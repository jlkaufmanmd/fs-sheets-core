import SwiftUI
import SwiftData

struct GoalRollEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var roll: CharacterGoalRoll
    
    @State private var showingDeleteAlert = false
    
    private var character: RPGCharacter? { roll.character }
    
    private var attributes: [Stat] {
        character?.stats
            .filter { $0.statType == "attribute" }
            .sorted { $0.displayOrder < $1.displayOrder } ?? []
    }
    
    private var naturalSkills: [Stat] {
        character?.stats
            .filter { $0.statType == "skill" && $0.category == "Natural Skills" }
            .sorted { $0.displayOrder < $1.displayOrder } ?? []
    }
    
    private var learnedSkills: [CharacterSkill] {
        character?.learnedSkills
            .filter { $0.effectiveCategory == "Learned Skills" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending } ?? []
    }
    
    private var loreSkills: [CharacterSkill] {
        character?.learnedSkills
            .filter { $0.effectiveCategory == "Lores" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending } ?? []
    }
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $roll.name)
                    .textInputAutocapitalization(.words)
                
                TextField("Keywords (comma-separated)", text: $roll.userKeywords)
                    .autocorrectionDisabled()
                
                ZStack(alignment: .topLeading) {
                    if roll.rollDescription.isEmpty {
                        Text("Description (optional)...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $roll.rollDescription)
                        .frame(minHeight: 110)
                }
            }
            
            Section("Base Modifier") {
                Stepper(value: $roll.baseModifier, in: -50...50) {
                    HStack {
                        Text("Modifier")
                        Spacer()
                        Text("\(roll.baseModifier >= 0 ? "+" : "")\(roll.baseModifier)")
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Section("Formula") {
                Picker("Attribute", selection: $roll.attributeStat) {
                    Text("Select...").tag(nil as Stat?)
                    ForEach(attributes) { attr in
                        Text(attr.name).tag(attr as Stat?)
                    }
                }
                
                // Skill Picker with sections
                Picker("Skill", selection: Binding(
                    get: {
                        if let natSkill = roll.naturalSkillStat {
                            return "nat_\(natSkill.persistentModelID.hashValue)"
                        } else if let learnedSkill = roll.characterSkill {
                            return "learned_\(learnedSkill.persistentModelID.hashValue)"
                        }
                        return ""
                    },
                    set: { newValue in
                        if newValue.starts(with: "nat_") {
                            if let skill = naturalSkills.first(where: { "nat_\($0.persistentModelID.hashValue)" == newValue }) {
                                roll.naturalSkillStat = skill
                                roll.characterSkill = nil
                            }
                        } else if newValue.starts(with: "learned_") {
                            let allLearnedAndLore = learnedSkills + loreSkills
                            if let skill = allLearnedAndLore.first(where: { "learned_\($0.persistentModelID.hashValue)" == newValue }) {
                                roll.characterSkill = skill
                                roll.naturalSkillStat = nil
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
            
            Section {
                HStack {
                    Text("Goal Value")
                    Spacer()
                    Text("\(roll.goalValue)")
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
            }
            
            Section {
                Button("Delete Goal Roll", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
        }
        .navigationTitle("Edit Goal Roll")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Goal Roll?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { deleteGoalRoll() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove \"\(roll.name)\" from this character.")
        }
    }
    
    private func deleteGoalRoll() {
        modelContext.delete(roll)
        dismiss()
    }
}
