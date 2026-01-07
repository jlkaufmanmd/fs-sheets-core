import SwiftUI
import SwiftData

struct AddGoalRollView: View {
    enum Mode {
        case new
        case fromTemplate(PersistentIdentifier)
    }

    var character: RPGCharacter
    var library: RulesLibrary
    @Binding var isPresented: Bool
    let mode: Mode
    var category: GoalRollCategory?

    // Shared fields
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var keywords: String = ""
    @State private var baseModifier: Int = 0

    // Formula selection for NEW template defaults
    @State private var selectedAttributeID: PersistentIdentifier?
    @State private var selectedNaturalSkillID: PersistentIdentifier?
    @State private var selectedLearnedSkillID: PersistentIdentifier?

    private var template: GoalRollTemplate? {
        guard case .fromTemplate(let id) = mode else { return nil }
        return library.goalRollTemplates.first(where: { $0.persistentModelID == id })
    }

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
    
    private var learnedSkillsByCategory: [(String, [CharacterSkill])] {
        let categories = ["Learned Skills", "Lores", "Tongues"]
        return categories.compactMap { cat in
            let skills = character.learnedSkills
                .filter { $0.effectiveCategory == cat }
                .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
            return skills.isEmpty ? nil : (cat, skills)
        }
    }
    
    private var selectedAttribute: Stat? {
        attributes.first(where: { $0.persistentModelID == selectedAttributeID })
    }
    
    private var selectedSkill: (name: String, isNatural: Bool)? {
        if let natID = selectedNaturalSkillID,
           let skill = naturalSkills.first(where: { $0.persistentModelID == natID }) {
            return (skill.name, true)
        }
        if let learnedID = selectedLearnedSkillID,
           let skill = character.learnedSkills.first(where: { $0.persistentModelID == learnedID }) {
            return (skill.effectiveName, false)
        }
        return nil
    }

