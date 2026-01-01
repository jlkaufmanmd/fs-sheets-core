import SwiftUI
import SwiftData

struct AddCharacterSkillView: View {
    var character: RPGCharacter
    var library: RulesLibrary?
    @Binding var isPresented: Bool

    @State private var category: String = "Learned Skills"
    @State private var name: String = ""
    @State private var descriptionText: String = ""
    @State private var userKeywords: String = ""

    @State private var showingDuplicateNameAlert = false

    private let categories = ["Learned Skills", "Lores", "Tongues"]

    private var canAdd: Bool {
        guard library != nil else { return false }
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }

                    TextField("Skill name", text: $name)
                        .autocorrectionDisabled()

                    TextField("Keywords (comma-separated)", text: $userKeywords)
                        .autocorrectionDisabled()

                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 90)
                }

                Section {
                    Text("This creates (or overwrites) a shared library template, then adds the skill to this character at value 0. You can branch later per character.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create & Add") { createTemplateAndAddSkill() }
                        .disabled(!canAdd)
                }
            }
            .alert("Duplicate Template Name", isPresented: $showingDuplicateNameAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A skill template with this name already exists and could not be overwritten due to the uniqueness constraint. Rename it and try again.")
            }
        }
    }

    private func createTemplateAndAddSkill() {
        guard let library else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let template: SkillTemplate
        if let existing = library.skillTemplates.first(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            // Overwrite existing template (note: category/name are unique by name only in your model)
            existing.category = category
            existing.templateDescription = descriptionText
            existing.userKeywords = userKeywords
            template = existing
        } else {
            let newTemplate = SkillTemplate(
                name: trimmedName,
                category: category,
                templateDescription: descriptionText,
                userKeywords: userKeywords
            )
            library.skillTemplates.append(newTemplate)
            template = newTemplate
        }

        // Add to character (prevent duplicates by template reference)
        if character.learnedSkills.contains(where: { $0.template?.persistentModelID == template.persistentModelID }) == false {
            let newSkill = CharacterSkill(template: template, value: 0)
            character.learnedSkills.append(newSkill)
        }

        isPresented = false
    }
}
