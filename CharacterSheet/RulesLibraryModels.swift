import Foundation
import SwiftData

@Model
final class RulesLibrary {
    var createdDate: Date

    // Explicit inverses help CloudKit/SwiftData sync and migrations.
    @Relationship(deleteRule: .cascade, inverse: \GoalRollTemplate.library)
    var goalRollTemplates: [GoalRollTemplate]

    @Relationship(deleteRule: .cascade, inverse: \SkillTemplate.library)
    var skillTemplates: [SkillTemplate]

    @Relationship(deleteRule: .cascade, inverse: \CombatMetricTemplate.library)
    var combatMetricTemplates: [CombatMetricTemplate]

    init() {
        self.createdDate = Date()
        self.goalRollTemplates = []
        self.skillTemplates = []
        self.combatMetricTemplates = []
    }
}

// MARK: - Skill Templates (Learned Skills / Lores / Tongues)

@Model
final class SkillTemplate: KeywordProvider {
    @Attribute(.unique) var name: String
    var category: String // "Learned Skills", "Lores", "Tongues"
    var templateDescription: String
    var userKeywords: String

    // Back-reference for inverse relationship
    var library: RulesLibrary?

    init(
        name: String,
        category: String,
        templateDescription: String = "",
        userKeywords: String = ""
    ) {
        self.name = name
        self.category = category
        self.templateDescription = templateDescription
        self.userKeywords = userKeywords
    }

    var implicitKeywords: [String] {
        KeywordUtil.make(
            base: [name, "skill", "stat", KeywordUtil.categoryToKeyword(category)],
            user: userKeywords
        )
    }

    var keywordsForRules: [String] { implicitKeywords }
}

@Model
final class CharacterSkill: KeywordProvider {
    var value: Int

    var isBranched: Bool
    var branchedDate: Date?

    var overrideName: String
    var overrideCategory: String
    var overrideDescription: String
    var overrideUserKeywords: String

    var template: SkillTemplate?
    var character: RPGCharacter?

    init(template: SkillTemplate, value: Int = 0) {
        self.template = template
        self.value = value
        self.isBranched = false
        self.branchedDate = nil
        self.overrideName = ""
        self.overrideCategory = ""
        self.overrideDescription = ""
        self.overrideUserKeywords = ""
    }

    var effectiveName: String { isBranched ? overrideName : (template?.name ?? overrideName) }
    var effectiveCategory: String { isBranched ? overrideCategory : (template?.category ?? overrideCategory) }
    var effectiveDescription: String { isBranched ? overrideDescription : (template?.templateDescription ?? overrideDescription) }
    var effectiveUserKeywords: String { isBranched ? overrideUserKeywords : (template?.userKeywords ?? overrideUserKeywords) }

    var minimumValue: Int { 0 }

    var keywordsForRules: [String] {
        KeywordUtil.make(
            base: [effectiveName, "skill", "stat", KeywordUtil.categoryToKeyword(effectiveCategory)],
            user: effectiveUserKeywords
        )
    }
}

// MARK: - Goal Roll Templates

@Model
final class GoalRollTemplate: KeywordProvider {
    enum SkillMode: String, Codable, CaseIterable {
        case natural = "Natural Skill"
        case learned = "Learned/Lore/Tongue"
    }

    @Attribute(.unique) var name: String
    var templateDescription: String
    var baseModifier: Int
    var userKeywords: String

    // Default formula
    var defaultAttributeName: String
    var defaultAttributeCategory: String // "Body", "Mind", "Spirit", "Occult"

    var defaultSkillModeRaw: String

    // If SkillMode == .natural
    var defaultNaturalSkillName: String

    // If SkillMode == .learned
    var defaultLearnedSkillTemplate: SkillTemplate?

    // Back-reference for inverse relationship
    var library: RulesLibrary?

    init(
        name: String,
        templateDescription: String = "",
        baseModifier: Int = 0,
        userKeywords: String = "",
        defaultAttributeName: String = "",
        defaultAttributeCategory: String = "Body",
        defaultSkillMode: SkillMode = .natural,
        defaultNaturalSkillName: String = "",
        defaultLearnedSkillTemplate: SkillTemplate? = nil
    ) {
        self.name = name
        self.templateDescription = templateDescription
        self.baseModifier = baseModifier
        self.userKeywords = userKeywords

        self.defaultAttributeName = defaultAttributeName
        self.defaultAttributeCategory = defaultAttributeCategory

        self.defaultSkillModeRaw = defaultSkillMode.rawValue
        self.defaultNaturalSkillName = defaultNaturalSkillName
        self.defaultLearnedSkillTemplate = defaultLearnedSkillTemplate
    }

