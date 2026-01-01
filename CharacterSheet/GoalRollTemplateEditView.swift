import SwiftUI
import SwiftData

struct GoalRollTemplateEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var template: GoalRollTemplate
    var library: RulesLibrary?

    @State private var editedName = ""
    @State private var editedDescription = ""
    @State private var editedKeywords = ""
    @State private var editedBaseModifier: Int = 0

    // Formula defaults
    private let attributeCategoryOrder = ["Body", "Mind", "Spirit", "Occult"]
    @State private var editedAttrCategory = "Body"
    @State private var editedAttrName = ""
    @State private var editedSkillMode: GoalRollTemplate.SkillMode = .natural
    @State private var editedNaturalSkillName = ""
    @State private var editedLearnedSkillTemplateID: PersistentIdentifier?

    @State private var showingDuplicateAlert = false

    private var learnedTemplatesGrouped: [(String, [SkillTemplate])] {
        guard let library else { return [] }
        let order = ["Learned Skills", "Lores", "Tongues"]
        return order.compactMap { cat in
            let items = library.skillTemplates
                .filter { $0.category == cat }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    private func learnedTemplateByID(_ id: PersistentIdentifier?) -> SkillTemplate? {
        guard let id, let library else { return nil }
        return library.skillTemplates.first(where: { $0.persistentModelID == id })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $editedName)
                        .autocorrectionDisabled()
                }

                Section("Description") {
                    TextEditor(text: $editedDescription)
                        .frame(minHeight: 120)
                }

                Section("Base Modifier") {
                    HStack {
                        Button { editedBaseModifier -= 1 } label: {
                            Image(systemName: "minus.circle.fill").font(.title2)
                        }.buttonStyle(.borderless)

                        Spacer()

                        Text("\(editedBaseModifier)")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Button { editedBaseModifier += 1 } label: {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }.buttonStyle(.borderless)
                    }
                }

                Section("Keywords") {
                    TextField("Comma-separated", text: $editedKeywords)
                        .autocorrectionDisabled()
                }

                Section("Formula Defaults") {
                    Picker("Attribute Category", selection: $editedAttrCategory) {
                        ForEach(attributeCategoryOrder, id: \.self) { Text($0).tag($0) }
                    }

                    TextField("Attribute Name", text: $editedAttrName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)

                    Picker("Skill Mode", selection: $editedSkillMode) {
                        ForEach(GoalRollTemplate.SkillMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    if editedSkillMode == .natural {
                        TextField("Natural Skill Name", text: $editedNaturalSkillName)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                    } else {
                        if learnedTemplatesGrouped.isEmpty {
                            Text("No learned-skill templates exist yet. Create a Skill/Lore/Tongue template first.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Default Learned Skill", selection: $editedLearnedSkillTemplateID) {
                                Text("Select...").tag(nil as PersistentIdentifier?)
                                ForEach(learnedTemplatesGrouped, id: \.0) { (cat, items) in
                                    Section(cat) {
                                        ForEach(items) { t in
                                            Text(t.name).tag(t.persistentModelID as PersistentIdentifier?)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text("These defaults are used by all non-branched rolls when calculating the goal on any character.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Keywords Preview") {
                    let preview = GoalRollTemplate(
                        name: editedName.trimmingCharacters(in: .whitespacesAndNewlines),
                        templateDescription: editedDescription,
                        baseModifier: editedBaseModifier,
                        userKeywords: editedKeywords,
                        defaultAttributeName: editedAttrName.trimmingCharacters(in: .whitespacesAndNewlines),
                        defaultAttributeCategory: editedAttrCategory,
                        defaultSkillMode: editedSkillMode,
                        defaultNaturalSkillName: editedNaturalSkillName.trimmingCharacters(in: .whitespacesAndNewlines),
                        defaultLearnedSkillTemplate: learnedTemplateByID(editedLearnedSkillTemplateID)
                    )
                    Text(preview.keywordsForRules.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("Edits here affect all non-branched goal rolls using this template.")
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
            .onAppear { loadFromTemplate() }
            .alert("Duplicate Name", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A goal roll template with this name already exists. Choose a different name.")
            }
        }
    }

    private func loadFromTemplate() {
        editedName = template.name
        editedDescription = template.templateDescription
        editedBaseModifier = template.baseModifier
        editedKeywords = template.userKeywords

        editedAttrCategory = template.defaultAttributeCategory
        editedAttrName = template.defaultAttributeName
        editedSkillMode = template.defaultSkillMode
        editedNaturalSkillName = template.defaultNaturalSkillName
        editedLearnedSkillTemplateID = template.defaultLearnedSkillTemplate?.persistentModelID
    }

    private func save() {
        let name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        if let library {
            let dup = library.goalRollTemplates.contains {
                $0.persistentModelID != template.persistentModelID &&
                $0.name.caseInsensitiveCompare(name) == .orderedSame
            }
            if dup {
                showingDuplicateAlert = true
                return
            }
        }

        template.name = name
        template.templateDescription = editedDescription
        template.baseModifier = editedBaseModifier
        template.userKeywords = editedKeywords

        template.defaultAttributeCategory = editedAttrCategory
        template.defaultAttributeName = editedAttrName.trimmingCharacters(in: .whitespacesAndNewlines)
        template.defaultSkillMode = editedSkillMode
        template.defaultNaturalSkillName = editedNaturalSkillName.trimmingCharacters(in: .whitespacesAndNewlines)
        template.defaultLearnedSkillTemplate = learnedTemplateByID(editedLearnedSkillTemplateID)

        dismiss()
    }
}
