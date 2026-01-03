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
    @State private var selectedLearnedSkillID: PersistentIdentifier?

    private let attributeCategoryOrder = ["Body", "Mind", "Spirit", "Occult"]

    private var templatesSorted: [GoalRollTemplate] {
        guard let library else { return [] }
        return library.goalRollTemplates.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var selectedTemplate: GoalRollTemplate? {
        guard let selectedTemplateID else { return nil }
        return templatesSorted.first(where: { $0.persistentModelID == selectedTemplateID })
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
        character.learnedSkills
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var selectedAttribute: Stat? {
        guard let selectedAttributeID else { return nil }
        return attributesOrdered.first(where: { $0.persistentModelID == selectedAttributeID })
    }

    private var selectedNaturalSkill: Stat? {
        guard let selectedNaturalSkillID else { return nil }
        return naturalSkillsOrdered.first(where: { $0.persistentModelID == selectedNaturalSkillID })
    }

    private var selectedLearnedSkill: CharacterSkill? {
        guard let selectedLearnedSkillID else { return nil }
        return learnedSkillsOrdered.first(where: { $0.persistentModelID == selectedLearnedSkillID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    Button {
                        showingTemplatePicker = true
                    } label: {
                        HStack {
                            Text(selectedTemplate?.name.isEmpty == false ? selectedTemplate!.name : "Select…")
                                .foregroundStyle(selectedTemplate == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let t = selectedTemplate, !t.templateDescription.isEmpty {
                        Text(t.templateDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Name Override (Optional)") {
                    TextField("Leave blank to use template name", text: $customName)
                        .autocorrectionDisabled()
                }

                Section("Formula (optional now; can be overridden later)") {
                    Picker("Attribute", selection: $selectedAttributeID) {
                        Text("Select…").tag(nil as PersistentIdentifier?)
                        ForEach(attributesOrdered) { a in
                            Text("\(a.category): \(a.name)").tag(a.persistentModelID as PersistentIdentifier?)
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
                        .onChange(of: selectedSkillMode) { _, newValue in
                            if newValue == .natural { selectedLearnedSkillID = nil }
                        }
                    } else {
                        Picker("Learned Skill", selection: $selectedLearnedSkillID) {
                            Text("Select…").tag(nil as PersistentIdentifier?)
                            ForEach(learnedSkillsOrdered) { s in
                                Text("\(s.effectiveName) (\(s.effectiveCategory))")
                                    .tag(s.persistentModelID as PersistentIdentifier?)
                            }
                        }
                        .onChange(of: selectedSkillMode) { _, newValue in
                            if newValue == .learned { selectedNaturalSkillID = nil }
                        }
                    }
                }

                Section("Preview") {
                    let attr = selectedAttribute?.value ?? 0
                    let skillVal: Int = {
                        if selectedSkillMode == .natural { return selectedNaturalSkill?.value ?? 0 }
                        return selectedLearnedSkill?.value ?? 0
                    }()

                    HStack {
                        Text("Goal (without modifiers)")
                        Spacer()
                        Text("\(attr + skillVal)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.secondary)
                }

                Section {
                    Button("Add Goal Roll") {
                        addRoll()
                    }
                    .disabled(selectedTemplate == nil)
                }
            }
            .navigationTitle("Add Goal Roll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                SearchableTemplatePickerSheet(
                    title: "Pick a Goal Roll Template",
                    prompt: "Search templates",
                    items: templatesSorted,
                    name: { $0.name },
                    subtitle: { $0.defaultAttributeName.isEmpty ? "" : "Default: \($0.defaultAttributeCategory) \($0.defaultAttributeName)" }
                ) { picked in
                    selectedTemplateID = picked.persistentModelID
                    // optional: you could also pre-fill formula from template defaults later,
                    // but leaving it user-driven is fine since this is an "Add" screen.
                }
            }
        }
    }

    private func addRoll() {
        guard let template = selectedTemplate else { return }

        let newRoll = CharacterGoalRoll(
            template: template,
            attributeStat: selectedAttribute,
            naturalSkillStat: selectedSkillMode == .natural ? selectedNaturalSkill : nil,
            characterSkill: selectedSkillMode == .learned ? selectedLearnedSkill : nil
        )

        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            newRoll.isBranched = true
            newRoll.branchedDate = Date()
            newRoll.overrideName = trimmed
            newRoll.overrideDescription = template.templateDescription
            newRoll.overrideBaseModifier = template.baseModifier
            newRoll.overrideUserKeywords = template.userKeywords
        }

        character.goalRolls.append(newRoll)
        isPresented = false
    }
}
