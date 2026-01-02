import SwiftUI
import SwiftData

struct CharacterSkillEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var skill: CharacterSkill
    var library: RulesLibrary?
    
    @State private var showingBranchAlert = false
    @State private var showingTemplateEdit = false
    
    @FocusState private var valueFocused: Bool
    
    var body: some View {
        Form {
            Section("Name") {
                if skill.isBranched {
                    TextField("Name", text: $skill.overrideName)
                        .autocorrectionDisabled()
                } else {
                    Button { showingBranchAlert = true } label: {
                        HStack {
                            Text(skill.effectiveName)
                            Spacer()
                            Image(systemName: "pencil").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("Category") {
                Text(skill.effectiveCategory)
                    .foregroundStyle(.secondary)
            }
            
            Section("Value") {
                VStack(spacing: 16) {
                    Text("\(skill.value)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                    
                    TextField("Value", value: $skill.value, format: .number)
                        .keyboardType(.numberPad)
                        .focused($valueFocused)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .onChange(of: skill.value) { _, _ in
                            enforceMinimum()
                        }
                    
                    HStack(spacing: 28) {
                        Button {
                            skill.value -= 1
                            enforceMinimum()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            skill.value += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Description") {
                if skill.isBranched {
                    TextEditor(text: $skill.overrideDescription)
                        .frame(minHeight: 100)
                } else {
                    Button("Edit Description") { showingBranchAlert = true }
                    if !skill.effectiveDescription.isEmpty {
                        Text(skill.effectiveDescription)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Keywords") {
                if skill.isBranched {
                    TextField("Comma-separated", text: $skill.overrideUserKeywords)
                        .autocorrectionDisabled()
                } else {
                    Button("Edit Keywords") { showingBranchAlert = true }
                    if !skill.effectiveUserKeywords.isEmpty {
                        Text(skill.effectiveUserKeywords)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Template Keywords") {
                if let t = skill.template {
                    Text(t.keywordsForRules.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Missing template reference.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Keywords for This Character") {
                Text(skill.keywordsForRules.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if skill.isBranched, let date = skill.branchedDate {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Branched from Library")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        Button("Revert to Library Version", role: .destructive) {
                            revertToLibrary()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .navigationTitle("Edit Skill")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { valueFocused = false }
            }
        }
        .alert("Edit Library Item?", isPresented: $showingBranchAlert) {
            Button("Edit Library") { showingTemplateEdit = true }
            Button("Create Local Override") { createBranch() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This skill template is shared across characters. Edit the library for everyone, or create a local override for this character only?")
        }
        .sheet(isPresented: $showingTemplateEdit) {
            if let template = skill.template {
                SkillTemplateEditView(template: template, library: library)
            } else {
                NavigationStack {
                    Text("Missing template reference.")
                        .foregroundStyle(.secondary)
                        .navigationTitle("Edit Template")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showingTemplateEdit = false }
                            }
                        }
                }
            }
        }
    }
    
    private func enforceMinimum() {
        if skill.value < skill.minimumValue {
            skill.value = skill.minimumValue
        }
    }
    
    private func createBranch() {
        skill.overrideName = skill.effectiveName
        skill.overrideCategory = skill.effectiveCategory
        skill.overrideDescription = skill.effectiveDescription
        skill.overrideUserKeywords = skill.effectiveUserKeywords
        
        skill.isBranched = true
        skill.branchedDate = Date()
    }
    
    private func revertToLibrary() {
        skill.isBranched = false
        skill.branchedDate = nil
        skill.overrideName = ""
        skill.overrideCategory = ""
        skill.overrideDescription = ""
        skill.overrideUserKeywords = ""
    }
}
