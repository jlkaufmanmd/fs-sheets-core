import SwiftUI
import SwiftData

struct AddCharacterSkillView: View {
    var character: RPGCharacter
    var library: RulesLibrary?
    @Binding var isPresented: Bool

    // Category is required for SkillTemplate
    @State private var selectedCategory: String = "Learned Skills"
    private let categories = ["Learned Skills", "Lores", "Tongues"]

    // Pick existing template
    @State private var selectedTemplateID: PersistentIdentifier?
    @State private var showingTemplatePicker = false

    // Create new template
    @State private var customName: String = ""
    @State private var customDescription: String = ""
    @State private var customKeywords: String = ""

    private var templatesInSelectedCategory: [SkillTemplate] {
        guard let library else { return [] }
        return library.skillTemplates
            .filter { $0.category == selectedCategory }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func templateByID(_ id: PersistentIdentifier?) -> SkillTemplate? {
        guard let id, let library else { return nil }
        return library.skillTemplates.first { $0.persistentModelID == id }
    }

    private var canAdd: Bool {
        guard library != nil else { return false }
        if selectedTemplateID != nil { return true }
        return !customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedCategory) { _, _ in
                        // Keep selection consistent with visible category
                        selectedTemplateID = nil
                    }
                }

                Section("Add From Library") {
                    Button {
                        showingTemplatePicker = true
                    } label: {
                        HStack {
                            Text("Choose Template")
                            Spacer()
                            if let t = templateByID(selectedTemplateID) {
                                Text(t.name).foregroundStyle(.secondary)
                            } else {
                                Text("None").foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .disabled(library == nil || templatesInSelectedCategory.isEmpty)

                    if library == nil {
                        Text("Rules library not available yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if templatesInSelectedCategory.isEmpty {
                        Text("No templates in \(selectedCategory) yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let t = templateByID(selectedTemplateID),
                              !t.templateDescription.isEmpty {
                        Text(t.templateDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Or Create New Template") {
                    TextField("New skill name", text: $customName)
                        .autocorrectionDisabled()

                    TextField("Keywords (comma-separated)", text: $customKeywords)
                        .autocorrectionDisabled()

                    TextEditor(text: $customDescription)
                        .frame(minHeight: 90)
                }

                Section("Implicit Keywords Preview") {
                    let previewName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let preview = SkillTemplate(
                        name: previewName.isEmpty ? "New Skill" : previewName,
                        category: selectedCategory,
                        templateDescription: customDescription,
                        userKeywords: customKeywords
                    )
                    Text(preview.implicitKeywords.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("Tip: Picking a template preserves the shared library version. Creating a new template adds it to the library, then adds the skill to this character.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Skill")
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
            .sheet(isPresented: $showingTemplatePicker) {
                SearchableTemplatePickerSheet(
                    title: "Choose \(selectedCategory) Template",
                    items: templatesInSelectedCategory,
                    itemTitle: { $0.name },
                    itemSubtitle: { $0.templateDescription },
                    onSelect: { chosen in
                        selectedTemplateID = chosen.persistentModelID
                        showingTemplatePicker = false
                    },
                    onCancel: {
                        showingTemplatePicker = false
                    }
                )
            }
        }
    }

    private func add() {
        guard let library else { return }

        // 1) Add from selected existing template
        if let t = templateByID(selectedTemplateID) {
            // Prevent duplicates of same template on the character
            if !character.learnedSkills.contains(where: { $0.template?.persistentModelID == t.persistentModelID }) {
                character.learnedSkills.append(CharacterSkill(template: t, value: 0))
            }
            isPresented = false
            return
        }

        // 2) Create (or reuse if same name/category) then add
        let name = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let existing = library.skillTemplates.first(where: {
            $0.category == selectedCategory &&
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        })

        let template: SkillTemplate
        if let existing {
            template = existing
        } else {
            let t = SkillTemplate(
                name: name,
                category: selectedCategory,
                templateDescription: customDescription,
                userKeywords: customKeywords
            )
            library.skillTemplates.append(t)
            template = t
        }

        if !character.learnedSkills.contains(where: { $0.template?.persistentModelID == template.persistentModelID }) {
            character.learnedSkills.append(CharacterSkill(template: template, value: 0))
        }

        isPresented = false
    }
}
