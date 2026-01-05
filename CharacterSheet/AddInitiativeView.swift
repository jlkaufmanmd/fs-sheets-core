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

    private var availableSkills: [String] {
        let existingInitiativeSkills = Set(character.combatMetrics
            .compactMap { $0.template }
            .filter { $0.isInitiative }
            .map { $0.associatedSkillName })

        var allSkills: [String] = []
        allSkills.append(contentsOf: character.stats.filter { $0.statType == "skill" }.map { $0.name })
        allSkills.append(contentsOf: character.learnedSkills.map { $0.effectiveName })

        return allSkills.filter { !existingInitiativeSkills.contains($0) }.sorted()
    }

    private var canAdd: Bool {
        !selectedSkill.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("New Initiative") {
                    if availableSkills.isEmpty {
                        Text("No skills available for initiative")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Associated Skill", selection: $selectedSkill) {
                            Text("Select a skill...").tag("")
                            ForEach(availableSkills, id: \.self) { skill in
                                Text(skill).tag(skill)
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
