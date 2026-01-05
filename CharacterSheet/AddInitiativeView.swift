import SwiftUI
import SwiftData

struct AddInitiativeView: View {
    var character: RPGCharacter
    var library: RulesLibrary
    @Binding var isPresented: Bool
    let subcategory: String // "Physical" or "Occult"

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

    var body: some View {
        NavigationStack {
            Form {
                if !hasAnySkills {
                    Section {
                        Text("No skills available for initiative")
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("New Initiative")
                    }
                } else {
                    Section {
                        Text("Select a skill to create an initiative. The initiative value will equal the skill's current value and update automatically when the skill changes.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("New Initiative")
                    }

                    InitiativeSkillSelectionView(
                        skillsByCategory: allAvailableSkills,
                        onSelect: { skillName in
                            addInitiative(for: skillName)
                        }
                    )
                }
            }
            .navigationTitle("New Initiative")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private func addInitiative(for skillName: String) {
        // Create template for this initiative
        let initiativeName = "Initiative (\(skillName))"
        let additionalKeywords = "\(skillName.lowercased()) initiative"

        let template = CombatMetricTemplate(
            name: initiativeName,
            subcategory: subcategory,
            templateDescription: "",
            additionalKeywords: additionalKeywords,
            baseValueFormula: skillName, // Use skill name as formula
            isInitiative: true,
            associatedSkillName: skillName
        )

        library.combatMetricTemplates.append(template)

        // Add to character
        let metric = CharacterCombatMetric(template: template)
        character.combatMetrics.append(metric)

        isPresented = false
    }
}

// MARK: - Skill Selection View

struct InitiativeSkillSelectionView: View {
    let skillsByCategory: [(category: String, skills: [String])]
    let onSelect: (String) -> Void

    var body: some View {
        ForEach(skillsByCategory, id: \.category) { categoryGroup in
            Section(categoryGroup.category) {
                ForEach(categoryGroup.skills, id: \.self) { skill in
                    Button {
                        onSelect(skill)
                    } label: {
                        Text(skill)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
}
