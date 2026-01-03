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

    @State private var name: String = ""
    @State private var category: String = "Learned Skills"
    @State private var description: String = ""
    @State private var keywords: String = ""

    // Template mode
    @State private var customizeForCharacter: Bool = false
    @State private var customName: String = ""
    @State private var customDescription: String = ""
    @State private var customKeywords: String = ""
    @State private var startingValue: Int = 0

    private let categories = ["Learned Skills", "Lores", "Tongues"]

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
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }

                        TextField("Keywords (comma-separated)", text: $keywords)
                            .autocorrectionDisabled()

                        TextEditor(text: $description)
                            .frame(minHeight: 110)
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
                        if let t = template {
                            Text(t.name)
                                .font(.headline)
                            Text(t.category)
                                .foregroundStyle(.secondary)
                            if !t.templateDescription.isEmpty {
                                Text(t.templateDescription)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Missing template.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Starting Value") {
                        Stepper(value: $startingValue, in: 0...50) {
                            Text("\(startingValue)")
                                .font(.title3)
                                .fontWeight(.semibold)
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

                            TextField("Keywords (comma-separated)", text: $customKeywords)
                                .autocorrectionDisabled()

                            TextEditor(text: $customDescription)
                                .frame(minHeight: 110)
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        add()
                    }
                    .disabled(!canAdd)
                }
            }
            .onAppear {
                if let t = template {
                    // Default suggested customization values (blank unless toggled)
                    customName = ""
                    customDescription = ""
                    customKeywords = ""
                    startingValue = 0
                    // If you prefer: prefill custom fields with template values
                    // customName = t.name
                    // customDescription = t.templateDescription
                    // customKeywords = t.userKeywords
                }
            }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .new: return "New Learned Skill"
        case .fromTemplate: return "Add Learned Skill"
        }
    }

    private func add() {
        switch mode {
        case .new:
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            let newTemplate = SkillTemplate(
                name: trimmed,
                category: category,
                templateDescription: description,
                userKeywords: keywords
            )
            library.skillTemplates.append(newTemplate)

            let skill = CharacterSkill(template: newTemplate, value: startingValue)
            character.learnedSkills.append(skill)
            isPresented = false

        case .fromTemplate:
            guard let t = template else { return }

            let skill = CharacterSkill(template: t, value: startingValue)

            if customizeForCharacter {
                // Branch only if something was actually entered
                let n = customName.trimmingCharacters(in: .whitespacesAndNewlines)
                let d = customDescription
                let k = customKeywords

                let hasAny = !n.isEmpty || !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !k.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                if hasAny {
                    skill.isBranched = true
                    skill.branchedDate = Date()
                    skill.overrideName = n.isEmpty ? t.name : n
                    skill.overrideCategory = t.category
                    skill.overrideDescription = d.isEmpty ? t.templateDescription : d
                    skill.overrideUserKeywords = k.isEmpty ? t.userKeywords : k
                }
            }

            character.learnedSkills.append(skill)
            isPresented = false
        }
    }
}