    var defaultSkillMode: SkillMode {
        get { SkillMode(rawValue: defaultSkillModeRaw) ?? .natural }
        set { defaultSkillModeRaw = newValue.rawValue }
    }

    var implicitKeywords: [String] {
        KeywordUtil.make(
            base: [name, "goal roll"],
            user: userKeywords
        )
    }

    var keywordsForRules: [String] { implicitKeywords }
}

@Model
final class CharacterGoalRoll: KeywordProvider {
    var isBranched: Bool
    var branchedDate: Date?

    var overrideName: String
    var overrideDescription: String
    var overrideBaseModifier: Int
    var overrideUserKeywords: String

    var template: GoalRollTemplate?

    // When branched: used as overrides
    var attributeStat: Stat?
    var naturalSkillStat: Stat?
    var characterSkill: CharacterSkill?

    var character: RPGCharacter?

    init(
        template: GoalRollTemplate,
        attributeStat: Stat? = nil,
        naturalSkillStat: Stat? = nil,
        characterSkill: CharacterSkill? = nil
    ) {
        self.template = template
        self.attributeStat = attributeStat
        self.naturalSkillStat = naturalSkillStat
        self.characterSkill = characterSkill

        self.isBranched = false
        self.branchedDate = nil
        self.overrideName = ""
        self.overrideDescription = ""
        self.overrideBaseModifier = 0
        self.overrideUserKeywords = ""
    }

    // MARK: - Template fields (name/desc/mod/keywords)

    var effectiveName: String { isBranched ? overrideName : (template?.name ?? overrideName) }
    var effectiveDescription: String { isBranched ? overrideDescription : (template?.templateDescription ?? overrideDescription) }
    var effectiveBaseModifier: Int { isBranched ? overrideBaseModifier : (template?.baseModifier ?? overrideBaseModifier) }
    var effectiveUserKeywords: String { isBranched ? overrideUserKeywords : (template?.userKeywords ?? overrideUserKeywords) }

    // MARK: - Formula resolution (template-defaults unless branched)

    var effectiveSkillMode: GoalRollTemplate.SkillMode {
        if isBranched {
            return characterSkill != nil ? .learned : .natural
        }
        return template?.defaultSkillMode ?? .natural
    }

    var effectiveAttributeStat: Stat? {
        if isBranched { return attributeStat }
        guard let character, let t = template else { return nil }
        return character.stats.first(where: {
            KeywordUtil.normalize($0.statType) == "attribute" &&
            KeywordUtil.normalize($0.category) == KeywordUtil.normalize(t.defaultAttributeCategory) &&
            $0.name.caseInsensitiveCompare(t.defaultAttributeName) == .orderedSame
        })
    }

    var effectiveNaturalSkillStat: Stat? {
        if isBranched { return naturalSkillStat }
        guard let character, let t = template else { return nil }
        guard t.defaultSkillMode == .natural else { return nil }
        return character.stats.first(where: {
            KeywordUtil.normalize($0.statType) == "skill" &&
            KeywordUtil.normalize($0.category) == KeywordUtil.normalize("Natural Skills") &&
            $0.name.caseInsensitiveCompare(t.defaultNaturalSkillName) == .orderedSame
        })
    }

    var effectiveCharacterSkill: CharacterSkill? {
        if isBranched { return characterSkill }
        guard let character, let t = template else { return nil }
        guard t.defaultSkillMode == .learned, let learnedTemplate = t.defaultLearnedSkillTemplate else { return nil }

        return character.learnedSkills.first(where: {
            $0.template?.persistentModelID == learnedTemplate.persistentModelID
        })
    }

    var goalValue: Int {
        let attrValue = effectiveAttributeStat?.value ?? 0
        let skillValue: Int = (effectiveSkillMode == .natural)
            ? (effectiveNaturalSkillStat?.value ?? 0)
            : (effectiveCharacterSkill?.value ?? 0)

        return attrValue + skillValue + effectiveBaseModifier
    }

    var skillName: String? {
        if effectiveSkillMode == .natural { return effectiveNaturalSkillStat?.name }
        return effectiveCharacterSkill?.effectiveName
    }

    // ✅ Important fix: use EFFECTIVE values so non-branched rolls still produce good keywords.
    var keywordsForRules: [String] {
        var base = [effectiveName, "goal roll"]

        if let attr = effectiveAttributeStat?.name { base.append(attr) }
        if let s = skillName { base.append(s) }

        return KeywordUtil.make(base: base, user: effectiveUserKeywords)
    }
}

// MARK: - Combat Metric Templates

@Model
final class CombatMetricTemplate: KeywordProvider {
    @Attribute(.unique) var name: String
    var subcategory: String // "Physical" or "Occult"
    var templateDescription: String
    var additionalKeywords: String // Explicitly defined keywords (not user-editable)
    var baseValueFormula: String // Formula or static value as string
    var isInitiative: Bool
    var associatedSkillName: String // For initiatives only

