import SwiftUI
import SwiftData

struct CharacterDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var libraries: [RulesLibrary]

    @Bindable var character: RPGCharacter

    @State private var showingAddSkill = false
    @State private var showingAddGoalRoll = false

    @State private var showingSkillPicker = false
    @State private var showingGoalRollPicker = false

    @State private var showingTemplateError = false
    @State private var templateErrorMessage = ""

    private var library: RulesLibrary? { libraries.first }

    // Required display order
    private let attributeCategoryOrder = ["Body", "Mind", "Spirit", "Occult"]

    var body: some View {
        List {
            Section("Character") {
                TextField("Name", text: $character.name)
                TextEditor(text: $character.characterDescription)
                    .frame(minHeight: 80)
            }

            Section("Attributes") {
                ForEach(attributeCategoryOrder, id: \.self) { cat in
                    let stats = attributes(in: cat)
                    if !stats.isEmpty {
                        Text(cat)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)

                        ForEach(stats) { stat in
                            NavigationLink { StatEditView(stat: stat) } label: {
                                HStack {
                                    Text(stat.name)
                                    Spacer()
                                    Text("\(stat.value)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section("Natural Skills") {
                ForEach(naturalSkillsSorted()) { stat in
                    NavigationLink { StatEditView(stat: stat) } label: {
                        HStack {
                            Text(stat.name)
                            Spacer()
                            Text("\(stat.value)").foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Learned Skills / Lores / Tongues") {
                ForEach(character.learnedSkills.sorted(by: {
                    $0.effectiveCategory < $1.effectiveCategory ||
                    ($0.effectiveCategory == $1.effectiveCategory &&
                     $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending)
                })) { skill in
                    HStack {
                        NavigationLink {
                            CharacterSkillEditView(skill: skill, library: library)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(skill.effectiveName)
                                Text(skill.effectiveCategory)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(skill.value)").foregroundStyle(.secondary)
                        }

                        Button(role: .destructive) { modelContext.delete(skill) } label: {
                            Image(systemName: "trash").foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Button {
                    showingSkillPicker = true
                } label: {
                    Label("Add Skill / Lore / Tongue", systemImage: "plus.circle.fill")
                }
            }

            Section("Goal Rolls") {
                ForEach(character.goalRolls.sorted { $0.effectiveName < $1.effectiveName }) { roll in
                    HStack {
                        NavigationLink {
                            GoalRollEditView(roll: roll, library: library)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(roll.effectiveName).font(.headline)
                                if let attr = roll.effectiveAttributeStat, let s = roll.skillName {
                                    Text("\(attr.name) + \(s)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Goal: \(roll.goalValue)")
                                    .font(.subheadline)
                            }
                        }

                        Button(role: .destructive) { modelContext.delete(roll) } label: {
                            Image(systemName: "trash").foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Button {
                    showingGoalRollPicker = true
                } label: {
                    Label("Add Goal Roll", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Character Sheet")

        // Existing “create new” screens
        .sheet(isPresented: $showingAddSkill) {
            AddCharacterSkillView(character: character, library: library, isPresented: $showingAddSkill)
        }
        .sheet(isPresented: $showingAddGoalRoll) {
            AddGoalRollView(character: character, library: library, isPresented: $showingAddGoalRoll)
        }

        // NEW searchable pickers
        .sheet(isPresented: $showingSkillPicker) {
            NavigationStack {
                if let library {
                    VStack(spacing: 0) {
                        // optional "New..." convenience
                        Button {
                            showingSkillPicker = false
                            showingAddSkill = true
                        } label: {
                            Label("New…", systemImage: "plus")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(.ultraThinMaterial)

                        SkillTemplatePickerSheet(
                            templates: library.skillTemplates,
                            onPick: { t in addLearnedSkillFromTemplate(t) }
                        )
                    }
                } else {
                    Text("Rules library not available yet.")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showingGoalRollPicker) {
            NavigationStack {
                if let library {
                    VStack(spacing: 0) {
                        Button {
                            showingGoalRollPicker = false
                            showingAddGoalRoll = true
                        } label: {
                            Label("New…", systemImage: "plus")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(.ultraThinMaterial)

                        GoalRollTemplatePickerSheet(
                            templates: library.goalRollTemplates,
                            onPick: { t in addGoalRollFromTemplate(t) }
                        )
                    }
                } else {
                    Text("Rules library not available yet.")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        }

        .alert("Template can’t be applied", isPresented: $showingTemplateError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(templateErrorMessage)
        }
    }

    // MARK: - Attributes helpers

    private func attributes(in category: String) -> [Stat] {
        character.stats
            .filter { KeywordUtil.normalize($0.statType) == "attribute" && $0.category == category }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private func naturalSkillsSorted() -> [Stat] {
        character.stats
            .filter { KeywordUtil.normalize($0.statType) == "skill" && $0.category == "Natural Skills" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    // MARK: - Add from template (Skills)

    private func addLearnedSkillFromTemplate(_ template: SkillTemplate) {
        if character.learnedSkills.contains(where: { $0.template?.id == template.id }) { return }
        let newSkill = CharacterSkill(template: template, value: 0)
        character.learnedSkills.append(newSkill)
    }

    // MARK: - Add from template (Goal Rolls)

    private func addGoalRollFromTemplate(_ template: GoalRollTemplate) {
        if character.goalRolls.contains(where: { $0.template?.id == template.id }) { return }

        guard let attr = character.stats.first(where: {
            KeywordUtil.normalize($0.statType) == "attribute" &&
            $0.category == template.defaultAttributeCategory &&
            $0.name.caseInsensitiveCompare(template.defaultAttributeName) == .orderedSame
        }) else {
            templateErrorMessage = "“\(template.name)” default attribute wasn’t found on this character: \(template.defaultAttributeCategory) → \(template.defaultAttributeName)."
            showingTemplateError = true
            return
        }

        switch template.defaultSkillMode {
        case .natural:
            guard let ns = character.stats.first(where: {
                KeywordUtil.normalize($0.statType) == "skill" &&
                $0.category == "Natural Skills" &&
                $0.name.caseInsensitiveCompare(template.defaultNaturalSkillName) == .orderedSame
            }) else {
                templateErrorMessage = "“\(template.name)” default natural skill wasn’t found on this character: \(template.defaultNaturalSkillName)."
                showingTemplateError = true
                return
            }

            let roll = CharacterGoalRoll(template: template, attributeStat: attr, naturalSkillStat: ns, characterSkill: nil)
            character.goalRolls.append(roll)

        case .learned:
            guard let learnedTemplate = template.defaultLearnedSkillTemplate else {
                templateErrorMessage = "“\(template.name)” is set to Learned/Lore/Tongue but has no default learned-skill template selected."
                showingTemplateError = true
                return
            }

            let learnedInstance: CharacterSkill
            if let existing = character.learnedSkills.first(where: { $0.template?.id == learnedTemplate.id }) {
                learnedInstance = existing
            } else {
                let created = CharacterSkill(template: learnedTemplate, value: 0)
                character.learnedSkills.append(created)
                learnedInstance = created
            }

            let roll = CharacterGoalRoll(template: template, attributeStat: attr, naturalSkillStat: nil, characterSkill: learnedInstance)
            character.goalRolls.append(roll)
        }
    }
}
