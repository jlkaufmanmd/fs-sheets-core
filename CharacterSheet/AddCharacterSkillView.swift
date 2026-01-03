import SwiftUI
import SwiftData

struct AddCharacterSkillView: View {
    var character: RPGCharacter
    var library: RulesLibrary?
    @Binding var isPresented: Bool

    @State private var selectedTemplateID: PersistentIdentifier?
    @State private var customName: String = ""
    @State private var customValue: Int = 0
    @State private var showingTemplatePicker = false

    private var templatesSorted: [SkillTemplate] {
        guard let library else { return [] }
        return library.skillTemplates.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var selectedTemplate: SkillTemplate? {
        guard let selectedTemplateID else { return nil }
        return templatesSorted.first(where: { $0.persistentModelID == selectedTemplateID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    Button {
                        showingTemplatePicker = true
                    } label: {
                        HStack {
                            Text(selectedTemplate?.name.isEmpty == false ? selectedTemplate!.name : "Select…")
                                .foregroundStyle(selectedTemplate == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let t = selectedTemplate {
                        Text(t.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Name Override (Optional)") {
                    TextField("Leave blank to use template name", text: $customName)
                        .autocorrectionDisabled()
                }

                Section("Starting Value") {
                    Stepper(value: $customValue, in: 0...50) {
                        Text("\(customValue)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }

                Section {
                    Button("Add Skill") {
                        addSkill()
                    }
                    .disabled(selectedTemplate == nil)
                }
            }
            .navigationTitle("Add Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                SearchableTemplatePickerSheet(
                    title: "Pick a Skill Template",
                    prompt: "Search templates",
                    items: templatesSorted,
                    name: { $0.name },
                    subtitle: { $0.category }
                ) { picked in
                    selectedTemplateID = picked.persistentModelID
                    // convenience: if user hasn't typed an override, keep it empty
                }
            }
        }
    }

    private func addSkill() {
        guard let template = selectedTemplate else { return }

        let newSkill = CharacterSkill(template: template, value: customValue)
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            // Branch immediately if they override the name at creation time
            newSkill.isBranched = true
            newSkill.branchedDate = Date()
            newSkill.overrideName = trimmed
            newSkill.overrideCategory = template.category
            newSkill.overrideDescription = template.templateDescription
            newSkill.overrideUserKeywords = template.userKeywords
        }

        character.learnedSkills.append(newSkill)
        isPresented = false
    }
}
