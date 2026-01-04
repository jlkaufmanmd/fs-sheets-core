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

    private var attributesByCategory: [(String, [Stat])] {
        let categories = ["Body", "Mind", "Spirit", "Occult"]
        return categories.compactMap { category in
            let stats = attributes.filter { $0.category == category }
            return stats.isEmpty ? nil : (category, stats)
        }
    }

    private var naturalSkills: [Stat] {
        character.stats
            .filter { $0.statType == "skill" && $0.category == "Natural Skills" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private var learnedSkills: [CharacterSkill] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Learned Skills" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var lores: [CharacterSkill] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Lores" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var tongues: [CharacterSkill] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Tongues" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
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
                ForEach(attributesByCategory, id: \.0) { (category, stats) in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        ForEach(stats) { stat in
                            statDisclosureRow(stat)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Natural Skills") {
                ForEach(naturalSkills) { stat in
                    statDisclosureRow(stat)
                }
            }

            Section {
                HStack {
                    Text("Learned Skills")
                        .font(.headline)
                    Spacer()

                    // Minimal add button
                    if !availableSkillTemplates.filter({ $0.category == "Learned Skills" }).isEmpty {
                        Menu {
                            Button("New…") {
                                showingAddSkillNew = true
                            }
                            Button("From Template…") {
                                showingSkillTemplatePicker = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Button {
                            showingAddSkillNew = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                if learnedSkills.isEmpty {
                    Text("No learned skills yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(learnedSkills) { skill in
                        skillDisclosureRow(skill)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(skill)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            modelContext.delete(learnedSkills[index])
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("Lores")
                        .font(.headline)
                    Spacer()

                    // Minimal add button
                    if !availableSkillTemplates.filter({ $0.category == "Lores" }).isEmpty {
                        Menu {
                            Button("New…") {
                                showingAddSkillNew = true
                            }
                            Button("From Template…") {
                                showingSkillTemplatePicker = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Button {
                            showingAddSkillNew = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                if lores.isEmpty {
                    Text("No lores yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(lores) { skill in
                        skillDisclosureRow(skill)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(skill)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            modelContext.delete(lores[index])
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("Tongues")
                        .font(.headline)
                    Spacer()

                    // Minimal add button
                    if !availableSkillTemplates.filter({ $0.category == "Tongues" }).isEmpty {
                        Menu {
                            Button("New…") {
                                showingAddSkillNew = true
                            }
                            Button("From Template…") {
                                showingSkillTemplatePicker = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Button {
                            showingAddSkillNew = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                if tongues.isEmpty {
                    Text("No tongues yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(tongues) { skill in
                        skillDisclosureRow(skill)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(skill)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            modelContext.delete(tongues[index])
                        }
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
                // Add skill directly with value 1
                let newSkill = CharacterSkill(template: picked, value: 1)
                character.learnedSkills.append(newSkill)
                showingSkillTemplatePicker = false
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
                // Auto-add missing learned skill if needed
                if picked.defaultSkillMode == .learned,
                   let skillTemplate = picked.defaultLearnedSkillTemplate {
                    let hasSkill = character.learnedSkills.contains {
                        $0.template?.persistentModelID == skillTemplate.persistentModelID
                    }
                    if !hasSkill {
                        let newSkill = CharacterSkill(template: skillTemplate, value: 0)
                        character.learnedSkills.append(newSkill)
                    }
                }

                // Add goal roll
                let newRoll = CharacterGoalRoll(template: picked)
                character.goalRolls.append(newRoll)
                showingRollTemplatePicker = false
            }
        }
    }

    // MARK: - Row builders

    @ViewBuilder
    private func statDisclosureRow(_ stat: Stat) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Base Value")
                    Spacer()
                    Text("\(stat.value)")
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Effective Value")
                    Spacer()
                    Text("\(stat.value)")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Keywords")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(stat.implicitKeywords.joined(separator: ", "))
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
        } label: {
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
    }

    @ViewBuilder
    private func skillDisclosureRow(_ skill: CharacterSkill) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Base Value")
                    Spacer()
                    Text("\(skill.value)")
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Effective Value")
                    Spacer()
                    Text("\(skill.value)")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Keywords")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(skill.keywordsForRules.joined(separator: ", "))
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                Text(skill.effectiveName)

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
