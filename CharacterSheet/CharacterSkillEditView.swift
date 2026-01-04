import SwiftUI
import SwiftData

struct CharacterSkillEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var skill: CharacterSkill

    @State private var showingDeleteAlert = false

    var body: some View {
        Form {
            Section("Name") {
                Text(skill.effectiveName)
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

            Section {
                Button("Delete Skill from Character", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
        }
        .navigationTitle("Skill Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Skill?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { deleteSkill() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove \"\(skill.effectiveName)\" from this character. The template will remain in your library.")
        }
    }

    private func deleteSkill() {
        modelContext.delete(skill)
        dismiss()
    }
}
