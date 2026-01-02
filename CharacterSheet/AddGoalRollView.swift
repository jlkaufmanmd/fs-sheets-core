import SwiftUI
import SwiftData

struct AddGoalRollView: View {
    var character: RPGCharacter
    var library: RulesLibrary?
    @Binding var isPresented: Bool

    // Optional: pick an existing template to prefill (still allows edits)
    @State private var selectedExistingTemplateID: PersistentIdentifier?
    @State private var showingGoalRollTemplatePicker = false

    // Template fields (create new OR update existing-by-name behavior kept simple)
    @State private var name: String = ""
    @State private var descriptionText: String = ""
    @State private var baseModifier: Int = 0
    @State private var userKeywords: String = ""

    // Defaults that will be stored on the template and used by non-branched rolls
    @State private var selectedAttributeID: PersistentIdentifier?
    @State private var selectedSkillMode: GoalRollTemplate.SkillMode = .natural
    @State private var selectedNaturalSkillID: PersistentIdentifier?
    @State private var selectedLearnedSkillTemplateID: PersistentIdentifier?

    @State private var showingLearnedTemplatePicker = false

    private let attributeCategoryOrder = ["Body", "Mind", "Spirit", "Occult"]
    private let learnedCategoryOrder = ["Learned Skills", "Lores", "Tongues"]

