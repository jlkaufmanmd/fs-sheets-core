import SwiftUI
import SwiftData

struct AddInitiativeView: View {
    var character: RPGCharacter
    var library: RulesLibrary
    @Binding var isPresented: Bool
    let subcategory: String // "Physical" or "Occult"

    @State private var selectedSkill: String = ""
    @State private var description: String = ""
    @State private var userKeywords: String = ""

    private var existingInitiativeSkills: Set<String> {
        Set(character.combatMetrics
            .compactMap { $0.template }
            .filter { $0.isInitiative }
            .map { $0.associatedSkillName })
    }

    private var availableNaturalSkills: [String] {
        character.stats
            .filter { $0.statType == "skill" }
            .map { $0.name }
            .filter { !existingInitiativeSkills.contains($0) }
            .sorted()
    }

    private var availableLearnedSkills: [String] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Learned Skills" }
            .map { $0.effectiveName }
            .filter { !existingInitiativeSkills.contains($0) }
            .sorted()
    }

    private var availableLores: [String] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Lores" }
            .map { $0.effectiveName }
            .filter { !existingInitiativeSkills.contains($0) }
            .sorted()
    }

    private var allAvailableSkills: [(category: String, skills: [String])] {
        var result: [(String, [String])] = []

        if !availableNaturalSkills.isEmpty {
            result.append(("Natural Skills", availableNaturalSkills))
        }
        if !availableLearnedSkills.isEmpty {
            result.append(("Learned Skills", availableLearnedSkills))
        }
        if !availableLores.isEmpty {
            result.append(("Lore Skills", availableLores))
        }

        return result
    }

    private var hasAnySkills: Bool {
        !availableNaturalSkills.isEmpty || !availableLearnedSkills.isEmpty || !availableLores.isEmpty
    }

    private var canAdd: Bool {
        !selectedSkill.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("New Initiative") {
                    if !hasAnySkills {
                        Text("No skills available for initiative")
                            .foregroundStyle(.secondary)
                    } else {
                        NavigationLink {
                            SkillSelectionView(
                                selectedSkill: $selectedSkill,
                                skillsByCategory: allAvailableSkills
                            )
                        } label: {
                            HStack {
                                Text("Associated Skill")
                                Spacer()
                                if selectedSkill.isEmpty {
                                    Text("Select...")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(selectedSkill)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if !selectedSkill.isEmpty {
                    Section("Preview") {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text("Initiative (\(selectedSkill))")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Category")
                            Spacer()
                            Text(subcategory)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Base Value")
                            Spacer()
                            Text("0")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Optional Customization") {
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Description (optional)...")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $description)
                                .frame(minHeight: 60)
                        }

                        TextField("Additional keywords (comma-separated)", text: $userKeywords)
                            .autocorrectionDisabled()
                    }
                }
            }
            .navigationTitle("New Initiative")
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
        }
    }

    private func add() {
        guard !selectedSkill.isEmpty else { return }

        // Create template for this initiative
        let initiativeName = "Initiative (\(selectedSkill))"
        let additionalKeywords = "\(selectedSkill.lowercased()) initiative" + (userKeywords.isEmpty ? "" : ", \(userKeywords)")

        let template = CombatMetricTemplate(
            name: initiativeName,
            subcategory: subcategory,
            templateDescription: description,
            additionalKeywords: additionalKeywords,
            baseValueFormula: "0",
            isInitiative: true,
            associatedSkillName: selectedSkill
        )

        library.combatMetricTemplates.append(template)

        // Add to character
        let metric = CharacterCombatMetric(template: template)
        character.combatMetrics.append(metric)

        isPresented = false
    }
}

// MARK: - Skill Selection View

struct SkillSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSkill: String
    let skillsByCategory: [(category: String, skills: [String])]

    var body: some View {
        Form {
            ForEach(skillsByCategory, id: \.category) { categoryGroup in
                Section(categoryGroup.category) {
                    ForEach(categoryGroup.skills, id: \.self) { skill in
                        Button {
                            selectedSkill = skill
                            dismiss()
                        } label: {
                            HStack {
                                Text(skill)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedSkill == skill {
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
