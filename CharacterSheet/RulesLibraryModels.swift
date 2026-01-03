import Foundation
import SwiftData

@Model
class RulesLibrary {
    var createdDate: Date

    @Relationship(deleteRule: .cascade)
    var goalRollTemplates: [GoalRollTemplate]

    @Relationship(deleteRule: .cascade)
    var skillTemplates: [SkillTemplate]

    init() {
        self.createdDate = Date()
        self.goalRollTemplates = []
        self.skillTemplates = []
    }
}

// MARK: - Skill Templates (Learned Skills / Lores / Tongues)

@Model
class SkillTemplate {
    @Attribute(.unique) var name: String
    var category: String // "Learned Skills", "Lores", "Tongues"
    var templateDescription: String
    var userKeywords: String

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
            base: [name, "skill", "stat", category],
            user: userKeywords
        )
    }
}

extension SkillTemplate: KeywordProvider {
    var keywordsForRules: [String] { implicitKeywords }
}

@Model
class CharacterSkill {
    @Attribute(.unique) var id: UUID

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
        self.id = UUID()
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
            base: [effectiveName, "skill", "stat", effectiveCategory],
            user: effectiveUserKeywords
        )
    }
}

extension CharacterSkill: KeywordProvider { }

// MARK: - Goal Roll Templates

@Model
class GoalRollTemplate {
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
}

extension GoalRollTemplate: KeywordProvider {
    var keywordsForRules: [String] { implicitKeywords }
}

@Model
class CharacterGoalRoll {
    @Attribute(.unique) var id: UUID

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
        self.id = UUID()

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
            $0.category == t.defaultAttributeCategory &&
            $0.name.caseInsensitiveCompare(t.defaultAttributeName) == .orderedSame
        })
    }

    var effectiveNaturalSkillStat: Stat? {
        if isBranched { return naturalSkillStat }
        guard let character, let t = template else { return nil }
        guard t.defaultSkillMode == .natural else { return nil }
        return character.stats.first(where: {
            KeywordUtil.normalize($0.statType) == "skill" &&
            $0.category == "Natural Skills" &&
            $0.name.caseInsensitiveCompare(t.defaultNaturalSkillName) == .orderedSame
        })
    }

    var effectiveCharacterSkill: CharacterSkill? {
        if isBranched { return characterSkill }
        guard let character, let t = template else { return nil }
        guard t.defaultSkillMode == .learned, let learnedTemplate = t.defaultLearnedSkillTemplate else { return nil }

        // Find existing instance on this character (no side effects here)
        return character.learnedSkills.first(where: { $0.template?.persistentModelID == learnedTemplate.persistentModelID })
    }

    var goalValue: Int {
        let attrValue = effectiveAttributeStat?.value ?? 0
        let skillValue: Int
        if effectiveSkillMode == .natural {
            skillValue = effectiveNaturalSkillStat?.value ?? 0
        } else {
            skillValue = effectiveCharacterSkill?.value ?? 0
        }
        return attrValue + skillValue + effectiveBaseModifier
    }

    var skillName: String? {
        if effectiveSkillMode == .natural { return effectiveNaturalSkillStat?.name }
        return effectiveCharacterSkill?.effectiveName
    }

    var keywordsForRules: [String] {
        var base = [effectiveName, "goal roll"]

        if let attr = effectiveAttributeStat?.name { base.append(attr) }
        if let s = skillName { base.append(s) }

        return KeywordUtil.make(base: base, user: effectiveUserKeywords)
    }
}

extension CharacterGoalRoll: KeywordProvider { }
