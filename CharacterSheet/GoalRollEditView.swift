import SwiftUI
import SwiftData

struct GoalRollEditView: View {
    @Bindable var roll: CharacterGoalRoll
    var library: RulesLibrary?
    
    @State private var showingBranchAlert = false
    @State private var showingTemplateEdit = false
    
    @State private var skillMode: SkillMode = .natural
    
    enum SkillMode: String, CaseIterable {
        case natural = "Natural Skill"
        case learned = "Learned/Lore/Tongue"
    }
    
    private var character: RPGCharacter? { roll.character }
    
    private let attributeCategoryOrder = ["Body", "Mind", "Spirit", "Occult"]
    
    private var attributesOrdered: [Stat] {
        guard let character else { return [] }
        let attrs = character.stats.filter { $0.statType == "attribute" }
        return attrs.sorted {
            let aIdx = attributeCategoryOrder.firstIndex(of: $0.category) ?? 999
            let bIdx = attributeCategoryOrder.firstIndex(of: $1.category) ?? 999
            if aIdx != bIdx { return aIdx < bIdx }
            if $0.displayOrder != $1.displayOrder { return $0.displayOrder < $1.displayOrder }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
    
    private var naturalSkillsOrdered: [Stat] {
        character?.stats
            .filter { $0.statType == "skill" && $0.category == "Natural Skills" }
            .sorted { $0.displayOrder < $1.displayOrder } ?? []
    }
    
    private var learnedSkillsOrdered: [CharacterSkill] {
        character?.learnedSkills
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending } ?? []
    }
    
    var body: some View {
        Form {
            Section("Name") {
                if roll.isBranched {
                    TextField("Name", text: $roll.overrideName)
                        .autocorrectionDisabled()
                } else {
                    Button { showingBranchAlert = true } label: {
                        HStack {
                            Text(roll.effectiveName)
                            Spacer()
                            Image(systemName: "pencil").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("Formula") {
                if roll.isBranched {
                    Picker("Attribute", selection: $roll.attributeStat) {
                        Text("Select...").tag(nil as Stat?)
                        ForEach(attributesOrdered) { a in
                            Text("\(a.category): \(a.name)").tag(a as Stat?)
                        }
                    }
                    
                    Picker("Skill Type", selection: $skillMode) {
                        ForEach(SkillMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if skillMode == .natural {
                        Picker("Natural Skill", selection: $roll.naturalSkillStat) {
                            Text("Select...").tag(nil as Stat?)
                            ForEach(naturalSkillsOrdered) { s in
                                Text(s.name).tag(s as Stat?)
                            }
                        }
                    } else {
                        Picker("Learned Skill", selection: $roll.characterSkill) {
                            Text("Select...").tag(nil as CharacterSkill?)
                            ForEach(learnedSkillsOrdered) { s in
                                Text("\(s.effectiveName) (\(s.effectiveCategory))").tag(s as CharacterSkill?)
                            }
                        }
                    }
                } else {
                    Button { showingBranchAlert = true } label: {
                        HStack {
                            Text("Attribute")
                            Spacer()
                            if let a = roll.effectiveAttributeStat {
                                Text("\(a.category): \(a.name)")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Missing").foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Button { showingBranchAlert = true } label: {
                        HStack {
                            Text("Skill")
                            Spacer()
                            if roll.effectiveSkillMode == .natural {
                                Text(roll.effectiveNaturalSkillStat?.name ?? "Missing")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(roll.effectiveCharacterSkill?.effectiveName ?? "Missing")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Text("To change the formula, edit the library template defaults or create a local override.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Calculated Goal") {
                VStack(spacing: 10) {
                    HStack {
                        Text("Goal")
                        Spacer()
                        Text("\(roll.goalValue)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                    }
                    
                    if let a = roll.effectiveAttributeStat {
                        HStack {
                            Text(a.name)
                            Spacer()
                            Text("\(a.value)")
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    if let sName = roll.skillName {
                        HStack {
                            Text(sName)
                            Spacer()
                            if roll.effectiveSkillMode == .natural {
                                Text("\(roll.effectiveNaturalSkillStat?.value ?? 0)")
                            } else {
                                Text("\(roll.effectiveCharacterSkill?.value ?? 0)")
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    if roll.effectiveBaseModifier != 0 {
                        HStack {
                            Text("Base Modifier")
                            Spacer()
                            Text("\(roll.effectiveBaseModifier >= 0 ? "+" : "")\(roll.effectiveBaseModifier)")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
            
            Section("Base Modifier") {
                if roll.isBranched {
                    HStack {
                        Button { roll.overrideBaseModifier -= 1 } label: {
                            Image(systemName: "minus.circle.fill").font(.title2)
                        }
                        .buttonStyle(.borderless)
                        
                        Spacer()
                        
                        Text("\(roll.overrideBaseModifier)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button { roll.overrideBaseModifier += 1 } label: {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                        .buttonStyle(.borderless)
                    }
                } else {
                    Button("Edit Base Modifier") { showingBranchAlert = true }
                    Text("Current: \(roll.effectiveBaseModifier)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Description") {
                if roll.isBranched {
                    TextEditor(text: $roll.overrideDescription)
                        .frame(minHeight: 100)
                } else {
                    Button("Edit Description") { showingBranchAlert = true }
                    if !roll.effectiveDescription.isEmpty {
                        Text(roll.effectiveDescription)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Keywords") {
                if roll.isBranched {
                    TextField("Comma-separated", text: $roll.overrideUserKeywords)
                        .autocorrectionDisabled()
                } else {
                    Button("Edit Keywords") { showingBranchAlert = true }
                    if !roll.effectiveUserKeywords.isEmpty {
                        Text(roll.effectiveUserKeywords)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Template Implicit Keywords") {
                Text(roll.template?.implicitKeywords.joined(separator: ", ") ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if roll.isBranched, let date = roll.branchedDate {
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
        .navigationTitle("Edit Goal Roll")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncSkillModeFromEffective()
        }
        .onChange(of: skillMode) { _, newValue in
            guard roll.isBranched else { return }
            if newValue == .natural {
                roll.characterSkill = nil
            } else {
                roll.naturalSkillStat = nil
            }
        }
        .alert("Edit Library Item?", isPresented: $showingBranchAlert) {
            Button("Edit Library") { showingTemplateEdit = true }
            Button("Create Local Override") { createBranch() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This goal roll is shared across characters. Edit the library for everyone, or create a local override for this character only?")
        }
        .sheet(isPresented: $showingTemplateEdit) {
            if let template = roll.template {
                GoalRollTemplateEditView(template: template, library: library)
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
    
    private func syncSkillModeFromEffective() {
        let eff = roll.effectiveSkillMode
        skillMode = (eff == .learned) ? .learned : .natural
    }
    
    private func createBranch() {
        roll.overrideName = roll.effectiveName
        roll.overrideDescription = roll.effectiveDescription
        roll.overrideBaseModifier = roll.effectiveBaseModifier
        roll.overrideUserKeywords = roll.effectiveUserKeywords
        
        roll.attributeStat = roll.effectiveAttributeStat
        
        if roll.effectiveSkillMode == .natural {
            roll.naturalSkillStat = roll.effectiveNaturalSkillStat
            roll.characterSkill = nil
            skillMode = .natural
        } else {
            roll.characterSkill = roll.effectiveCharacterSkill
            roll.naturalSkillStat = nil
            skillMode = .learned
        }
        
        roll.isBranched = true
        roll.branchedDate = Date()
    }
    
    private func revertToLibrary() {
        roll.isBranched = false
        roll.branchedDate = nil
        
        roll.overrideName = ""
        roll.overrideDescription = ""
        roll.overrideBaseModifier = 0
        roll.overrideUserKeywords = ""
        
        roll.attributeStat = nil
        roll.naturalSkillStat = nil
        roll.characterSkill = nil
        
        syncSkillModeFromEffective()
    }
}

