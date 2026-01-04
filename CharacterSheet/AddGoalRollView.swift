import SwiftUI
import SwiftData

struct AddGoalRollView: View {
    enum Mode {
        case new
        case fromTemplate(PersistentIdentifier)
    }

    var character: RPGCharacter
    var library: RulesLibrary
    @Binding var isPresented: Bool
    let mode: Mode

    // Shared fields
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var keywords: String = ""
    @State private var baseModifier: Int = 0

    // Formula selection for NEW template defaults
    @State private var selectedAttributeID: PersistentIdentifier?
    @State private var skillMode: GoalRollTemplate.SkillMode = .natural
    @State private var selectedNaturalSkillID: PersistentIdentifier?
    @State private var selectedLearnedTemplateID: PersistentIdentifier?

    // Template mode customization
    @State private var customizeForCharacter: Bool = false
    @State private var customName: String = ""
    @State private var customDescription: String = ""
    @State private var customKeywords: String = ""
    @State private var customBaseModifier: Int = 0

    private var template: GoalRollTemplate? {
        guard case .fromTemplate(let id) = mode else { return nil }
        return library.goalRollTemplates.first(where: { $0.persistentModelID == id })
    }

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

    private var learnedTemplates: [SkillTemplate] {
        let order = ["Learned Skills", "Lores", "Tongues"]
        return order.flatMap { cat in
            library.skillTemplates
                .filter { $0.category == cat }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    private var canAdd: Bool {
        switch mode {
        case .new:
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return false }
            guard selectedAttributeID != nil else { return false }
            if skillMode == .natural { return selectedNaturalSkillID != nil }
            return selectedLearnedTemplateID != nil
        case .fromTemplate:
            return template != nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                switch mode {
                case .new:
                    Section("New Goal Roll") {
                        TextField("Name", text: $name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()

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
                            Text("\(baseModifier)")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }

                    Section("Formula") {
                        Picker("Attribute", selection: $selectedAttributeID) {
                            Text("Select...").tag(nil as PersistentIdentifier?)
                            ForEach(attributes) { a in
                                Text("\(a.category): \(a.name)").tag(a.persistentModelID as PersistentIdentifier?)
                            }
                        }

                        Picker("Skill Type", selection: $skillMode) {
                            ForEach(GoalRollTemplate.SkillMode.allCases, id: \.self) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)

                        if skillMode == .natural {
                            Picker("Natural Skill", selection: $selectedNaturalSkillID) {
                                Text("Select...").tag(nil as PersistentIdentifier?)
                                ForEach(naturalSkills) { s in
                                    Text(s.name).tag(s.persistentModelID as PersistentIdentifier?)
                                }
                            }
                        } else {
                            Picker("Learned Skill Template", selection: $selectedLearnedTemplateID) {
                                Text("Select...").tag(nil as PersistentIdentifier?)
                                ForEach(learnedTemplates) { t in
                                    Text("\(t.category): \(t.name)").tag(t.persistentModelID as PersistentIdentifier?)
                                }
                            }
                        }
                    }

                case .fromTemplate:
                    Section("Template") {
                        if let t = template {
                            Text(t.name).font(.headline)
                            if !t.templateDescription.isEmpty {
                                Text(t.templateDescription)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Missing template.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        Toggle("Customize for this character", isOn: $customizeForCharacter)
                    }

                    if customizeForCharacter {
                        Section("Customization") {
                            TextField("Name (optional)", text: $customName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()

                            TextField("Keywords (comma-separated)", text: $customKeywords)
                                .autocorrectionDisabled()

                            ZStack(alignment: .topLeading) {
                                if customDescription.isEmpty {
                                    Text("Description (optional)...")
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                                TextEditor(text: $customDescription)
                                    .frame(minHeight: 110)
                            }


                            Stepper(value: $customBaseModifier, in: -50...50) {
                                Text("Base Modifier: \(customBaseModifier)")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresented = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                        .disabled(!canAdd)
                }
            }
            .onAppear {
                if let t = template {
                    customName = ""
                    customDescription = ""
                    customKeywords = ""
                    customBaseModifier = t.baseModifier
                } else {
                    // sensible defaults for new
                    if selectedAttributeID == nil { selectedAttributeID = attributes.first?.persistentModelID }
                    if selectedNaturalSkillID == nil { selectedNaturalSkillID = naturalSkills.first?.persistentModelID }
                }
            }
            .onChange(of: skillMode) { _, newValue in
                if newValue == .natural {
                    selectedLearnedTemplateID = nil
                } else {
                    selectedNaturalSkillID = nil
                }
            }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .new: return "New Goal Roll"
        case .fromTemplate: return "Add Goal Roll"
        }
    }

    private func add() {
        switch mode {
        case .new:
            guard let attrID = selectedAttributeID,
                  let attr = character.stats.first(where: { $0.persistentModelID == attrID })
            else { return }

            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { return }

            let template = GoalRollTemplate(
                name: trimmedName,
                templateDescription: description,
                baseModifier: baseModifier,
                userKeywords: keywords
            )

            // Template defaults from current selections
            template.defaultAttributeCategory = attr.category
            template.defaultAttributeName = attr.name

            template.defaultSkillMode = skillMode
            if skillMode == .natural {
                guard let nsID = selectedNaturalSkillID,
                      let s = character.stats.first(where: { $0.persistentModelID == nsID })
                else { return }
                template.defaultNaturalSkillName = s.name
                template.defaultLearnedSkillTemplate = nil
            } else {
                guard let ltID = selectedLearnedTemplateID,
                      let learned = library.skillTemplates.first(where: { $0.persistentModelID == ltID })
                else { return }
                template.defaultNaturalSkillName = ""
                template.defaultLearnedSkillTemplate = learned
            }

            library.goalRollTemplates.append(template)
            let roll = CharacterGoalRoll(template: template)
            character.goalRolls.append(roll)
            isPresented = false

        case .fromTemplate:
            guard let t = template else { return }

            let roll = CharacterGoalRoll(template: t)

            if customizeForCharacter {
                let n = customName.trimmingCharacters(in: .whitespacesAndNewlines)
                let d = customDescription
                let k = customKeywords

                let hasAny =
                    !n.isEmpty ||
                    !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    !k.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    customBaseModifier != t.baseModifier

                if hasAny {
                    roll.isBranched = true
                    roll.branchedDate = Date()
                    roll.overrideName = n.isEmpty ? t.name : n
                    roll.overrideDescription = d.isEmpty ? t.templateDescription : d
                    roll.overrideUserKeywords = k.isEmpty ? t.userKeywords : k
                    roll.overrideBaseModifier = customBaseModifier
                }
            }

            character.goalRolls.append(roll)
            isPresented = false
        }
    }
}