    private var canAdd: Bool {
        switch mode {
        case .new:
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return false }
            guard selectedAttributeID != nil else { return false }
            return selectedNaturalSkillID != nil || selectedLearnedSkillID != nil
        case .fromTemplate:
            return template != nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                switch mode {
                case .new:
                    Section("New Goal Roll") {
                        TextField("Name", text: $name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()

                        TextField("Keywords (comma-separated)", text: $keywords)
                            .autocorrectionDisabled()

                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Description (optional)...")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $description)
                                .frame(minHeight: 110)
                        }
                    }

                    Section("Base Modifier") {
                        Stepper(value: $baseModifier, in: -50...50) {
                            Text("\(baseModifier)")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }

                    Section("Formula") {
                        // Attribute Picker - no category prefix
                        Picker("Attribute", selection: $selectedAttributeID) {
                            Text("Select...").tag(nil as PersistentIdentifier?)
                            ForEach(attributes) { a in
                                Text(a.name).tag(a.persistentModelID as PersistentIdentifier?)
                            }
                        }

                        // Skill selection with NavigationLink
                        NavigationLink {
                            GoalRollSkillSelectionView(
                                character: character,
                                selectedNaturalSkillID: $selectedNaturalSkillID,
                                selectedLearnedSkillID: $selectedLearnedSkillID
                            )
                        } label: {
                            HStack {
                                Text("Skill")
                                Spacer()
                                Text(selectedSkill?.name ?? "Select...")
                                    .foregroundStyle(selectedSkill == nil ? .secondary : .primary)
                            }
                        }
                    }

                case .fromTemplate:
                    Section("Adding Goal Roll") {
                        if let template {
                            Text(template.name).font(.headline)
                            if !template.templateDescription.isEmpty {
                                Text(template.templateDescription)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Missing template.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresented = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                        .disabled(!canAdd)
                }
            }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .new: return "New Goal Roll"
        case .fromTemplate: return "Add Goal Roll"
        }
    }

    private func add() {
        switch mode {
        case .new:
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            guard let selectedAttr = selectedAttribute else { return }

            // Determine skill mode and get appropriate skill reference
            var skillMode: GoalRollTemplate.SkillMode = .natural
            var natSkillName = ""
            var learnedTemplate: SkillTemplate? = nil
            
            if let natID = selectedNaturalSkillID,
               let natSkill = naturalSkills.first(where: { $0.persistentModelID == natID }) {
                skillMode = .natural
                natSkillName = natSkill.name
            } else if let learnedID = selectedLearnedSkillID,
                      let learnedSkill = character.learnedSkills.first(where: { $0.persistentModelID == learnedID }) {
                skillMode = .learned
                learnedTemplate = learnedSkill.template
            } else {
                return
            }

            // Check if template with this name already exists
            let existingTemplate = library.goalRollTemplates.first { $0.name == trimmed }

            let template: GoalRollTemplate
            if let existing = existingTemplate {
                // Reuse existing template
                template = existing
            } else {
                // Create new template
                template = GoalRollTemplate(
                    name: trimmed,
                    templateDescription: description,
                    baseModifier: baseModifier,
                    userKeywords: keywords,
                    defaultAttributeName: selectedAttr.name,
                    defaultAttributeCategory: selectedAttr.category,
                    defaultSkillMode: skillMode,
                    defaultNaturalSkillName: natSkillName,
                    defaultLearnedSkillTemplate: learnedTemplate
                )
                library.goalRollTemplates.append(template)
            }

            // Create goal roll and branch it with user's selections
            let roll = CharacterGoalRoll(template: template)
            roll.category = category

            // Branch the roll to override with user's specific selections
            roll.isBranched = true
            roll.branchedDate = Date()
            roll.overrideName = trimmed
            roll.overrideDescription = description
            roll.overrideBaseModifier = baseModifier
            roll.overrideUserKeywords = keywords
            roll.attributeStat = selectedAttr

            if skillMode == .natural, let natID = selectedNaturalSkillID,
               let natSkill = naturalSkills.first(where: { $0.persistentModelID == natID }) {
                roll.naturalSkillStat = natSkill
                roll.characterSkill = nil
            } else if skillMode == .learned, let learnedID = selectedLearnedSkillID,
                      let learnedSkill = character.learnedSkills.first(where: { $0.persistentModelID == learnedID }) {
                roll.characterSkill = learnedSkill
                roll.naturalSkillStat = nil
            }

            character.goalRolls.append(roll)
            isPresented = false

        case .fromTemplate:
            guard let template else { return }

            // Auto-add missing learned skill if needed
            if template.defaultSkillMode == .learned,
               let skillTemplate = template.defaultLearnedSkillTemplate {
                let hasSkill = character.learnedSkills.contains {
                    $0.template?.persistentModelID == skillTemplate.persistentModelID
                }
                if !hasSkill {
                    let newSkill = CharacterSkill(template: skillTemplate, value: 0)
                    character.learnedSkills.append(newSkill)
                }
            }

            let roll = CharacterGoalRoll(template: template)
            roll.category = category
            character.goalRolls.append(roll)
            isPresented = false
        }
    }
}

// MARK: - Skill Selection View for Goal Rolls

struct GoalRollSkillSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    var character: RPGCharacter
    @Binding var selectedNaturalSkillID: PersistentIdentifier?
    @Binding var selectedLearnedSkillID: PersistentIdentifier?

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

    private var loreSkills: [CharacterSkill] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Lores" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var tongues: [CharacterSkill] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Tongues" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    var body: some View {
        Form {
            if !naturalSkills.isEmpty {
                Section("Natural Skills") {
                    ForEach(naturalSkills) { skill in
                        Button {
                            selectedNaturalSkillID = skill.persistentModelID
                            selectedLearnedSkillID = nil
                            dismiss()
                        } label: {
                            HStack {
                                Text(skill.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedNaturalSkillID == skill.persistentModelID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }

            if !learnedSkills.isEmpty {
                Section("Learned Skills") {
                    ForEach(learnedSkills) { skill in
                        Button {
                            selectedLearnedSkillID = skill.persistentModelID
                            selectedNaturalSkillID = nil
                            dismiss()
                        } label: {
                            HStack {
                                Text(skill.effectiveName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedLearnedSkillID == skill.persistentModelID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }

            if !loreSkills.isEmpty {
                Section("Lore Skills") {
                    ForEach(loreSkills) { skill in
                        Button {
                            selectedLearnedSkillID = skill.persistentModelID
                            selectedNaturalSkillID = nil
                            dismiss()
                        } label: {
                            HStack {
                                Text(skill.effectiveName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedLearnedSkillID == skill.persistentModelID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }

            if !tongues.isEmpty {
                Section("Tongues") {
                    ForEach(tongues) { skill in
                        Button {
                            selectedLearnedSkillID = skill.persistentModelID
                            selectedNaturalSkillID = nil
                            dismiss()
                        } label: {
                            HStack {
                                Text(skill.effectiveName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedLearnedSkillID == skill.persistentModelID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Skill")
        .navigationBarTitleDisplayMode(.inline)
    }
}
