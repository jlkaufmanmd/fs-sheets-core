import Foundation
import SwiftData

@Model
class RPGCharacter {
    @Attribute(.unique) var id: UUID
    
    var name: String
    var characterDescription: String
    
    @Relationship(deleteRule: .cascade, inverse: \Stat.character)
    var stats: [Stat]
    
    @Relationship(deleteRule: .cascade, inverse: \CharacterSkill.character)
    var learnedSkills: [CharacterSkill]
    
    @Relationship(deleteRule: .cascade, inverse: \CharacterGoalRoll.character)
    var goalRolls: [CharacterGoalRoll]
    
    init(name: String, characterDescription: String = "") {
        self.id = UUID()
        self.name = name
        self.characterDescription = characterDescription
        self.stats = []
        self.learnedSkills = []
        self.goalRolls = []
    }
}

@Model
class Stat: KeywordProvider {
    @Attribute(.unique) var id: UUID
    
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
        self.id = UUID()
        self.name = name
        self.value = value
        self.statType = statType
        self.category = category
        self.displayOrder = displayOrder
        self.isDeletable = isDeletable
    }
    
    var minimumValue: Int {
        if KeywordUtil.normalize(statType) == "attribute" {
            return category == "Occult" ? 0 : 1
        } else {
            return category == "Natural Skills" ? 1 : 0
        }
    }
    
    /// Keywords intrinsic to this Stat (no user keywords yet).
    var implicitKeywords: [String] {
        let typeKey = KeywordUtil.normalize(statType)
        let catKey  = KeywordUtil.normalize(category)
        let nameKey = KeywordUtil.normalize(name)
        
        var base = [nameKey, "stat", typeKey, catKey]
        
        if typeKey == "attribute" { base.append("attribute") }
        if typeKey == "skill" { base.append("skill") }
        
        if catKey.contains("natural") {
            base.append("natural")
            base.append("natural skill")
        }
        
        return Array(Set(base.map(KeywordUtil.normalize))).sorted()
    }
    
    // KeywordProvider
    var keywordsForRules: [String] { implicitKeywords }
}

