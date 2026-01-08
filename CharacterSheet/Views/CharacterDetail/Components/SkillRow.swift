import SwiftUI
import SwiftData

/// A reusable row for displaying and editing a CharacterSkill (learned skills, lores, tongues)
struct SkillRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var skill: CharacterSkill
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 4) {
            // The skill row itself
            HStack(spacing: 4) {
                Text(skill.effectiveName)
                    .font(.caption)
                    .lineLimit(1)
                    .onTapGesture {
                        isExpanded.toggle()
                    }
                Spacer()

                valueControls
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(isExpanded ? Color(.systemGray6) : Color.clear)
            .cornerRadius(6)
            .contextMenu {
                Button(role: .destructive) {
                    modelContext.delete(skill)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            // Details appear directly below this skill
            if isExpanded {
                detailsView
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Components

    private var valueControls: some View {
        HStack(spacing: 3) {
            Button {
                skill.value -= 1
                if skill.value < skill.minimumValue { skill.value = skill.minimumValue }
            } label: {
                Image(systemName: "minus.circle")
                    .font(.caption2)
            }
            .buttonStyle(.plain)

            Text("\(skill.value)")
                .font(.caption)
                .fontWeight(.semibold)
                .frame(minWidth: 20)

            Button {
                skill.value += 1
            } label: {
                Image(systemName: "plus.circle")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
    }

    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Base")
                    .font(.caption2)
                Spacer()
                Text("\(skill.value)")
                    .font(.caption2)
                    .fontWeight(.bold)
            }

            // Future: Effective value if modifiers exist

            Divider()

            VStack(alignment: .leading, spacing: 2) {
                Text("Keywords")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(skill.keywordsForRules.joined(separator: ", "))
                    .font(.caption2)
                    .lineLimit(nil)
            }
        }
        .padding(6)
        .background(Color(.systemGray6))
        .cornerRadius(4)
    }
}
