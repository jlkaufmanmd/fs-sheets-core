import SwiftUI
import SwiftData

struct AddGoalRollView: View {
    var character: RPGCharacter
    var library: RulesLibrary?
    @Binding var isPresented: Bool

    // MARK: - UI State
    @State private var name: String = ""
    @State private var descriptionText: String = ""
    @State private var baseModifier: Int = 0
    @State private var userKeywords: String = ""

    // store IDs to avoid SwiftUI Picker hash issues with SwiftData models
    @State private var selectedAttributeID: PersistentIdentifier?
    @State private var selectedSkillMode: GoalRollTemplate.SkillMode = .natural
    @State private var selectedNaturalSkillID: PersistentIdentifier?
    @State private var selectedLearnedSkillTemplateID: PersistentIdentifier?

    @State private var showingDuplicateNameAlert = false

    // MARK: - Requirements
    private let attributeCategoryOrder = ["Body", "Mind", "Spirit", "Occult"]
    private let learnedCategoryOrder = ["Learned Skills", "Lores", "Tongues"]

    // MARK: - Derived lists
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

    // MARK: - Lookups
    private func statByID(_ id: PersistentIdentifier?) -> Stat? {
        guard let id else { return nil }
        return character.stats.first { $0.persistentModelID == id }
    }

    private func skillTemplateByID(_ id: PersistentIdentifier?) -> SkillTemplate? {
        guard let id, let library else { return nil }
        return library.skillTemplates.first { $0.persistentModelID == id }
    }

    // MARK: - Validation
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
                    } onIncrement: {
                        baseModifier += 1
                    } onDecrement: {
                        baseModifier -= 1
                    }

                    TextField("Keywords (comma-separated)", text: $userKeywords)
                        .autocorrectionDisabled()

                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 90)
                }

                Section("Default Formula") {
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
                                Text(s.name)
                                    .tag(s.persistentModelID as PersistentIdentifier?)
                            }
                        }
                    } else {
                        Picker("Learned/Lore/Tongue", selection: $selectedLearnedSkillTemplateID) {
                            Text("Select...").tag(nil as PersistentIdentifier?)
                            ForEach(learnedSkillTemplatesOrdered) { t in
                                Text("\(t.category): \(t.name)")
                                    .tag(t.persistentModelID as PersistentIdentifier?)
                            }
                        }
                    }
                }

                Section {
                    Text("This screen creates (or overwrites) a library template, then adds the roll to this character using the defaults above. You can still change the roll’s attribute/skill later per character.")
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
                // clear opposite selection
                selectedNaturalSkillID = nil
                selectedLearnedSkillTemplateID = nil
            }
            .alert("Duplicate Template Name", isPresented: $showingDuplicateNameAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A goal roll template with this name already exists and could not be overwritten due to the uniqueness constraint. Rename it and try again.")
            }
        }
    }

    // MARK: - Create/Overwrite + Add
    private func createTemplateAndAddRoll() {
        guard let library else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        guard let attr = statByID(selectedAttributeID) else { return }

        // Resolve (reuse + overwrite) OR create new
        let template: GoalRollTemplate
        if let existing = library.goalRollTemplates.first(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            // "Overwrite" existing template
            existing.templateDescription = descriptionText
            existing.baseModifier = baseModifier
            existing.userKeywords = userKeywords

            existing.defaultAttributeName = attr.name
            existing.defaultAttributeCategory = attr.category
            existing.defaultSkillMode = selectedSkillMode

            if selectedSkillMode == .natural {
                guard let ns = statByID(selectedNaturalSkillID) else { return }
                existing.defaultNaturalSkillName = ns.name
                existing.defaultLearnedSkillTemplate = nil
            } else {
                guard let st = skillTemplateByID(selectedLearnedSkillTemplateID) else { return }
                existing.defaultNaturalSkillName = ""
                existing.defaultLearnedSkillTemplate = st
            }

            template = existing
        } else {
            // Create new template with defaults
            let newTemplate = GoalRollTemplate(
                name: trimmedName,
                templateDescription: descriptionText,
                baseModifier: baseModifier,
                userKeywords: userKeywords,
                defaultAttributeName: attr.name,
                defaultAttributeCategory: attr.category,
                defaultSkillMode: selectedSkillMode,
                defaultNaturalSkillName: "",
                defaultLearnedSkillTemplate: nil
            )

            if selectedSkillMode == .natural {
                guard let ns = statByID(selectedNaturalSkillID) else { return }
                newTemplate.defaultNaturalSkillName = ns.name
            } else {
                guard let st = skillTemplateByID(selectedLearnedSkillTemplateID) else { return }
                newTemplate.defaultLearnedSkillTemplate = st
            }

            // Add to library (SwiftData will persist via relationship)
            library.goalRollTemplates.append(newTemplate)
            template = newTemplate
        }

        // Now add the CharacterGoalRoll instance using defaults
        if selectedSkillMode == .natural {
            guard let ns = statByID(selectedNaturalSkillID) else { return }
            let roll = CharacterGoalRoll(
                template: template,
                attributeStat: attr,
                naturalSkillStat: ns,
                characterSkill: nil
            )
            character.goalRolls.append(roll)
        } else {
            guard let st = template.defaultLearnedSkillTemplate else { return }

            // ensure character has the CharacterSkill for that template
            let cs: CharacterSkill
            if let existingCS = character.learnedSkills.first(where: { $0.template?.persistentModelID == st.persistentModelID }) {
                cs = existingCS
            } else {
                let newCS = CharacterSkill(template: st, value: 0)
                character.learnedSkills.append(newCS)
                cs = newCS
            }

            let roll = CharacterGoalRoll(
                template: template,
                attributeStat: attr,
                naturalSkillStat: nil,
                characterSkill: cs
            )
            character.goalRolls.append(roll)
        }

        isPresented = false
    }
}
