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

    init(name: String, characterDescription: String = "") {
        self.name = name
        self.characterDescription = characterDescription
        self.stats = []
        self.learnedSkills = []
        self.goalRolls = []
    }
}

@Model
final class Stat: KeywordProvider {
    var name: String
    var value: Int

    var statType: String // "attribute" or "skill"
    var category: String // "Body", "Mind", "Natural Skills", etc.
    var displayOrder: Int
    var isDeletable: Bool

    var character: RPGCharacter?

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
        let catKey  = KeywordUtil.normalize(category)
        let nameKey = KeywordUtil.normalize(name)

        var keys: [String] = [
            nameKey,
            "stat",
            typeKey,
            catKey
        ]

        if typeKey == "attribute" { keys.append("attribute") }
        if typeKey == "skill" { keys.append("skill") }

        if catKey.contains("natural") {
            keys.append("natural")
            keys.append("natural skill")
        }

        return Array(Set(keys.map(KeywordUtil.normalize))).sorted()
    }

    var keywordsForRules: [String] { implicitKeywords }
}
