import Foundation
import SwiftData

@Model
final class RPGCharacter {
    var name: String
    var characterDescription: String

    @Relationship(deleteRule: .cascade, inverse: \Stat.character)
    var stats: [Stat]

    @Relationship(deleteRule: .cascade, inverse: \CharacterSkill.character)
    var learnedSkills: [CharacterSkill]

    @Relationship(deleteRule: .cascade, inverse: \CharacterGoalRoll.character)
    var goalRolls: [CharacterGoalRoll]

    @Relationship(deleteRule: .cascade, inverse: \GoalRollCategory.character)
    var goalRollCategories: [GoalRollCategory]

    @Relationship(deleteRule: .cascade, inverse: \CharacterCombatMetric.character)
    var combatMetrics: [CharacterCombatMetric]

    init(name: String, characterDescription: String = "") {
        self.name = name
        self.characterDescription = characterDescription
        self.stats = []
        self.learnedSkills = []
        self.goalRolls = []
        self.goalRollCategories = []
        self.combatMetrics = []
    }
}

@Model
final class Stat: KeywordProvider {
    var name: String
    var value: Int  // Base value

    var statType: String // "attribute" or "skill"
    var category: String // "Body", "Mind", "Natural Skills", etc.
    var displayOrder: Int
    var isDeletable: Bool

    var character: RPGCharacter?

    // TODO: Add modifier system - for now, effective value equals base value
    var effectiveValue: Int {
        // Future: calculate base + modifiers
        return value
    }

    var hasModifiers: Bool {
        // Future: check if any modifiers exist
        return false
    }

    init(
        name: String,
        value: Int,
        statType: String,
        category: String,
        displayOrder: Int,
        isDeletable: Bool
    ) {
        self.name = name
        self.value = value
        self.statType = statType
        self.category = category
        self.displayOrder = displayOrder
        self.isDeletable = isDeletable
    }

    var minimumValue: Int {
        let typeKey = KeywordUtil.normalize(statType)
        let catKey = KeywordUtil.normalize(category)

        if typeKey == "attribute" {
            return catKey == "occult" ? 0 : 1
        } else {
            return catKey == KeywordUtil.normalize("Natural Skills") ? 1 : 0
        }
    }

    /// Keywords intrinsic to this Stat (no user keywords yet).
    /// Using "implicit" so we can reserve "effective" later for modified values.
    var implicitKeywords: [String] {
        let typeKey = KeywordUtil.normalize(statType)
        let catKey  = KeywordUtil.categoryToKeyword(category)
        let nameKey = KeywordUtil.normalize(name)

        let keys: [String] = [
            nameKey,
            "stat",
            typeKey,
            catKey
        ]

        return Array(Set(keys)).sorted()
    }

    var keywordsForRules: [String] { implicitKeywords }
}