    private var goalRollTemplatesOrdered: [GoalRollTemplate] {
        guard let library else { return [] }
        return library.goalRollTemplates
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var attributesOrdered: [Stat] {
        let attrs = character.stats.filter { KeywordUtil.normalize($0.statType) == "attribute" }
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
            .filter { KeywordUtil.normalize($0.statType) == "skill" && $0.category == "Natural Skills" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private var learnedSkillTemplatesOrdered: [SkillTemplate] {
        guard let library else { return [] }
        let all = library.skillTemplates
        return all.sorted {
            let aIdx = learnedCategoryOrder.firstIndex(of: $0.category) ?? 999
            let bIdx = learnedCategoryOrder.firstIndex(of: $1.category) ?? 999
            if aIdx != bIdx { return aIdx < bIdx }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func templateByID(_ id: PersistentIdentifier?) -> GoalRollTemplate? {
        guard let id, let library else { return nil }
        return library.goalRollTemplates.first { $0.persistentModelID == id }
    }

    private func statByID(_ id: PersistentIdentifier?) -> Stat? {
        guard let id else { return nil }
        return character.stats.first { $0.persistentModelID == id }
    }

    private func skillTemplateByID(_ id: PersistentIdentifier?) -> SkillTemplate? {
        guard let id, let library else { return nil }
        return library.skillTemplates.first { $0.persistentModelID == id }
    }

    private var canAdd: Bool {
        guard library != nil else { return false }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        guard selectedAttributeID != nil else { return false }
        if selectedSkillMode == .natural {
            return selectedNaturalSkillID != nil
        } else {
            return selectedLearnedSkillTemplateID != nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Prefill From Library (Optional)") {
                    Button {
                        showingGoalRollTemplatePicker = true
                    } label: {
                        HStack {
                            Text("Choose Template")
                            Spacer()
                            if let t = templateByID(selectedExistingTemplateID) {
                                Text(t.name).foregroundStyle(.secondary)
                            } else {
                                Text("None").foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                    }
                    .disabled(library == nil || goalRollTemplatesOrdered.isEmpty)

                    if library == nil {
                        Text("Rules library not available yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if goalRollTemplatesOrdered.isEmpty {
                        Text("No goal roll templates yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Template") {
                    TextField("Goal roll name", text: $name)
                        .autocorrectionDisabled()

                    Stepper {
                        HStack {
                            Text("Base Modifier")
                            Spacer()
                            Text("\(baseModifier >= 0 ? "+" : "")\(baseModifier)")
                                .foregroundStyle(.secondary)
                        }
                    } onIncrement: { baseModifier += 1 }
                      onDecrement: { baseModifier -= 1 }

                    TextField("Keywords (comma-separated)", text: $userKeywords)
                        .autocorrectionDisabled()

                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 90)
                }

                Section("Formula Defaults") {
                    Picker("Attribute", selection: $selectedAttributeID) {
                        Text("Select...").tag(nil as PersistentIdentifier?)
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
                            Text("Select...").tag(nil as PersistentIdentifier?)
                            ForEach(naturalSkillsOrdered) { s in
                                Text(s.name).tag(s.persistentModelID as PersistentIdentifier?)
                            }
                        }
                    } else {
                        Button {
                            showingLearnedTemplatePicker = true
                        } label: {
                            HStack {
                                Text("Default Learned Skill")
                                Spacer()
                                if let st = skillTemplateByID(selectedLearnedSkillTemplateID) {
                                    Text("\(st.category): \(st.name)")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Select…").foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                        }
                        .disabled(library == nil || learnedSkillTemplatesOrdered.isEmpty)

                        if library != nil && learnedSkillTemplatesOrdered.isEmpty {
                            Text("No learned-skill templates exist yet. Create a Skill/Lore/Tongue template first.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("These defaults are used by all non-branched goal rolls created from this template.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Implicit Keywords Preview") {
                    let previewName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let preview = GoalRollTemplate(
                        name: previewName.isEmpty ? "New Goal Roll" : previewName,
                        templateDescription: descriptionText,
                        baseModifier: baseModifier,
                        userKeywords: userKeywords,
                        defaultAttributeName: "",
                        defaultAttributeCategory: "Body",
                        defaultSkillMode: .natural,
                        defaultNaturalSkillName: "",
                        defaultLearnedSkillTemplate: nil
                    )
                    Text(preview.implicitKeywords.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("This screen creates (or updates) a library template, then adds the roll to this character using the defaults above.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Goal Roll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create & Add") { createTemplateAndAddRoll() }
                        .disabled(!canAdd)
                }
            }
            .onChange(of: selectedSkillMode) { _, _ in
                // clear opposite selection when switching modes
                selectedNaturalSkillID = nil
                selectedLearnedSkillTemplateID = nil
            }
            .sheet(isPresented: $showingGoalRollTemplatePicker) {
                SearchableTemplatePickerSheet(
                    title: "Choose Goal Roll Template",
                    items: goalRollTemplatesOrdered,
                    itemTitle: { $0.name },
                    itemSubtitle: { $0.templateDescription },
                    onSelect: { chosen in
                        selectedExistingTemplateID = chosen.persistentModelID
                        applyTemplateToEditor(chosen)
                        showingGoalRollTemplatePicker = false
                    },
                    onCancel: {
                        showingGoalRollTemplatePicker = false
                    }
                )
            }
            .sheet(isPresented: $showingLearnedTemplatePicker) {
                SearchableTemplatePickerSheet(
                    title: "Choose Learned Skill Template",
                    items: learnedSkillTemplatesOrdered,
                    itemTitle: { "\($0.category): \($0.name)" },
                    itemSubtitle: { $0.templateDescription },
                    onSelect: { chosen in
                        selectedLearnedSkillTemplateID = chosen.persistentModelID
                        showingLearnedTemplatePicker = false
                    },
                    onCancel: {
                        showingLearnedTemplatePicker = false
                    }
                )
            }
        }
    }

    private func applyTemplateToEditor(_ template: GoalRollTemplate) {
        name = template.name
        descriptionText = template.templateDescription
        baseModifier = template.baseModifier
        userKeywords = template.userKeywords

        // Resolve defaults into this character’s IDs where possible
        if let attr = character.stats.first(where: {
            KeywordUtil.normalize($0.statType) == "attribute" &&
            $0.category == template.defaultAttributeCategory &&
            $0.name.caseInsensitiveCompare(template.defaultAttributeName) == .orderedSame
        }) {
            selectedAttributeID = attr.persistentModelID
        } else {
            selectedAttributeID = nil
        }

        selectedSkillMode = template.defaultSkillMode

        if template.defaultSkillMode == .natural {
            if let ns = character.stats.first(where: {
                KeywordUtil.normalize($0.statType) == "skill" &&
                $0.category == "Natural Skills" &&
                $0.name.caseInsensitiveCompare(template.defaultNaturalSkillName) == .orderedSame
            }) {
                selectedNaturalSkillID = ns.persistentModelID
            } else {
                selectedNaturalSkillID = nil
            }
            selectedLearnedSkillTemplateID = nil
        } else {
            selectedNaturalSkillID = nil
            selectedLearnedSkillTemplateID = template.defaultLearnedSkillTemplate?.persistentModelID
        }
    }

    private func createTemplateAndAddRoll() {
        guard let library else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let attr = statByID(selectedAttributeID) else { return }

        // Prefer: if user selected an existing template, update THAT one.
        // Otherwise: update-by-name (case-insensitive), else create new.
        let template: GoalRollTemplate

        if let selected = templateByID(selectedExistingTemplateID) {
            template = selected
        } else if let existingByName = library.goalRollTemplates.first(where: {
            $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }) {
            template = existingByName
        } else {
            let newTemplate = GoalRollTemplate(
                name: trimmedName,
                templateDescription: "",
                baseModifier: 0,
                userKeywords: "",
                defaultAttributeName: "",
                defaultAttributeCategory: "Body",
                defaultSkillMode: .natural,
                defaultNaturalSkillName: "",
                defaultLearnedSkillTemplate: nil
            )
            library.goalRollTemplates.append(newTemplate)
            template = newTemplate
        }

        // Update template fields
        template.name = trimmedName
        template.templateDescription = descriptionText
        template.baseModifier = baseModifier
        template.userKeywords = userKeywords

        // Save defaults
        template.defaultAttributeName = attr.name
        template.defaultAttributeCategory = attr.category
        template.defaultSkillMode = selectedSkillMode

        if selectedSkillMode == .natural {
            guard let ns = statByID(selectedNaturalSkillID) else { return }
            template.defaultNaturalSkillName = ns.name
            template.defaultLearnedSkillTemplate = nil
        } else {
            guard let st = skillTemplateByID(selectedLearnedSkillTemplateID) else { return }
            template.defaultNaturalSkillName = ""
            template.defaultLearnedSkillTemplate = st
        }

        // Add the roll to this character using the chosen defaults
        if selectedSkillMode == .natural {
            guard let ns = statByID(selectedNaturalSkillID) else { return }
            character.goalRolls.append(
                CharacterGoalRoll(template: template, attributeStat: attr, naturalSkillStat: ns, characterSkill: nil)
            )
        } else {
            guard let st = template.defaultLearnedSkillTemplate else { return }

            let cs: CharacterSkill
            if let existingCS = character.learnedSkills.first(where: { $0.template?.persistentModelID == st.persistentModelID }) {
                cs = existingCS
            } else {
                let newCS = CharacterSkill(template: st, value: 0)
                character.learnedSkills.append(newCS)
                cs = newCS
            }

            character.goalRolls.append(
                CharacterGoalRoll(template: template, attributeStat: attr, naturalSkillStat: nil, characterSkill: cs)
            )
        }

        isPresented = false
    }
}
