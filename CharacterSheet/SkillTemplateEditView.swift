import SwiftUI
import SwiftData

struct SkillTemplateEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var template: SkillTemplate
    var library: RulesLibrary?

    @State private var editedName = ""
    @State private var editedDescription = ""
    @State private var editedKeywords = ""
    @State private var showingDuplicateAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $editedName)
                        .autocorrectionDisabled()
                }

                Section("Category") {
                    Text(template.category)
                        .foregroundStyle(.secondary)
                }

                Section("Description") {
                    TextEditor(text: $editedDescription)
                        .frame(minHeight: 120)
                }

                Section("Keywords") {
                    TextField("Comma-separated", text: $editedKeywords)
                        .autocorrectionDisabled()
                }

                Section("Keywords Preview") {
                    let preview = SkillTemplate(
                        name: editedName.trimmingCharacters(in: .whitespacesAndNewlines),
                        category: template.category,
                        templateDescription: editedDescription,
                        userKeywords: editedKeywords
                    )
                    Text(preview.keywordsForRules.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("Edits here affect all non-branched character skills using this template.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                editedName = template.name
                editedDescription = template.templateDescription
                editedKeywords = template.userKeywords
            }
            .alert("Duplicate Name", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A template with this name already exists in this category. Choose a different name.")
            }
        }
    }

    private func save() {
        let name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        if let library {
            let dup = library.skillTemplates.contains {
                $0.persistentModelID != template.persistentModelID &&
                $0.category == template.category &&
                $0.name.caseInsensitiveCompare(name) == .orderedSame
            }
            if dup {
                showingDuplicateAlert = true
                return
            }
        }

        template.name = name
        template.templateDescription = editedDescription
        template.userKeywords = editedKeywords
        dismiss()
    }
}
