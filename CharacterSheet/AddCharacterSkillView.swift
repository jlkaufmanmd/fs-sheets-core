import SwiftUI
import SwiftData

struct AddCharacterSkillView: View {
    var character: RPGCharacter
    var library: RulesLibrary?
    @Binding var isPresented: Bool

    @State private var selectedCategory: String = "Learned Skills"

    // Template selection
    @State private var selectedTemplateID: PersistentIdentifier?
    @State private var showingTemplatePicker = false

    // Creating new template
    @State private var customName: String = ""
    @State private var createAsCategory: String = "Learned Skills"

    private let categories = ["Learned Skills", "Lores", "Tongues"]

    private var templatesForSelectedCategory: [SkillTemplate] {
        guard let library else { return [] }
        return library.skillTemplates
            .filter { $0.category == selectedCategory }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func templateByID(_ id: PersistentIdentifier?) -> SkillTemplate? {
        guard let id else { return nil }
        return templatesForSelectedCategory.first { $0.persistentModelID == id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Choose Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Template") {
                    HStack {
                        Text("From Library")
                        Spacer()
                        Button {
                            showingTemplatePicker = true
                        } label: {
                            if let t = templateByID(selectedTemplateID) {
                                Text(t.name).foregroundStyle(.tint)
                            } else {
                                Text("Choose…").foregroundStyle(.tint)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if let t = templateByID(selectedTemplateID), !t.templateDescription.isEmpty {
                        Text(t.templateDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Picker("New Template Category", selection: $createAsCategory) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }

                    TextField("Or create new template name", text: $customName)
                        .autocorrectionDisabled()
                }

                Section {
                    Text("Adding from library keeps the shared template. You can branch later per character.")
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
                    Button("Add") { addSkill() }
                        .disabled(!canAdd)
                }
            }
            .onChange(of: selectedCategory) { _, _ in
                // Reset selection when changing category
                selectedTemplateID = nil
            }
            .sheet(isPresented: $showingTemplatePicker) {
                SearchableTemplatePickerSheet(
                    title: selectedCategory,
                    prompt: "Search…",
                    items: templatesForSelectedCategory,
                    name: { $0.name },
                    subtitle: { $0.templateDescription }
                ) { picked in
                    selectedTemplateID = picked.persistentModelID
                }
            }
        }
    }

    private var canAdd: Bool {
        if templateByID(selectedTemplateID) != nil { return true }
        return !customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addSkill() {
        guard let library else { return }

        // If a template is selected, add that
        if let selected = templateByID(selectedTemplateID) {
            // Prevent duplicates of the same template on the character
            if character.learnedSkills.contains(where: { $0.template?.persistentModelID == selected.persistentModelID }) {
                isPresented = false
                return
            }
            character.learnedSkills.append(CharacterSkill(template: selected, value: 0))
            isPresented = false
            return
        }

        // Otherwise create (or reuse existing) template by name+category
        let name = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        if let existing = library.skillTemplates.first(where: {
            $0.category == createAsCategory && $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            if !character.learnedSkills.contains(where: { $0.template?.persistentModelID == existing.persistentModelID }) {
                character.learnedSkills.append(CharacterSkill(template: existing, value: 0))
            }
            isPresented = false
            return
        }

        let template = SkillTemplate(name: name, category: createAsCategory)
        library.skillTemplates.append(template)

        character.learnedSkills.append(CharacterSkill(template: template, value: 0))
        isPresented = false
    }
}
