import SwiftUI
import SwiftData

struct CharacterSkillEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var skill: CharacterSkill
    var library: RulesLibrary?

    @State private var showingBranchAlert = false
    @State private var showingTemplateEdit = false
    @State private var showingDeleteAlert = false

    var body: some View {
        Form {
            Section("Name") {
                if skill.isBranched {
                    TextField("Name", text: $skill.overrideName)
                        .autocorrectionDisabled()
                } else {
                    HStack {
                        Text(skill.effectiveName)
                        Spacer()
                        Button {
                            showingBranchAlert = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Category") {
                Text(skill.effectiveCategory)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("Base Value")
                    Spacer()
                    Text("\(skill.value)")
                        .font(.headline)
                }

                // Show effective value and modifiers breakdown here
                // TODO: Add modifier calculation and display
                HStack {
                    Text("Effective Value")
                    Spacer()
                    Text("\(skill.value)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("All Keywords") {
                Text(skill.keywordsForRules.joined(separator: ", "))
                    .font(.callout)
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

            Section {
                Button("Delete Skill from Character", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
        }
        .navigationTitle("Skill Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Edit Library Item?", isPresented: $showingBranchAlert) {
            Button("Edit Library") { showingTemplateEdit = true }
            Button("Create Local Override") { createBranch() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This skill template is shared across characters. Edit the library for everyone, or create a local override for this character only?")
        }
        .alert("Delete Skill?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { deleteSkill() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove \"\(skill.effectiveName)\" from this character. The template will remain in your library.")
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

    private func createBranch() {
        skill.overrideName = skill.effectiveName
        skill.overrideCategory = skill.effectiveCategory
        skill.overrideDescription = ""
        skill.overrideUserKeywords = ""

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

    private func deleteSkill() {
        modelContext.delete(skill)
        dismiss()
    }
}

