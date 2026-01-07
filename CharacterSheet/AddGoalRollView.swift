import SwiftUI
import SwiftData

struct AddGoalRollView: View {
    @Environment(\.modelContext) private var modelContext

    var character: RPGCharacter
    @Binding var isPresented: Bool
    var category: GoalRollCategory?

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var keywords: String = ""
    @State private var baseModifier: Int = 0

    @State private var selectedAttributeID: PersistentIdentifier?
    @State private var selectedNaturalSkillID: PersistentIdentifier?
    @State private var selectedLearnedSkillID: PersistentIdentifier?

    private var attributes: [Stat] {
        character.stats
            .filter { $0.statType == "attribute" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private var naturalSkills: [Stat] {
        character.stats
            .filter { $0.statType == "skill" && $0.category == "Natural Skills" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private var learnedSkills: [CharacterSkill] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Learned Skills" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var loreSkills: [CharacterSkill] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Lores" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var canAdd: Bool {
        // Name can be empty now - it will be auto-generated
        guard selectedAttributeID != nil else { return false }
        return selectedNaturalSkillID != nil || selectedLearnedSkillID != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("New Goal Roll") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Name", text: $name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                        if name.isEmpty {
                            HStack(spacing: 0) {
                                Text("Leave blank for ")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("Attribute")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .italic()
                                Text(" + ")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("Skill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .italic()
                            }
                        }
                    }

                    TextField("Keywords (comma-separated)", text: $keywords)
                        .autocorrectionDisabled()

                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description (optional)...")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 110)
                    }
                }

                Section("Base Modifier") {
                    Stepper(value: $baseModifier, in: -50...50) {
                        HStack {
                            Text("Modifier")
                            Spacer()
                            Text("\(baseModifier >= 0 ? "+" : "")\(baseModifier)")
                                .fontWeight(.semibold)
                        }
                    }
                }

                Section("Formula") {
                    Picker("Attribute", selection: $selectedAttributeID) {
                        Text("Select...").tag(nil as PersistentIdentifier?)
                        ForEach(attributes) { attr in
                            Text(attr.name).tag(attr.persistentModelID as PersistentIdentifier?)
                        }
                    }

                    // Skill Picker with sections
                    Picker("Skill", selection: Binding(
                        get: {
                            if let natID = selectedNaturalSkillID {
                                return "nat_\(natID.hashValue)"
                            } else if let learnedID = selectedLearnedSkillID {
                                return "learned_\(learnedID.hashValue)"
                            }
                            return ""
                        },
                        set: { newValue in
                            if newValue.starts(with: "nat_") {
                                // Find the natural skill
                                if let skill = naturalSkills.first(where: { "nat_\($0.persistentModelID.hashValue)" == newValue }) {
                                    selectedNaturalSkillID = skill.persistentModelID
                                    selectedLearnedSkillID = nil
                                }
                            } else if newValue.starts(with: "learned_") {
                                // Find the learned/lore skill
                                let allLearnedAndLore = learnedSkills + loreSkills
                                if let skill = allLearnedAndLore.first(where: { "learned_\($0.persistentModelID.hashValue)" == newValue }) {
                                    selectedLearnedSkillID = skill.persistentModelID
                                    selectedNaturalSkillID = nil
                                }
                            }
                        }
                    )) {
                        Text("Select...").tag("")

                        if !naturalSkills.isEmpty {
                            Section(header: Text("Natural Skills")) {
                                ForEach(naturalSkills) { skill in
                                    Text(skill.name).tag("nat_\(skill.persistentModelID.hashValue)")
                                }
                            }
                        }

                        if !learnedSkills.isEmpty {
                            Section(header: Text("Learned Skills")) {
                                ForEach(learnedSkills) { skill in
                                    Text(skill.effectiveName).tag("learned_\(skill.persistentModelID.hashValue)")
                                }
                            }
                        }

                        if !loreSkills.isEmpty {
                            Section(header: Text("Lore Skills")) {
                                ForEach(loreSkills) { skill in
                                    Text(skill.effectiveName).tag("learned_\(skill.persistentModelID.hashValue)")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Goal Roll")
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
        }
    }

    private func add() {
        let attr = attributes.first(where: { $0.persistentModelID == selectedAttributeID })
        let natSkill = naturalSkills.first(where: { $0.persistentModelID == selectedNaturalSkillID })
        let learnedSkill = (learnedSkills + loreSkills).first(where: { $0.persistentModelID == selectedLearnedSkillID })

        // Auto-generate name if empty
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName: String
        if trimmed.isEmpty {
            // Generate name from Attribute + Skill
            let attrName = attr?.name ?? "Unknown"
            let skillName = natSkill?.name ?? learnedSkill?.effectiveName ?? "Unknown"
            finalName = "\(attrName) + \(skillName)"
        } else {
            finalName = trimmed
        }

        // Calculate next displayOrder
        let existingRollsInCategory = character.goalRolls.filter { $0.category?.persistentModelID == category?.persistentModelID }
        let maxOrder = existingRollsInCategory.map { $0.displayOrder }.max() ?? -1

        let roll = CharacterGoalRoll(
            name: finalName,
            description: description,
            keywords: keywords,
            baseModifier: baseModifier,
            attributeStat: attr,
            naturalSkillStat: natSkill,
            characterSkill: learnedSkill
        )
        roll.category = category
        roll.displayOrder = maxOrder + 1
        character.goalRolls.append(roll)

        // Insert into model context to ensure proper persistence
        modelContext.insert(roll)

        isPresented = false
    }
}
