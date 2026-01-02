import SwiftUI
import SwiftData

struct AddCharacterSkillView: View {
    var character: RPGCharacter
    var library: RulesLibrary?
    @Binding var isPresented: Bool
    
    private let categories = ["Learned Skills", "Lores", "Tongues"]
    
    @State private var selectedCategory: String = "Learned Skills"
    
    // Template selection uses IDs (CloudKit/SwiftData friendly + avoids hashing issues)
    @State private var selectedTemplateID: PersistentIdentifier?
    
    // New template path
    @State private var customName: String = ""
    
    @State private var showingTemplatePicker = false
    
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
    
    private var canAdd: Bool {
        let hasPickedTemplate = templateByID(selectedTemplateID) != nil
        let hasCustom = !customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasPickedTemplate || hasCustom
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
                        // Reset selection when category changes
                        selectedTemplateID = nil
                    }
                }
                
                Section("From Library") {
                    Button {
                        showingTemplatePicker = true
                    } label: {
                        HStack {
                            Text("Template")
                            Spacer()
                            if let t = templateByID(selectedTemplateID) {
                                Text(t.name).foregroundStyle(.secondary)
                            } else {
                                Text("Choose…").foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .disabled(library == nil || templatesForSelectedCategory.isEmpty)
                    
                    if library == nil {
                        Text("Rules library not available yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if templatesForSelectedCategory.isEmpty {
                        Text("No templates in this category yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Or Create New Template") {
                    TextField("New skill name", text: $customName)
                        .autocorrectionDisabled()
                }
                
                Section {
                    Text("Adding from library keeps the shared template. You can branch later per character if needed.")
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
            .sheet(isPresented: $showingTemplatePicker) {
                SearchableTemplatePickerSheet(
                    title: "Choose Template",
                    prompt: "Search templates",
                    items: templatesForSelectedCategory,
                    name: { $0.name },
                    subtitle: { $0.templateDescription }
                ) { picked in
                    selectedTemplateID = picked.persistentModelID
                    // If they pick a template, we leave customName alone (in case they were drafting).
                    // Add() logic prefers template if selected.
                }
            }
        }
    }
    
    private func addSkill() {
        guard let library else { return }
        
        if let picked = templateByID(selectedTemplateID) {
            // Prevent duplicate template instance on this character
            if character.learnedSkills.contains(where: { $0.template?.persistentModelID == picked.persistentModelID }) {
                isPresented = false
                return
            }
            let newSkill = CharacterSkill(template: picked, value: 0)
            character.learnedSkills.append(newSkill)
            isPresented = false
            return
        }
        
        let name = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        // If template exists already in that category, reuse it.
        if let existing = library.skillTemplates.first(where: {
            $0.category == selectedCategory &&
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            if !character.learnedSkills.contains(where: { $0.template?.persistentModelID == existing.persistentModelID }) {
                character.learnedSkills.append(CharacterSkill(template: existing, value: 0))
            }
            isPresented = false
            return
        }
        
        let template = SkillTemplate(name: name, category: selectedCategory)
        library.skillTemplates.append(template)
        character.learnedSkills.append(CharacterSkill(template: template, value: 0))
        isPresented = false
    }
}

