import SwiftUI
import SwiftData

struct AddGoalRollView: View {
    var character: RPGCharacter
    var library: RulesLibrary?
    @Binding var isPresented: Bool

    // Template selection
    @State private var selectedTemplateID: PersistentIdentifier?
    @State private var customName: String = ""
    @State private var showingTemplatePicker = false

    // Formula selection uses IDs (avoids SwiftData picker/hash issues)
    @State private var selectedAttributeID: PersistentIdentifier?
    @State private var selectedSkillMode: GoalRollTemplate.SkillMode = .natural
    @State private var selectedNaturalSkillID: PersistentIdentifier?
    @State private var selectedCharacterSkillID: PersistentIdentifier?

    // Required display order
    private let attributeCategoryOrder = ["Body", "Mind", "Spirit", "Occult"]

    private var templatesSorted: [GoalRollTemplate] {
        guard let library else { return [] }
        return library.goalRollTemplates.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var attributesOrdered: [Stat] {
        let attrs = character.stats.filter { $0.statType == "attribute" }
        return attrs.sorted {
            let aIdx = attributeCategoryOrder.firstIndex(of: $0.category) ?? 999
            let bIdx = attributeCategoryOrder.firstIndex(of: $1.category) ?? 999
            if aIdx != bIdx { return aIdx < bIdx }
            if $0.displayOrder != $1.displayOrder { return $0.displayOrder < $1.displayOrder }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var naturalSkillsOrdered: [Stat] {
        character.stats
            .filter { $0.statType == "skill" && $0.category == "Natural Skills" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private var learnedSkillsOrdered: [CharacterSkill] {
        character.learnedSkills.sorted {
            $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending
        }
    }

    private func templateByID(_ id: PersistentIdentifier?) -> GoalRollTemplate? {
        guard let id else { return nil }
        return templatesSorted.first { $0.persistentModelID == id }
    }

    private func statByID(_ id: PersistentIdentifier?) -> Stat? {
        guard let id else { return nil }
        return character.stats.first { $0.persistentModelID == id }
    }

    private func characterSkillByID(_ id: PersistentIdentifier?) -> CharacterSkill? {
        guard let id else { return nil }
        return character.learnedSkills.first { $0.persistentModelID == id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    HStack {
                        Text("From Library")
                        Spacer()
                        Button {
                            showingTemplatePicker = true
                        } label: {
                            if let t = templateByID(selectedTemplateID) {
                                Text(t.name).foregroundStyle(.tint)
                            } else {
                                Text("Choose…").foregroundStyle(.tint)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if let t = templateByID(selectedTemplateID), !t.templateDescription.isEmpty {
                        Text(t.templateDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    TextField("Or create new template name", text: $customName)
                        .autocorrectionDisabled()
                }

                Section("Formula (defaults can come from template)") {
                    Picker("Attribute", selection: $selectedAttributeID) {
                        Text("Select…").tag(nil as PersistentIdentifier?)
                        ForEach(attributesOrdered) { a in
                            Text("\(a.category): \(a.name)")
                                .tag(a.persistentModelID as PersistentIdentifier?)
                        }
                    }

                    Picker("Skill Type", selection: $selectedSkillMode) {
                        ForEach(GoalRollTemplate.SkillMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedSkillMode == .natural {
                        Picker("Natural Skill", selection: $selectedNaturalSkillID) {
                            Text("Select…").tag(nil as PersistentIdentifier?)
                            ForEach(naturalSkillsOrdered) { s in
                                Text(s.name).tag(s.persistentModelID as PersistentIdentifier?)
                            }
                        }
                    } else {
                        Picker("Learned/Lore/Tongue", selection: $selectedCharacterSkillID) {
                            Text("Select…").tag(nil as PersistentIdentifier?)
                            ForEach(learnedSkillsOrdered) { s in
                                Text("\(s.effectiveName) (\(s.effectiveCategory))")
                                    .tag(s.persistentModelID as PersistentIdentifier?)
                            }
                        }

                        if let t = templateByID(selectedTemplateID),
                           t.defaultSkillMode == .learned,
                           t.defaultLearnedSkillTemplate != nil,
                           selectedCharacterSkillID == nil {
                            Text("Tip: If the template’s default learned skill isn’t on this character yet, it will be added at value 0 when you tap Add.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Goal Roll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                        .disabled(!canAdd)
                }
            }
            .onChange(of: selectedSkillMode) { _, _ in
                selectedNaturalSkillID = nil
                selectedCharacterSkillID = nil
            }
            .sheet(isPresented: $showingTemplatePicker) {
                SearchableTemplatePickerSheet(
                    title: "Goal Roll Templates",
                    prompt: "Search templates…",
                    items: templatesSorted,
                    name: { $0.name },
                    subtitle: { $0.templateDescription }
                ) { picked in
                    selectedTemplateID = picked.persistentModelID
                    applyTemplateDefaults(picked)
                }
            }
        }
    }

    private var canAdd: Bool {
        let hasTemplate = templateByID(selectedTemplateID) != nil ||
        !customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let hasAttr = selectedAttributeID != nil

        let hasSkill: Bool =
        (selectedSkillMode == .natural && selectedNaturalSkillID != nil) ||
        (selectedSkillMode == .learned && (selectedCharacterSkillID != nil || templateProvidesLearnedSkill()))

        return hasTemplate && hasAttr && hasSkill
    }

    private func templateProvidesLearnedSkill() -> Bool {
        guard let t = templateByID(selectedTemplateID) else { return false }
        return t.defaultSkillMode == .learned && t.defaultLearnedSkillTemplate != nil
    }

    private func applyTemplateDefaults(_ template: GoalRollTemplate) {
        // Attribute
        if let attr = character.stats.first(where: {
            $0.statType == "attribute" &&
            $0.category == template.defaultAttributeCategory &&
            $0.name.caseInsensitiveCompare(template.defaultAttributeName) == .orderedSame
        }) {
            selectedAttributeID = attr.persistentModelID
        }

        selectedSkillMode = template.defaultSkillMode

        if template.defaultSkillMode == .natural {
            if let ns = character.stats.first(where: {
                $0.statType == "skill" &&
                $0.category == "Natural Skills" &&
                $0.name.caseInsensitiveCompare(template.defaultNaturalSkillName) == .orderedSame
            }) {
                selectedNaturalSkillID = ns.persistentModelID
            }
        } else {
            if let st = template.defaultLearnedSkillTemplate,
               let existing = character.learnedSkills.first(where: { $0.template?.persistentModelID == st.persistentModelID }) {
                selectedCharacterSkillID = existing.persistentModelID
            } else {
                selectedCharacterSkillID = nil
            }
        }
    }

    private func add() {
        guard let library else { return }
        guard let attr = statByID(selectedAttributeID) else { return }

        // Resolve template (existing or create)
        let template: GoalRollTemplate
        if let selected = templateByID(selectedTemplateID) {
            template = selected
        } else {
            let name = customName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }

            if let existing = library.goalRollTemplates.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                template = existing
            } else {
                let t = GoalRollTemplate(name: name)
                library.goalRollTemplates.append(t)
                template = t
            }
        }

        // Resolve skill + build roll
        let roll: CharacterGoalRoll

        if selectedSkillMode == .natural {
            guard let ns = statByID(selectedNaturalSkillID) else { return }
            roll = CharacterGoalRoll(template: template, attributeStat: attr, naturalSkillStat: ns, characterSkill: nil)
        } else {
            if let cs = characterSkillByID(selectedCharacterSkillID) {
                roll = CharacterGoalRoll(template: template, attributeStat: attr, naturalSkillStat: nil, characterSkill: cs)
            } else {
                guard let st = template.defaultLearnedSkillTemplate else { return }

                if let existing = character.learnedSkills.first(where: { $0.template?.persistentModelID == st.persistentModelID }) {
                    roll = CharacterGoalRoll(template: template, attributeStat: attr, naturalSkillStat: nil, characterSkill: existing)
                } else {
                    let newSkill = CharacterSkill(template: st, value: 0)
                    character.learnedSkills.append(newSkill)
                    roll = CharacterGoalRoll(template: template, attributeStat: attr, naturalSkillStat: nil, characterSkill: newSkill)
                }
            }
        }

        character.goalRolls.append(roll)
        isPresented = false
    }
}
