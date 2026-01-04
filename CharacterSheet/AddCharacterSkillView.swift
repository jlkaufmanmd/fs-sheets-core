import SwiftUI
import SwiftData

struct AddCharacterSkillView: View {
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
    @State private var category: String = "Learned Skills"

    private var template: SkillTemplate? {
        guard case .fromTemplate(let id) = mode else { return nil }
        return library.skillTemplates.first(where: { $0.persistentModelID == id })
    }

    private var canAdd: Bool {
        switch mode {
        case .new:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .fromTemplate:
            return template != nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                switch mode {
                case .new:
                    Section("New Skill") {
                        TextField("Name", text: $name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()

                        Picker("Category", selection: $category) {
                            Text("Learned Skills").tag("Learned Skills")
                            Text("Lores").tag("Lores")
                            Text("Tongues").tag("Tongues")
                        }
                    }

                case .fromTemplate:
                    Section("Adding Skill") {
                        if let template {
                            Text(template.name).font(.headline)
                            Text(template.category)
                                .font(.callout)
                                .foregroundStyle(.secondary)
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
        case .new: return "New Skill"
        case .fromTemplate: return "Add Skill"
        }
    }

    private func add() {
        switch mode {
        case .new:
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { return }

            let template = SkillTemplate(
                name: trimmedName,
                category: category,
                templateDescription: "",
                userKeywords: ""
            )

            library.skillTemplates.append(template)
            let skill = CharacterSkill(template: template, value: 1)
            character.learnedSkills.append(skill)
            isPresented = false

        case .fromTemplate:
            guard let template else { return }

            let skill = CharacterSkill(template: template, value: 1)
            character.learnedSkills.append(skill)
            isPresented = false
        }
    }
}
