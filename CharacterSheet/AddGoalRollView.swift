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
    
    // Formula selection uses IDs (avoids SwiftData picker/hash weirdness)
    @State private var selectedAttributeID: PersistentIdentifier?
    @State private var selectedSkillMode: GoalRollTemplate.SkillMode = .natural
    @State private var selectedNaturalSkillID: PersistentIdentifier?
    @State private var selectedCharacterSkillID: PersistentIdentifier?
    
    // Required display order
    private let attributeCategoryOrder = ["Body", "Mind", "Spirit", "Occult"]
    
    private var templatesSorted: [GoalRollTemplate] {
        guard let library else { return [] }
        return library.goalRollTemplates
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    private func templateByID(_ id: PersistentIdentifier?) -> GoalRollTemplate? {
        guard let id else { return nil }
        return templatesSorted.first { $0.persistentModelID == id }
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
    
    private var learnedSkillsGrouped: [(String, [CharacterSkill])] {
        let categories = ["Learned Skills", "Lores", "Tongues"]
        return categories.compactMap { cat in
            let subset = character.learnedSkills
                .filter { $0.effectiveCategory == cat }
                .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
            return subset.isEmpty ? nil : (cat, subset)
        }
    }
    
    private func statByID(_ id: PersistentIdentifier?) -> Stat? {
        guard let id else { return nil }
        return character.stats.first { $0.persistentModelID == id }
    }
    
    private func characterSkillByID(_ id: PersistentIdentifier?) -> CharacterSkill? {
        guard let id else { return nil }
        return character.learnedSkills.first { $0.persistentModelID == id }
    }
    
    private var canAdd: Bool {
        let hasTemplateOrName =
        templateByID(selectedTemplateID) != nil ||
        !customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        let hasAttr = selectedAttributeID != nil
        
        let hasSkill =
        (selectedSkillMode == .natural && selectedNaturalSkillID != nil) ||
        (selectedSkillMode == .learned && (selectedCharacterSkillID != nil || templateProvidesLearnedSkill()))
        
        return hasTemplateOrName && hasAttr && hasSkill
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("From Library") {
                    Button {
                        showingTemplatePicker = true
                    } label: {
                        HStack {
                            Text("Template")
                            Spacer()
                            if let t = templateByID(selectedTemplateID) {
                                Text(t.name).foregroundStyle(.secondary)
                            } else {
                                Text("Choose…").foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .disabled(library == nil || templatesSorted.isEmpty)
                    
                    if library == nil {
                        Text("Rules library not available yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if templatesSorted.isEmpty {
                        Text("No goal roll templates yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Pick a template to auto-fill defaults, then adjust if you want.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Or Create New Template") {
                    TextField("New goal roll name", text: $customName)
                        .autocorrectionDisabled()
                }
                
                Section("Formula") {
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
                    .onChange(of: selectedSkillMode) { _, _ in
                        selectedNaturalSkillID = nil
                        selectedCharacterSkillID = nil
                    }
                    
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
                            ForEach(learnedSkillsGrouped, id: \.0) { (cat, items) in
                                Section(cat) {
                                    ForEach(items) { s in
                                        Text(s.effectiveName)
                                            .tag(s.persistentModelID as PersistentIdentifier?)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Text("Tip: If a template points at a learned skill your character doesn’t have yet, it will be created at value 0 when you add the roll.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Goal Roll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Goal Roll") { add() }
                        .disabled(!canAdd)
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                SearchableTemplatePickerSheet(
                    title: "Choose Template",
                    prompt: "Search templates",
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
    
    // MARK: - Template defaults
    
    private func applyTemplateDefaults(_ template: GoalRollTemplate) {
        // Attribute default
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
            } else {
                selectedNaturalSkillID = nil
            }
            selectedCharacterSkillID = nil
        } else {
            selectedNaturalSkillID = nil
            
            if let st = template.defaultLearnedSkillTemplate,
               let existing = character.learnedSkills.first(where: { $0.template?.persistentModelID == st.persistentModelID }) {
                selectedCharacterSkillID = existing.persistentModelID
            } else {
                selectedCharacterSkillID = nil
            }
        }
    }
    
    private func templateProvidesLearnedSkill() -> Bool {
        guard let t = templateByID(selectedTemplateID) else { return false }
        return t.defaultSkillMode == .learned && t.defaultLearnedSkillTemplate != nil
    }
    
    // MARK: - Add
    
    private func add() {
        guard let library else { return }
        guard let attr = statByID(selectedAttributeID) else { return }
        
        // Resolve template (picked or create/reuse by name)
        let template: GoalRollTemplate
        if let picked = templateByID(selectedTemplateID) {
            template = picked
        } else {
            let name = customName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            
            if let existing = library.goalRollTemplates.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                template = existing
            } else {
                let created = GoalRollTemplate(name: name)
                library.goalRollTemplates.append(created)
                template = created
            }
        }
        
        // Prevent duplicates of the same template on a character
        if character.goalRolls.contains(where: { $0.template?.persistentModelID == template.persistentModelID }) {
            isPresented = false
            return
        }
        
        let roll: CharacterGoalRoll
        
        if selectedSkillMode == .natural {
            guard let ns = statByID(selectedNaturalSkillID) else { return }
            roll = CharacterGoalRoll(template: template, attributeStat: attr, naturalSkillStat: ns, characterSkill: nil)
        } else {
            // Prefer explicit pick
            if let cs = characterSkillByID(selectedCharacterSkillID) {
                roll = CharacterGoalRoll(template: template, attributeStat: attr, naturalSkillStat: nil, characterSkill: cs)
            } else {
                // Fall back to template default learned skill (auto-create if missing)
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

