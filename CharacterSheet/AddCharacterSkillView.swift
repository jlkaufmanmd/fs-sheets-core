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
    @State private var description: String = ""
    @State private var keywords: String = ""
    @State private var category: String = "Learned Skills"
    @State private var startingValue: Int = 0

    // Template mode customization
    @State private var customizeForCharacter: Bool = false
    @State private var customName: String = ""
    @State private var customValue: Int = 0

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
                                .frame(minHeight: 100)
                        }

                    }

                    Section("Starting Value") {
                        Stepper(value: $startingValue, in: 0...50) {
                            Text("\(startingValue)")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }

                case .fromTemplate:
                    Section("Template") {
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

                    Section {
                        Toggle("Customize for this character", isOn: $customizeForCharacter)
                    }

                    if customizeForCharacter {
                        Section("Customization") {
                            TextField("Name (optional)", text: $customName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()

                            Stepper(value: $customValue, in: 0...50) {
                                Text("Starting Value: \(customValue)")
                                    .fontWeight(.semibold)
                            }
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
            .onAppear {
                if template != nil {
                    customValue = 0
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
                templateDescription: description,
                userKeywords: keywords
            )

            library.skillTemplates.append(template)
            let skill = CharacterSkill(template: template, value: startingValue)
            character.learnedSkills.append(skill)
            isPresented = false

        case .fromTemplate:
            guard let template else { return }

            let skill = CharacterSkill(template: template, value: customValue)

            if customizeForCharacter {
                let n = customName.trimmingCharacters(in: .whitespacesAndNewlines)

                if !n.isEmpty || customValue != 0 {
                    skill.isBranched = true
                    skill.branchedDate = Date()
                    skill.overrideName = n.isEmpty ? template.name : n
                    skill.overrideCategory = template.category
                    skill.overrideDescription = template.templateDescription
                    skill.overrideUserKeywords = template.userKeywords
                    skill.value = customValue
                }
            }

            character.learnedSkills.append(skill)
            isPresented = false
        }
    }
}
