import SwiftUI
import SwiftData

struct CharacterDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var character: RPGCharacter

    @Query(sort: \RulesLibrary.createdDate) private var libraries: [RulesLibrary]
    @Query(sort: \RPGCharacter.name) private var allCharacters: [RPGCharacter]
    private var library: RulesLibrary? { libraries.first }

    // Sheets / pickers
    @State private var showingAddSkillNew = false
    @State private var showingAddRollNew = false

    @State private var showingSkillTemplatePicker = false
    @State private var showingRollTemplatePicker = false

    @State private var showingAddSkillFromTemplate = false
    @State private var showingAddRollFromTemplate = false

    @State private var selectedSkillTemplateID: PersistentIdentifier?
    @State private var selectedRollTemplateID: PersistentIdentifier?

    // Inline value editing focus (tap number to type)
    @FocusState private var focusedStatID: PersistentIdentifier?
    @FocusState private var focusedSkillID: PersistentIdentifier?
    @FocusState private var isNameFieldFocused: Bool
    
    // Name validation
    @State private var showingDuplicateNameAlert = false
    @State private var previousValidName: String = ""

    private var attributes: [Stat] {
        character.stats
            .filter { $0.statType == "attribute" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private var naturalSkills: [Stat] {
        character.stats
            .filter { $0.statType == "skill" && $0.category == "Natural Skills" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private var learnedSkills: [CharacterSkill] {
        character.learnedSkills.sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var goalRolls: [CharacterGoalRoll] {
        character.goalRolls.sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    // Filter templates to exclude ones character already has
    private var availableSkillTemplates: [SkillTemplate] {
        guard let library else { return [] }
        let existingTemplateIDs = Set(character.learnedSkills.compactMap { $0.template?.persistentModelID })
        return library.skillTemplates.filter { !existingTemplateIDs.contains($0.persistentModelID) }
    }

    private var availableGoalRollTemplates: [GoalRollTemplate] {
        guard let library else { return [] }
        let existingTemplateIDs = Set(character.goalRolls.compactMap { $0.template?.persistentModelID })
        return library.goalRollTemplates.filter { !existingTemplateIDs.contains($0.persistentModelID) }
    }

    var body: some View {
        Form {
            Section("Character") {
                TextField("Name", text: $character.name)
                    .font(.headline)
                    .focused($isNameFieldFocused)
                    .onSubmit {
                        validateName()
                    }
                    .onChange(of: isNameFieldFocused) { _, isFocused in
                        if !isFocused {
                            validateName()
                        }
                    }
                
                ZStack(alignment: .topLeading) {
                    if character.characterDescription.isEmpty {
                        Text("Description (optional)...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $character.characterDescription)
                        .frame(minHeight: 80)
                }
            }

            Section("Attributes") {
                ForEach(attributes) { stat in
                    valueRowForStat(stat)
                }
            }

            Section("Natural Skills") {
                ForEach(naturalSkills) { stat in
                    valueRowForStat(stat)
                }
            }

            Section {
                HStack {
                    Text("Learned Skills / Lores / Tongues")
                        .font(.headline)
                    Spacer()

                    // Show button if no available templates, menu if templates exist
                    if !availableSkillTemplates.isEmpty {
                        Menu {
                            Button("New…") { showingAddSkillNew = true }
                            Button("From Template…") { showingSkillTemplatePicker = true }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    } else {
                        Button {
                            showingAddSkillNew = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }

            Section {
                if learnedSkills.isEmpty {
                    Text("No learned skills yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(learnedSkills) { skill in
                        valueRowForLearnedSkill(skill)
                    }
                    .onDelete { idx in
                        for i in idx { character.learnedSkills.remove(at: i) }
                    }
                }
            }

            Section {
                HStack {
                    Text("Goal Rolls")
                        .font(.headline)
                    Spacer()

                    // Show button if no available templates, menu if templates exist
                    if !availableGoalRollTemplates.isEmpty {
                        Menu {
                            Button("New…") { showingAddRollNew = true }
                            Button("From Template…") { showingRollTemplatePicker = true }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    } else {
                        Button {
                            showingAddRollNew = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }

            Section {
                if goalRolls.isEmpty {
                    Text("No goal rolls yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(goalRolls) { roll in
                        NavigationLink {
                            GoalRollEditView(roll: roll, library: library)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(roll.effectiveName)
                                Text("Goal: \(roll.goalValue)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { idx in
                        for i in idx { character.goalRolls.remove(at: i) }
                    }
                }
            }
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Duplicate Name", isPresented: $showingDuplicateNameAlert) {
            Button("OK") {
                character.name = previousValidName
            }
        } message: {
            Text("A character named \"\(character.name)\" already exists. Please choose a different name.")
        }
        .onAppear {
            ensureLibraryExists()
            previousValidName = character.name
        }
        // MARK: - New sheets
        .sheet(isPresented: $showingAddSkillNew) {
            if let lib = library {
                AddCharacterSkillView(character: character, library: lib, isPresented: $showingAddSkillNew, mode: .new)
            }
        }
        .sheet(isPresented: $showingAddRollNew) {
            if let lib = library {
                AddGoalRollView(character: character, library: lib, isPresented: $showingAddRollNew, mode: .new)
            }
        }
        // MARK: - Template pickers
        .sheet(isPresented: $showingSkillTemplatePicker) {
            SearchableTemplatePickerSheet(
                title: "Skill Templates",
                prompt: "Type to filter. Pick a template to add it to this character.",
                templates: availableSkillTemplates,
                sectionTitle: { $0.category },
                rowTitle: { $0.name },
                rowSubtitle: { t in
                    let d = t.templateDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    return d.isEmpty ? nil : d
                },
                rowSearchText: { $0.userKeywords }
            ) { picked in
                selectedSkillTemplateID = picked.persistentModelID
                showingAddSkillFromTemplate = true
            }
        }
        .sheet(isPresented: $showingRollTemplatePicker) {
            SearchableTemplatePickerSheet(
                title: "Goal Roll Templates",
                prompt: "Type to filter. Pick a template to add it to this character.",
                templates: availableGoalRollTemplates,
                sectionTitle: { _ in "Goal Rolls" },
                rowTitle: { $0.name },
                rowSubtitle: { t in
                    let d = t.templateDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    return d.isEmpty ? nil : d
                },
                rowSearchText: { $0.userKeywords }
            ) { picked in
                selectedRollTemplateID = picked.persistentModelID
                showingAddRollFromTemplate = true
            }
        }
        // MARK: - Add-from-template sheets (with optional customization)
        .sheet(isPresented: $showingAddSkillFromTemplate) {
            if let lib = library, let id = selectedSkillTemplateID {
                AddCharacterSkillView(character: character, library: lib, isPresented: $showingAddSkillFromTemplate, mode: .fromTemplate(id))
            }
        }
        .sheet(isPresented: $showingAddRollFromTemplate) {
            if let lib = library, let id = selectedRollTemplateID {
                AddGoalRollView(character: character, library: lib, isPresented: $showingAddRollFromTemplate, mode: .fromTemplate(id))
            }
        }
    }

    // MARK: - Row builders

    private func valueRowForStat(_ stat: Stat) -> some View {
        HStack {
            Text(stat.name)

            Spacer()

            Button {
                stat.value -= 1
                if stat.value < stat.minimumValue { stat.value = stat.minimumValue }
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.plain)

            Text("\(stat.value)")
                .frame(width: 44)
                .font(.headline)

            Button {
                stat.value += 1
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
        }
    }

    private func valueRowForLearnedSkill(_ skill: CharacterSkill) -> some View {
        HStack {
            NavigationLink {
                CharacterSkillEditView(skill: skill, library: library)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.effectiveName)
                    Text(skill.effectiveCategory)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                skill.value -= 1
                if skill.value < skill.minimumValue { skill.value = skill.minimumValue }
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.plain)

            ZStack {
                if focusedSkillID == skill.persistentModelID {
                    TextField("", value: Binding(
                        get: { skill.value },
                        set: { newVal in skill.value = max(newVal, skill.minimumValue) }
                    ), format: .number)
                        .frame(width: 44)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .focused($focusedSkillID, equals: skill.persistentModelID)
                } else {
                    Text("\(skill.value)")
                        .frame(width: 44)
                        .font(.headline)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedSkillID = skill.persistentModelID
                        }
                }
            }

            Button {
                skill.value += 1
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Validation
    
    private func validateName() {
        let trimmed = character.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If empty, revert to previous
        if trimmed.isEmpty {
            character.name = previousValidName
            return
        }
        
        // Check for duplicates
        let isDuplicate = allCharacters.contains { otherChar in
            otherChar.persistentModelID != character.persistentModelID &&
            otherChar.name.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(trimmed) == .orderedSame
        }
        
        if isDuplicate {
            showingDuplicateNameAlert = true
        } else {
            previousValidName = character.name
        }
    }

    // MARK: - Library bootstrap

    private func ensureLibraryExists() {
        if library == nil {
            let lib = RulesLibrary()
            modelContext.insert(lib)
        }
    }
}
