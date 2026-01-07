import SwiftUI
import SwiftData

struct CharacterDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var character: RPGCharacter

    @Query(sort: \RulesLibrary.createdDate) private var libraries: [RulesLibrary]
    @Query(sort: \RPGCharacter.name) private var allCharacters: [RPGCharacter]
    private var library: RulesLibrary? { libraries.first }

    // Quick add state
    @State private var showingAddRollNew = false
    @State private var selectedSkillCategory: String = "Learned Skills"
    @State private var showingQuickAddSkill = false
    @State private var quickAddSkillName: String = ""
    @State private var showingAddInitiative = false
    @State private var initiativeSubcategory: String = "Physical"

    // Goal Roll category management
    @State private var showingGoalRollCategoryPicker = false
    @State private var showingNewGoalRollCategory = false
    @State private var newGoalRollCategoryName = ""
    @State private var selectedCategoryForNewRoll: GoalRollCategory?
    @State private var showingCategorySettings: GoalRollCategory?
    @State private var showingRenameCategoryAlert = false
    @State private var renameCategoryName = ""
    @State private var showingDeleteCategoryAlert = false
    @State private var categoryToDelete: GoalRollCategory?
    @State private var deleteCategoryAction: DeleteCategoryAction = .deleteRolls
    @State private var migrationTargetCategory: GoalRollCategory?
    @State private var showingMigrationPicker = false

    // Inline value editing focus (tap number to type)
    @FocusState private var focusedStatID: PersistentIdentifier?
    @FocusState private var focusedSkillID: PersistentIdentifier?
    @FocusState private var isNameFieldFocused: Bool

    // Name validation
    @State private var showingDuplicateNameAlert = false
    @State private var previousValidName: String = ""

    enum DeleteCategoryAction {
        case deleteRolls
        case migrateRolls
    }

    private var attributes: [Stat] {
        character.stats
            .filter { $0.statType == "attribute" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private var attributesByCategory: [(String, [Stat])] {
        let categories = ["Body", "Mind", "Spirit", "Occult"]
        return categories.compactMap { category in
            let stats = attributes.filter { $0.category == category }
            return stats.isEmpty ? nil : (category, stats)
        }
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

    private var lores: [CharacterSkill] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Lores" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var tongues: [CharacterSkill] {
        character.learnedSkills
            .filter { $0.effectiveCategory == "Tongues" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var goalRolls: [CharacterGoalRoll] {
        character.goalRolls.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var physicalCombatMetrics: [CharacterCombatMetric] {
        character.combatMetrics
            .filter { $0.effectiveSubcategory == "Physical" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    private var occultCombatMetrics: [CharacterCombatMetric] {
        character.combatMetrics
            .filter { $0.effectiveSubcategory == "Occult" }
            .sorted { $0.effectiveName.localizedCaseInsensitiveCompare($1.effectiveName) == .orderedAscending }
    }

    // Filter templates to exclude ones character already has
    private var availableSkillTemplates: [SkillTemplate] {
        guard let library else { return [] }
        let existingTemplateIDs = Set(character.learnedSkills.compactMap { $0.template?.persistentModelID })
        return library.skillTemplates.filter { !existingTemplateIDs.contains($0.persistentModelID) }
    }


    private var availableCombatMetricTemplates: [CombatMetricTemplate] {
        guard let library else { return [] }
        let existingTemplateIDs = Set(character.combatMetrics.compactMap { $0.template?.persistentModelID })
        return library.combatMetricTemplates.filter { !existingTemplateIDs.contains($0.persistentModelID) && !$0.isInitiative }
    }

    private var physicalCombatMetricTemplates: [CombatMetricTemplate] {
        availableCombatMetricTemplates.filter { $0.subcategory == "Physical" }
    }

    private var occultCombatMetricTemplates: [CombatMetricTemplate] {
        availableCombatMetricTemplates.filter { $0.subcategory == "Occult" }
    }

    // Skills available for initiative creation (no existing initiative)
    private var skillsWithoutInitiative: [String] {
        let existingInitiativeSkills = Set(character.combatMetrics
            .compactMap { $0.template }
            .filter { $0.isInitiative }
            .map { $0.associatedSkillName })

        var allSkills: [String] = []
        allSkills.append(contentsOf: character.stats.filter { $0.statType == "skill" }.map { $0.name })
        allSkills.append(contentsOf: character.learnedSkills.map { $0.effectiveName })

        return allSkills.filter { !existingInitiativeSkills.contains($0) }.sorted()
    }

    // Category-specific template filters
    private var learnedSkillTemplates: [SkillTemplate] {
        availableSkillTemplates.filter { $0.category == "Learned Skills" }
    }

    private var loreTemplates: [SkillTemplate] {
        availableSkillTemplates.filter { $0.category == "Lores" }
    }

    private var tongueTemplates: [SkillTemplate] {
        availableSkillTemplates.filter { $0.category == "Tongues" }
    }

    // Goal Roll Categories
    private var goalRollCategories: [GoalRollCategory] {
        character.goalRollCategories.sorted { $0.displayOrder < $1.displayOrder }
    }

    private func goalRollsForCategory(_ category: GoalRollCategory) -> [CharacterGoalRoll] {
        character.goalRolls
            .filter { $0.category?.persistentModelID == category.persistentModelID }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private var canDeleteCategory: Bool {
        character.goalRollCategories.count > 1
    }

    // Display name for quick-add alert
    private var alertSkillTypeLabel: String {
        switch selectedSkillCategory {
        case "Learned Skills": return "Learned Skill"
        case "Lores": return "Lore Skill"
        case "Tongues": return "Tongue"
        default: return "Skill"
        }
    }

    var body: some View {
        Form {
            Section("Character") {
                TextField("Name", text: $character.name)
                    .font(.headline)
                    .focused($isNameFieldFocused)
                    .onSubmit {
                        validateName()
                    }
                    .onChange(of: isNameFieldFocused) { _, isFocused in
                        if !isFocused {
                            validateName()
                        }
                    }
                
                ZStack(alignment: .topLeading) {
                    if character.characterDescription.isEmpty {
                        Text("Description (optional)...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $character.characterDescription)
                        .frame(minHeight: 80)
                }
            }

            Section {
                Text("ATTRIBUTES")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color(.systemGray6))
            }

            ForEach(attributesByCategory, id: \.0) { (category, stats) in
                Section {
                    ForEach(stats) { stat in
                        statDisclosureRow(stat)
                    }
                } header: {
                    HStack {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
                    .textCase(nil)
                }
            }

            Section {
                Text("SKILLS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color(.systemGray6))
            }

            Section {
                ForEach(naturalSkills) { stat in
                    statDisclosureRow(stat)
                }
            } header: {
                HStack {
                    Text("Natural Skills")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                .textCase(nil)
            }

            Section {
                if learnedSkills.isEmpty {
                    Text("No learned skills yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(learnedSkills) { skill in
                        skillDisclosureRow(skill)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(skill)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            modelContext.delete(learnedSkills[index])
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Learned Skills")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()

                    // Category-aware add button
                    if !learnedSkillTemplates.isEmpty {
                        Menu {
                            Button("New…") {
                                selectedSkillCategory = "Learned Skills"
                                showingQuickAddSkill = true
                            }

                            Divider()

                            ForEach(learnedSkillTemplates) { template in
                                Button(template.name) {
                                    let newSkill = CharacterSkill(template: template, value: 1)
                                    character.learnedSkills.append(newSkill)
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Button {
                            selectedSkillCategory = "Learned Skills"
                            showingQuickAddSkill = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                .textCase(nil)
            }

            Section {
                if lores.isEmpty {
                    Text("No lore skills yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(lores) { skill in
                        skillDisclosureRow(skill)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(skill)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            modelContext.delete(lores[index])
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Lore Skills")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()

                    // Category-aware add button
                    if !loreTemplates.isEmpty {
                        Menu {
                            Button("New…") {
                                selectedSkillCategory = "Lores"
                                showingQuickAddSkill = true
                            }

                            Divider()

                            ForEach(loreTemplates) { template in
                                Button(template.name) {
                                    let newSkill = CharacterSkill(template: template, value: 1)
                                    character.learnedSkills.append(newSkill)
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Button {
                            selectedSkillCategory = "Lores"
                            showingQuickAddSkill = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                .textCase(nil)
            }

            Section {
                if tongues.isEmpty {
                    Text("No tongues yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(tongues) { skill in
                        skillDisclosureRow(skill)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(skill)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            modelContext.delete(tongues[index])
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Tongues")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()

                    // Category-aware add button
                    if !tongueTemplates.isEmpty {
                        Menu {
                            Button("New…") {
                                selectedSkillCategory = "Tongues"
                                showingQuickAddSkill = true
                            }

                            Divider()

                            ForEach(tongueTemplates) { template in
                                Button(template.name) {
                                    let newSkill = CharacterSkill(template: template, value: 1)
                                    character.learnedSkills.append(newSkill)
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Button {
                            selectedSkillCategory = "Tongues"
                            showingQuickAddSkill = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                .textCase(nil)
            }

            Section {
                Text("DASHBOARD")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color(.systemGray6))
            }

            // Physical Combat
            Section {
                if physicalCombatMetrics.isEmpty {
                    Text("No physical combat metrics yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(physicalCombatMetrics) { metric in
                        combatMetricDisclosureRow(metric)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(metric)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            modelContext.delete(physicalCombatMetrics[index])
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Physical Combat")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()

                    // Combat metric add button
                    if !physicalCombatMetricTemplates.isEmpty || !skillsWithoutInitiative.isEmpty {
                        Menu {
                            if !skillsWithoutInitiative.isEmpty {
                                Button("New Initiative…") {
                                    initiativeSubcategory = "Physical"
                                    showingAddInitiative = true
                                }
                            }

                            if !physicalCombatMetricTemplates.isEmpty {
                                if !skillsWithoutInitiative.isEmpty {
                                    Divider()
                                }
                                ForEach(physicalCombatMetricTemplates) { template in
                                    Button(template.name) {
                                        let metric = CharacterCombatMetric(template: template)
                                        character.combatMetrics.append(metric)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .menuStyle(.button)
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                .textCase(nil)
            }

            // Combat Metrics - Occult
            Section {
                if occultCombatMetrics.isEmpty {
                    Text("No occult combat metrics yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(occultCombatMetrics) { metric in
                        combatMetricDisclosureRow(metric)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(metric)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            modelContext.delete(occultCombatMetrics[index])
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Occult Combat")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()

                    // Combat metric add button
                    if !occultCombatMetricTemplates.isEmpty || !skillsWithoutInitiative.isEmpty {
                        Menu {
                            if !skillsWithoutInitiative.isEmpty {
                                Button("New Initiative…") {
                                    initiativeSubcategory = "Occult"
                                    showingAddInitiative = true
                                }
                            }

                            if !occultCombatMetricTemplates.isEmpty {
                                if !skillsWithoutInitiative.isEmpty {
                                    Divider()
                                }
                                ForEach(occultCombatMetricTemplates) { template in
                                    Button(template.name) {
                                        let metric = CharacterCombatMetric(template: template)
                                        character.combatMetrics.append(metric)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .menuStyle(.button)
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                .textCase(nil)
            }

            // General Traits
            Section {
                Text("Coming soon")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } header: {
                HStack {
                    Text("General Traits")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                .textCase(nil)
            }

            Section {
                Text("GOAL ROLLS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color(.systemGray6))
            }

            // Goal Roll Categories
            ForEach(goalRollCategories) { category in
                Section {
                    let rolls = goalRollsForCategory(category)
                    if rolls.isEmpty {
                        Text("No goal rolls yet.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(rolls) { roll in
                            goalRollDisclosureRow(roll)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(roll)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .onMove { fromOffsets, toOffset in
                            moveGoalRolls(in: category, from: fromOffsets, to: toOffset)
                        }
                    }
                } header: {
                    HStack {
                        Text(category.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Spacer()

                        // Category settings
                        Menu {
                            Button {
                                showingCategorySettings = category
                                renameCategoryName = category.name
                                showingRenameCategoryAlert = true
                            } label: {
                                Label("Rename Category", systemImage: "pencil")
                            }

                            Button {
                                showingNewGoalRollCategory = true
                            } label: {
                                Label("New Category", systemImage: "plus")
                            }

                            if canDeleteCategory {
                                Divider()
                                Button(role: .destructive) {
                                    categoryToDelete = category
                                    showingDeleteCategoryAlert = true
                                } label: {
                                    Label("Delete Category", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)

                        // Add button (simplified for now)
                        Button {
                            selectedCategoryForNewRoll = category
                            showingAddRollNew = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
                    .textCase(nil)
                }
            }
        }
        .scrollDismissesKeyboard(.never)
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Duplicate Name", isPresented: $showingDuplicateNameAlert) {
            Button("OK") {
                character.name = previousValidName
            }
        } message: {
            Text("A character named \"\(character.name)\" already exists. Please choose a different name.")
        }
        .alert("Rename Category", isPresented: $showingRenameCategoryAlert) {
            TextField("Category Name", text: $renameCategoryName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) {
                renameCategoryName = ""
                showingCategorySettings = nil
            }
            Button("Rename") {
                if let category = showingCategorySettings {
                    renameCategory(category, to: renameCategoryName)
                }
            }
        } message: {
            Text("Enter a new name for the category")
        }
        .alert("New Category", isPresented: $showingNewGoalRollCategory) {
            TextField("Category Name", text: $newGoalRollCategoryName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) {
                newGoalRollCategoryName = ""
            }
            Button("Create") {
                createNewCategory()
            }
        } message: {
            Text("Enter a name for the new category")
        }
        .alert("Delete Category?", isPresented: $showingDeleteCategoryAlert) {
            if let category = categoryToDelete, !goalRollsForCategory(category).isEmpty {
                Button("Delete Rolls & Category", role: .destructive) {
                    deleteCategory(category, deleteRolls: true)
                }
                Button("Move Rolls to...") {
                    showingDeleteCategoryAlert = false
                    showingMigrationPicker = true
                }
                Button("Cancel", role: .cancel) {
                    categoryToDelete = nil
                }
            } else {
                Button("Delete", role: .destructive) {
                    if let category = categoryToDelete {
                        deleteCategory(category, deleteRolls: true)
                    }
                }
                Button("Cancel", role: .cancel) {
                    categoryToDelete = nil
                }
            }
        } message: {
            if let category = categoryToDelete {
                let rollCount = goalRollsForCategory(category).count
                if rollCount > 0 {
                    Text("This category contains \(rollCount) goal roll(s). What would you like to do?")
                } else {
                    Text("Delete the \"\(category.name)\" category?")
                }
            }
        }
        .onAppear {
            ensureLibraryExists()
            ensureDefaultCategories()
            previousValidName = character.name
        }
        .sheet(isPresented: $showingAddRollNew) {
            AddGoalRollView(character: character, isPresented: $showingAddRollNew, category: selectedCategoryForNewRoll)
        }
        .sheet(isPresented: $showingAddInitiative) {
            if let lib = library {
                AddInitiativeView(character: character, library: lib, isPresented: $showingAddInitiative, subcategory: initiativeSubcategory)
            }
        }
        .sheet(isPresented: $showingMigrationPicker) {
            MigrationPickerView(
                isPresented: $showingMigrationPicker,
                categories: goalRollCategories.filter { $0.persistentModelID != categoryToDelete?.persistentModelID },
                onSelect: { targetCategory in
                    if let categoryToDelete {
                        migrateAndDeleteCategory(categoryToDelete, to: targetCategory)
                    }
                }
            )
        }
        .alert("New \(alertSkillTypeLabel)", isPresented: $showingQuickAddSkill) {
            TextField("Name", text: $quickAddSkillName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) {
                quickAddSkillName = ""
            }
            Button("Add") {
                addQuickSkill()
            }
        } message: {
            Text("Enter a name for the new \(alertSkillTypeLabel.lowercased())")
        }
    }

    // MARK: - Row builders

    @ViewBuilder
    private func statDisclosureRow(_ stat: Stat) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Base Value")
                    Spacer()
                    Text("\(stat.value)")
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Effective Value")
                    Spacer()
                    Text("\(stat.value)")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Keywords")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(stat.implicitKeywords.joined(separator: ", "))
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                Text(stat.name)

                Spacer()

                Button {
                    stat.value -= 1
                    if stat.value < stat.minimumValue { stat.value = stat.minimumValue }
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.plain)

                Text("\(stat.value)")
                    .frame(width: 44)
                    .font(.headline)

                Button {
                    stat.value += 1
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func skillDisclosureRow(_ skill: CharacterSkill) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Base Value")
                    Spacer()
                    Text("\(skill.value)")
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Effective Value")
                    Spacer()
                    Text("\(skill.value)")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Keywords")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(skill.keywordsForRules.joined(separator: ", "))
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                Text(skill.effectiveName)

                Spacer()

                Button {
                    skill.value -= 1
                    if skill.value < skill.minimumValue { skill.value = skill.minimumValue }
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.plain)

                ZStack {
                    if focusedSkillID == skill.persistentModelID {
                        TextField("", value: Binding(
                            get: { skill.value },
                            set: { newVal in skill.value = max(newVal, skill.minimumValue) }
                        ), format: .number)
                            .frame(width: 44)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($focusedSkillID, equals: skill.persistentModelID)
                    } else {
                        Text("\(skill.value)")
                            .frame(width: 44)
                            .font(.headline)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusedSkillID = skill.persistentModelID
                            }
                    }
                }

                Button {
                    skill.value += 1
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func goalRollDisclosureRow(_ roll: CharacterGoalRoll) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                if let attrStat = roll.attributeStat {
                    HStack {
                        Text("Attribute")
                        Spacer()
                        Text(attrStat.name)
                            .fontWeight(.medium)
                    }
                }

                if let skillName = roll.skillName {
                    HStack {
                        Text("Skill")
                        Spacer()
                        Text(skillName)
                            .fontWeight(.medium)
                    }
                }

                HStack {
                    Text("Goal Value")
                    Spacer()
                    Text("\(roll.goalValue)")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Keywords")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(roll.keywordsForRules.joined(separator: ", "))
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(roll.name)
                Text("Goal: \(roll.goalValue)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func combatMetricDisclosureRow(_ metric: CharacterCombatMetric) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                if !metric.effectiveDescription.isEmpty {
                    HStack {
                        Text("Description")
                        Spacer()
                        Text(metric.effectiveDescription)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // Show calculation breakdown
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Base Value")
                        Spacer()
                        Text("\(metric.calculatedBaseValue)")
                            .fontWeight(.bold)
                    }

                    // Show breakdown
                    ForEach(Array(metric.calculationBreakdown.enumerated()), id: \.offset) { _, component in
                        HStack {
                            Text("  \(component.0)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(component.1)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Keywords")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(metric.keywordsForRules.joined(separator: ", "))
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                Text(metric.effectiveName)
                Spacer()
                Text("\(metric.calculatedBaseValue)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Validation & Actions

    private func validateName() {
        let trimmed = character.name.trimmingCharacters(in: .whitespacesAndNewlines)

        // If empty, revert to previous
        if trimmed.isEmpty {
            character.name = previousValidName
            return
        }

        // Check for duplicates
        let isDuplicate = allCharacters.contains { otherChar in
            otherChar.persistentModelID != character.persistentModelID &&
            otherChar.name.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(trimmed) == .orderedSame
        }

        if isDuplicate {
            showingDuplicateNameAlert = true
        } else {
            previousValidName = character.name
        }
    }

    private func addQuickSkill() {
        guard let library else { return }
        let trimmed = quickAddSkillName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            quickAddSkillName = ""
            return
        }

        // Create template and add skill
        let template = SkillTemplate(
            name: trimmed,
            category: selectedSkillCategory,
            templateDescription: "",
            userKeywords: ""
        )
        library.skillTemplates.append(template)

        let skill = CharacterSkill(template: template, value: 1)
        character.learnedSkills.append(skill)

        quickAddSkillName = ""
    }

    // MARK: - Library bootstrap

    private func ensureLibraryExists() {
        if library == nil {
            let lib = RulesLibrary()
            modelContext.insert(lib)
        }
        // Bootstrap combat metrics if needed
        if let lib = library, lib.combatMetricTemplates.isEmpty {
            bootstrapCombatMetrics(lib)
        }
    }

    private func bootstrapCombatMetrics(_ library: RulesLibrary) {
        // Physical Combat Metrics
        let physicalMetrics: [CombatMetricTemplate] = [
            CombatMetricTemplate(
                name: "Actions (physical)",
                subcategory: "Physical",
                additionalKeywords: "physical actions",
                baseValueFormula: "3"
            ),
            CombatMetricTemplate(
                name: "Hit Points",
                subcategory: "Physical",
                baseValueFormula: "5 + Endurance"
            ),
            CombatMetricTemplate(
                name: "Recovery",
                subcategory: "Physical",
                templateDescription: "available in-combat healing",
                baseValueFormula: "0"
            ),
            CombatMetricTemplate(
                name: "Armor",
                subcategory: "Physical",
                baseValueFormula: "0"
            ),
            CombatMetricTemplate(
                name: "Damage",
                subcategory: "Physical",
                baseValueFormula: "Strength / 3"
            ),
            CombatMetricTemplate(
                name: "Guard",
                subcategory: "Physical",
                templateDescription: "penalty to be hit",
                baseValueFormula: "0"
            ),
            CombatMetricTemplate(
                name: "Pressure",
                subcategory: "Physical",
                templateDescription: "penalty to be parried",
                baseValueFormula: "0"
            )
        ]

        // Occult Combat Metrics
        let occultMetrics: [CombatMetricTemplate] = [
            CombatMetricTemplate(
                name: "Actions (mental)",
                subcategory: "Occult",
                additionalKeywords: "mental actions",
                baseValueFormula: "1"
            ),
            CombatMetricTemplate(
                name: "Wyrd",
                subcategory: "Occult",
                baseValueFormula: "Wyrd"
            ),
            CombatMetricTemplate(
                name: "Psi Bonus",
                subcategory: "Occult",
                baseValueFormula: "0"
            ),
            CombatMetricTemplate(
                name: "Theurgy Bonus",
                subcategory: "Occult",
                baseValueFormula: "0"
            ),
            CombatMetricTemplate(
                name: "Occult Bonus",
                subcategory: "Occult",
                baseValueFormula: "0"
            ),
            CombatMetricTemplate(
                name: "Occult Power",
                subcategory: "Occult",
                templateDescription: "penalty to be resisted (all occult)",
                baseValueFormula: "0"
            ),
            CombatMetricTemplate(
                name: "Theurgy Power",
                subcategory: "Occult",
                templateDescription: "penalty to be resisted (theurgy only)",
                baseValueFormula: "2"
            ),
            CombatMetricTemplate(
                name: "Psi Power",
                subcategory: "Occult",
                templateDescription: "penalty to be resisted (psi only)",
                baseValueFormula: "0"
            )
        ]

        library.combatMetricTemplates.append(contentsOf: physicalMetrics)
        library.combatMetricTemplates.append(contentsOf: occultMetrics)
    }

    private func ensureDefaultCategories() {
        // Create default Physical and Occult categories if none exist
        if character.goalRollCategories.isEmpty {
            let physical = GoalRollCategory(name: "Physical", displayOrder: 0)
            physical.character = character
            character.goalRollCategories.append(physical)
            modelContext.insert(physical)

            let occult = GoalRollCategory(name: "Occult", displayOrder: 1)
            occult.character = character
            character.goalRollCategories.append(occult)
            modelContext.insert(occult)
        }

        // Assign uncategorized goal rolls to first category
        let firstCategory = character.goalRollCategories.sorted { $0.displayOrder < $1.displayOrder }.first
        for roll in character.goalRolls where roll.category == nil {
            roll.category = firstCategory
        }
    }

    // MARK: - Category Management

    private func renameCategory(_ category: GoalRollCategory, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        category.name = trimmed
        showingCategorySettings = nil
        renameCategoryName = ""
    }

    private func createNewCategory() {
        let trimmed = newGoalRollCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let maxOrder = character.goalRollCategories.map { $0.displayOrder }.max() ?? 0
        let newCategory = GoalRollCategory(name: trimmed, displayOrder: maxOrder + 1)
        newCategory.character = character
        character.goalRollCategories.append(newCategory)
        modelContext.insert(newCategory)

        newGoalRollCategoryName = ""
    }

    private func deleteCategory(_ category: GoalRollCategory, deleteRolls: Bool) {
        if deleteRolls {
            // Delete all goal rolls in this category
            let rolls = goalRollsForCategory(category)
            for roll in rolls {
                modelContext.delete(roll)
            }
        }

        // Delete the category
        modelContext.delete(category)
        categoryToDelete = nil
    }

    private func migrateAndDeleteCategory(_ category: GoalRollCategory, to targetCategory: GoalRollCategory) {
        // Move all goal rolls to the target category
        let rolls = goalRollsForCategory(category)
        for roll in rolls {
            roll.category = targetCategory
        }

        // Delete the now-empty category
        modelContext.delete(category)
        categoryToDelete = nil
        showingMigrationPicker = false
    }

    private func moveGoalRolls(in category: GoalRollCategory, from source: IndexSet, to destination: Int) {
        var rolls = goalRollsForCategory(category)
        rolls.move(fromOffsets: source, toOffset: destination)

        // Update displayOrder for all rolls in this category
        for (index, roll) in rolls.enumerated() {
            roll.displayOrder = index
        }
    }
}