    var library: RulesLibrary?

    init(
        name: String,
        subcategory: String,
        templateDescription: String = "",
        additionalKeywords: String = "",
        baseValueFormula: String = "0",
        isInitiative: Bool = false,
        associatedSkillName: String = ""
    ) {
        self.name = name
        self.subcategory = subcategory
        self.templateDescription = templateDescription
        self.additionalKeywords = additionalKeywords
        self.baseValueFormula = baseValueFormula
        self.isInitiative = isInitiative
        self.associatedSkillName = associatedSkillName
    }

    var implicitKeywords: [String] {
        let combatProfileType = subcategory.lowercased() + " combat profile"
        var base = [name, "stat", "calculated stat", combatProfileType]

        // Add additional keywords
        let additional = additionalKeywords
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        base.append(contentsOf: additional)

        return Array(Set(base.map(KeywordUtil.normalize))).sorted()
    }

    var keywordsForRules: [String] { implicitKeywords }
}

@Model
final class CharacterCombatMetric: KeywordProvider {
    var value: Int

    var template: CombatMetricTemplate?
    var character: RPGCharacter?

    init(template: CombatMetricTemplate, value: Int = 0) {
        self.template = template
        self.value = value
    }

    var effectiveName: String { template?.name ?? "" }
    var effectiveDescription: String { template?.templateDescription ?? "" }
    var effectiveSubcategory: String { template?.subcategory ?? "" }

    // Calculate base value from formula
    var calculatedBaseValue: Int {
        guard let template, let character else { return 0 }
        return evaluateFormula(template.baseValueFormula)
    }

    private func evaluateFormula(_ formula: String) -> Int {
        guard let character else { return 0 }

        // Handle static values
        if let staticValue = Int(formula) {
            return staticValue
        }

        // Handle special formulas
        switch formula {
        case "5 + Endurance":
            let endurance = character.stats.first { $0.name == "Endurance" }
            return 5 + (endurance?.value ?? 0)

        case "Strength / 3":
            let strength = character.stats.first { $0.name == "Strength" }
            return (strength?.value ?? 0) / 3

        case "Wyrd":
            return calculateWyrd()

        default:
            return 0
        }
    }

    private func calculateWyrd() -> Int {
        guard let character else { return 1 }

        let psi = character.stats.first { $0.name == "Psi" }?.value ?? 0
        let theurgy = character.stats.first { $0.name == "Theurgy" }?.value ?? 0
        let introvert = character.stats.first { $0.name == "Introvert" }?.value ?? 0
        let faith = character.stats.first { $0.name == "Faith" }?.value ?? 0

        if psi > 0 && theurgy == 0 {
            return introvert
        } else if psi == 0 && theurgy > 0 {
            return faith
        } else if psi > 0 && theurgy > 0 {
            return max(introvert, faith)
        } else {
            return 1
        }
    }

    // Breakdown showing how the value was calculated
    var calculationBreakdown: [(String, Int)] {
        guard let template, let character else { return [] }

        switch template.baseValueFormula {
        case "5 + Endurance":
            let endurance = character.stats.first { $0.name == "Endurance" }?.value ?? 0
            return [("vital", 5), ("Endurance", endurance)]

        case "Strength / 3":
            let strength = character.stats.first { $0.name == "Strength" }?.value ?? 0
            return [("Strength / 3 (rounded down)", strength / 3)]

        case "Wyrd":
            let psi = character.stats.first { $0.name == "Psi" }?.value ?? 0
            let theurgy = character.stats.first { $0.name == "Theurgy" }?.value ?? 0
            let introvert = character.stats.first { $0.name == "Introvert" }?.value ?? 0
            let faith = character.stats.first { $0.name == "Faith" }?.value ?? 0

            if psi > 0 && theurgy == 0 {
                return [("Introvert", introvert)]
            } else if psi == 0 && theurgy > 0 {
                return [("Faith", faith)]
            } else if psi > 0 && theurgy > 0 {
                let maxValue = max(introvert, faith)
                if introvert > faith {
                    return [("max(Introvert, Faith)", maxValue)]
                } else if faith > introvert {
                    return [("max(Introvert, Faith)", maxValue)]
                } else {
                    return [("Introvert or Faith", maxValue)]
                }
            } else {
                return [("default", 1)]
            }

        default:
            // Static value or unknown formula
            if let staticValue = Int(template.baseValueFormula) {
                return [(template.baseValueFormula, staticValue)]
            }
            return []
        }
    }

    var keywordsForRules: [String] {
        template?.implicitKeywords ?? []
    }
}
