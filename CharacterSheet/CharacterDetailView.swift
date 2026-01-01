import SwiftUI
import SwiftData

struct CharacterDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var libraries: [RulesLibrary]

    @Bindable var character: RPGCharacter
    @State private var showingAddSkill = false
    @State private var showingAddGoalRoll = false

    @State private var showingTemplateError = false
    @State private var templateErrorMessage = ""

    private var library: RulesLibrary? { libraries.first }

    // Required display order
    private let attributeCategoryOrder = ["Body", "Mind", "Spirit", "Occult"]
    private let learnedSkillCategoryOrder = ["Learned Skills", "Lores", "Tongues"]

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
                ForEach(learnedSkillsSorted()) { skill in
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

                // ✅ Main-sheet dropdown (organized by category)
                Menu {
                    Button {
                        showingAddSkill = true
                    } label: {
                        Label("New…", systemImage: "plus")
                    }

                    Divider()

                    ForEach(learnedSkillCategoryOrder, id: \.self) { category in
                        let templates = skillTemplates(in: category)
                        if !templates.isEmpty {
                            Menu(category) {
                                ForEach(templates) { t in
                                    Button(t.name) {
                                        addLearnedSkillFromTemplate(t)
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Label("Add Learned Skill / Lore / Tongue", systemImage: "plus.circle.fill")
                }
            }

            Section("Goal Rolls") {
                ForEach(character.goalRolls.sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }) { roll in
                    HStack {
                        NavigationLink {
                            GoalRollEditView(roll: roll, library: library)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(roll.effectiveName).font(.headline)
                                if let attr = roll.attributeStat, let s = roll.skillName {
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

                // ✅ Main-sheet dropdown
                Menu {
                    Button {
                        showingAddGoalRoll = true
                    } label: {
                        Label("New…", systemImage: "plus")
                    }

                    Divider()

                    ForEach(goalRollTemplatesSorted()) { t in
                        Button(t.name) {
                            addGoalRollFromTemplate(t)
                        }
                    }
                } label: {
                    Label("Add Goal Roll", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Character Sheet")
        .sheet(isPresented: $showingAddSkill) {
            AddCharacterSkillView(character: character, library: library, isPresented: $showingAddSkill)
        }
        .sheet(isPresented: $showingAddGoalRoll) {
            AddGoalRollView(character: character, library: library, isPresented: $showingAddGoalRoll)
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
            .filter { $0.statType == "attribute" && $0.category == category }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private func naturalSkillsSorted() -> [Stat] {
        character.stats
            .filter { $0.statType == "skill" && $0.category == "Natural Skills" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    // MARK: - Learned skills sorting (category order, then name)

    private func learnedSkillsSorted() -> [CharacterSkill] {
        character.learnedSkills.sorted {
            let aCatIdx = learnedSkillCategoryOrder.firstIndex(of: $0.effectiveCategory) ?? 999
            let bCatIdx = learnedSkillCategoryOrder.firstIndex(of: $1.effectiveCategory) ?? 999
            if aCatIdx != bCatIdx { return aCatIdx < bCatIdx }
            return $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending
        }
    }

    // MARK: - Template lists

    private func skillTemplates(in category: String) -> [SkillTemplate] {
        guard let library else { return [] }
        return library.skillTemplates
            .filter { $0.category == category }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func goalRollTemplatesSorted() -> [GoalRollTemplate] {
        guard let library else { return [] }
        return library.goalRollTemplates
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Add from template (Skills)

    private func addLearnedSkillFromTemplate(_ template: SkillTemplate) {
        // Prevent duplicates of the same template on a character
        if character.learnedSkills.contains(where: { $0.template?.persistentModelID == template.persistentModelID }) {
            return
        }
        let newSkill = CharacterSkill(template: template, value: 0)
        character.learnedSkills.append(newSkill)
    }

    // MARK: - Add from template (Goal Rolls)

    private func addGoalRollFromTemplate(_ template: GoalRollTemplate) {
        // Prevent duplicates of the same template on a character
        if character.goalRolls.contains(where: { $0.template?.persistentModelID == template.persistentModelID }) {
            return
        }

        let wantedAttrName = template.defaultAttributeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let wantedAttrCat = template.defaultAttributeCategory.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let attr = character.stats.first(where: {
            $0.statType == "attribute" &&
            $0.category.caseInsensitiveCompare(wantedAttrCat) == .orderedSame &&
            $0.name.caseInsensitiveCompare(wantedAttrName) == .orderedSame
        }) else {
            templateErrorMessage = "“\(template.name)” default attribute wasn’t found on this character: \(template.defaultAttributeCategory) → \(template.defaultAttributeName)."
            showingTemplateError = true
            return
        }

        switch template.defaultSkillMode {
        case .natural:
            let wantedSkillName = template.defaultNaturalSkillName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let ns = character.stats.first(where: {
                $0.statType == "skill" &&
                $0.category.caseInsensitiveCompare("Natural Skills") == .orderedSame &&
                $0.name.caseInsensitiveCompare(wantedSkillName) == .orderedSame
            }) else {
                templateErrorMessage = "“\(template.name)” default natural skill wasn’t found on this character: \(template.defaultNaturalSkillName)."
                showingTemplateError = true
                return
            }

            let roll = CharacterGoalRoll(
                template: template,
                attributeStat: attr,
                naturalSkillStat: ns,
                characterSkill: nil
            )
            character.goalRolls.append(roll)

        case .learned:
            guard let learnedTemplate = template.defaultLearnedSkillTemplate else {
                templateErrorMessage = "“\(template.name)” is set to Learned/Lore/Tongue but has no default learned-skill template selected."
                showingTemplateError = true
                return
            }

            // Ensure the character has a CharacterSkill instance for that template
            let learnedInstance: CharacterSkill
            if let existing = character.learnedSkills.first(where: { $0.template?.persistentModelID == learnedTemplate.persistentModelID }) {
                learnedInstance = existing
            } else {
                let created = CharacterSkill(template: learnedTemplate, value: 0)
                character.learnedSkills.append(created)
                learnedInstance = created
            }

            let roll = CharacterGoalRoll(
                template: template,
                attributeStat: attr,
                naturalSkillStat: nil,
                characterSkill: learnedInstance
            )
            character.goalRolls.append(roll)
        }
    }
}
