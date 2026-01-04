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

                        // Skill Picker with hierarchical menu
                        HStack {
                            Text("Skill")
                            Spacer()
                            Menu {
                                // Natural Skills submenu
                                Menu("Natural Skills") {
                                    ForEach(naturalSkills) { skill in
                                        Button(skill.name) {
                                            selectedNaturalSkillID = skill.persistentModelID
                                            selectedLearnedSkillID = nil
                                        }
                                    }
                                }
                                
                                // Learned Skills, Lores, Tongues submenus
                                ForEach(learnedSkillsByCategory, id: \.0) { (category, skills) in
                                    Menu(category) {
                                        ForEach(skills) { skill in
                                            Button(skill.effectiveName) {
                                                selectedLearnedSkillID = skill.persistentModelID
                                                selectedNaturalSkillID = nil
                                            }
                                        }
                                    }
                                }
                            } label: {
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

                    Section {
                        Text("The goal roll will be added using the template's default formula and settings. You can customize it in the goal roll detail screen.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
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

            let template = GoalRollTemplate(
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
            
            let roll = CharacterGoalRoll(
                template: template,
                attributeStat: nil,
                naturalSkillStat: nil,
                characterSkill: nil
            )
            character.goalRolls.append(roll)
            isPresented = false

        case .fromTemplate:
            guard let template else { return }

            let roll = CharacterGoalRoll(template: template)
            character.goalRolls.append(roll)
            isPresented = false
        }
    }
}
