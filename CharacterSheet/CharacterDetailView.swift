import SwiftUI
import SwiftData

struct CharacterDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var character: RPGCharacter
    var library: RulesLibrary?

    // Sheet presentation
    @State private var showingAddSkill = false
    @State private var showingAddGoalRoll = false

    // Required display order
    private let attributeCategoryOrder = ["Body", "Mind", "Spirit", "Occult"]

    private var attributesOrdered: [Stat] {
        let attrs = character.stats.filter { KeywordUtil.normalize($0.statType) == "attribute" }
        return attrs.sorted {
            let aIdx = attributeCategoryOrder.firstIndex(of: $0.category) ?? 999
            let bIdx = attributeCategoryOrder.firstIndex(of: $1.category) ?? 999
            if aIdx != bIdx { return aIdx < bIdx }
            if $0.displayOrder != $1.displayOrder { return $0.displayOrder < $1.displayOrder }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var naturalSkillsOrdered: [Stat] {
        character.stats
            .filter {
                KeywordUtil.normalize($0.statType) == "skill" &&
                $0.category == "Natural Skills"
            }
            .sorted {
                if $0.displayOrder != $1.displayOrder { return $0.displayOrder < $1.displayOrder }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private var learnedSkillsOrdered: [CharacterSkill] {
        character.learnedSkills
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var goalRollsOrdered: [CharacterGoalRoll] {
        character.goalRolls
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    var body: some View {
        Form {
            Section("Character") {
                TextField("Name", text: $character.name)
                TextEditor(text: $character.characterDescription)
                    .frame(minHeight: 80)
            }

            Section("Attributes") {
                if attributesOrdered.isEmpty {
                    Text("No attributes yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(attributesOrdered) { stat in
                        NavigationLink {
                            StatEditView(stat: stat)   // ✅ FIX: stat:, not character:
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stat.name)
                                    Text(stat.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(stat.value)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Natural Skills") {
                if naturalSkillsOrdered.isEmpty {
                    Text("No natural skills yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(naturalSkillsOrdered) { stat in
                        NavigationLink {
                            StatEditView(stat: stat)   // ✅ FIX: stat:
                        } label: {
                            HStack {
                                Text(stat.name)
                                Spacer()
                                Text("\(stat.value)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Learned Skills / Lores / Tongues") {
                if learnedSkillsOrdered.isEmpty {
                    Text("No learned skills yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(learnedSkillsOrdered) { skill in
                        NavigationLink {
                            CharacterSkillEditView(skill: skill, library: library)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(skill.effectiveName)
                                    Text(skill.effectiveCategory)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(skill.value)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button {
                    showingAddSkill = true
                } label: {
                    Label("Add Learned Skill", systemImage: "plus")
                }
            }

            Section("Goal Rolls") {
                if goalRollsOrdered.isEmpty {
                    Text("No goal rolls yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(goalRollsOrdered) { roll in
                        NavigationLink {
                            GoalRollEditView(roll: roll, library: library)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(roll.effectiveName)
                                Text("Goal: \(roll.goalValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button {
                    showingAddGoalRoll = true
                } label: {
                    Label("Add Goal Roll", systemImage: "plus")
                }
            }
        }
        .navigationTitle(character.name.isEmpty ? "Character" : character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showingAddSkill) {
            AddCharacterSkillView(
                character: character,
                library: library,
                isPresented: $showingAddSkill
            )
        }
        .sheet(isPresented: $showingAddGoalRoll) {
            AddGoalRollView(
                character: character,
                library: library,
                isPresented: $showingAddGoalRoll
            )
        }
    }
}
