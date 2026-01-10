# Implementation Patterns - Phase 1

**Purpose:** Detailed code examples and implementation patterns for Phase 1 development. Reference this file when implementing data models, protocols, and core systems.

**IMPORTANT:** These patterns are Phase 1-focused. They include optional fields for Phase 2A/2B features, but those fields remain unused in Phase 1.

---

## Core Data Models

### Template Scope & Modifier Types

```swift
enum TemplateScope: String, Codable {
    case local              // User's personal library
    case characterOverride  // Character-specific branch
    case imported           // From another user's export file
}

enum ModifierType: String, Codable {
    case static             // Fixed value (e.g., +2)
    case victoryPoints      // Formula-based (e.g., +2 + VP)
}
```

### Effect & EffectModifier Models

**CRITICAL:** Effects support **multiple modifiers** via EffectModifier array. This is essential for complex effects like "Quickening" which modifies multiple stats.

```swift
@Model
class Effect {
    var id: UUID
    var name: String
    var category: String             // e.g., "Psi Power", "Theurgical Ritual", "Maneuver"
    var description: String
    var isActive: Bool

    // Occult effect metadata
    var level: Int?                  // 1-10 for psi/theurgy effects
    var type: String?                // Path (Psi) or Paradigm (Theurgy)
                                     // e.g., "Soma", "Universalist"
    var equipmentType: String?       // For equipment: "melee weapon", "armor", etc.

    // Effects can have multiple modifiers
    var modifiers: [EffectModifier]  // Array of modifiers this effect provides

    // Template reference (optional)
    var template: EffectTemplate?
    var templateScope: TemplateScope

    // Ownership
    var character: Character

    // Future Phase 2A fields (optional, unused in Phase 1)
    var availableModes: [String]?    // Named modes (e.g., ["Aggressive", "Defensive"])
    var mentalActionScaling: Bool?   // Whether modifier scales with mental action input
    var physicalActionCost: Int?     // Physical actions consumed when active
    var conditionalDescription: String?  // Condition for applicability

    init(name: String, category: String, character: Character) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.description = ""
        self.isActive = false
        self.modifiers = []
        self.templateScope = .characterOverride
        self.character = character
    }
}

@Model
class EffectModifier {
    var id: UUID
    var targetStat: String           // Which stat this modifies (e.g., "Attack", "Defense")
    var modifierType: ModifierType

    // For static modifiers
    var staticValue: Int?            // e.g., 2 for "+2 to Defense"

    // For Victory Points modifiers
    var baseBonus: Int?              // e.g., 2 for "+2 + VP"
    var rollAttribute: String?       // e.g., "Introvert"
    var rollSkill: String?           // e.g., "Vigor"

    // Relationship
    var effect: Effect

    init(targetStat: String, modifierType: ModifierType, effect: Effect) {
        self.id = UUID()
        self.targetStat = targetStat
        self.modifierType = modifierType
        self.effect = effect
    }

    func calculateModifier(character: Character) -> Int {
        switch modifierType {
        case .static:
            return staticValue ?? 0
        case .victoryPoints:
            let base = baseBonus ?? 0
            // Assume roll of 8 for sustained effects (Phase 1 standard)
            let attributeValue = character.getStatValue(rollAttribute) ?? 0
            let skillValue = character.getStatValue(rollSkill) ?? 0
            let rollValue = attributeValue + skillValue
            let vp = (rollValue - 8) / 3  // Integer division (rounded down)
            return base + vp
        }
    }
}
```

**Example Usage:**
```swift
// Creating "Quickening" psi effect with multiple modifiers
let quickening = Effect(name: "Quickening", category: "Psi Power", character: character)
quickening.level = 3
quickening.type = "Soma"
quickening.description = "Increases speed and reflexes"

// Modifier 1: +2 to Initiative (static)
let initMod = EffectModifier(targetStat: "Initiative", modifierType: .static, effect: quickening)
initMod.staticValue = 2

// Modifier 2: +1 to Defense (static)
let defMod = EffectModifier(targetStat: "Defense", modifierType: .static, effect: quickening)
defMod.staticValue = 1

// Modifier 3: +2+VP to Dodge (Victory Points)
let dodgeMod = EffectModifier(targetStat: "Dodge", modifierType: .victoryPoints, effect: quickening)
dodgeMod.baseBonus = 2
dodgeMod.rollAttribute = "Introvert"
dodgeMod.rollSkill = "Vigor"

quickening.modifiers = [initMod, defMod, dodgeMod]
```

### Stat Model

```swift
@Model
class Stat {
    var id: UUID
    var name: String
    var baseValue: Int
    var category: String  // "Attribute", "NaturalSkill", "LearnedSkill", "Lore", "Tongue"

    // Template reference (optional)
    var template: StatTemplate?
    var templateScope: TemplateScope

    // Ownership
    var character: Character

    init(name: String, category: String, baseValue: Int, character: Character) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.baseValue = baseValue
        self.templateScope = .characterOverride
        self.character = character
    }

    var effectiveValue: Int {
        let modifierSum = character.activeEffects
            .flatMap { $0.modifiers }
            .filter { $0.targetStat == self.name }
            .map { $0.calculateModifier(character: character) }
            .reduce(0, +)
        return baseValue + modifierSum
    }

    var hasModifiers: Bool {
        character.activeEffects
            .flatMap { $0.modifiers }
            .contains { $0.targetStat == self.name }
    }
}
```

### Metric Model (Calculated Values)

```swift
@Model
class Metric {
    var id: UUID
    var name: String
    var formula: String  // e.g., "Defense = Dexterity + Fight + 3"

    // Ownership
    var character: Character

    init(name: String, formula: String, character: Character) {
        self.id = UUID()
        self.name = name
        self.formula = formula
        self.character = character
    }

    var calculatedBase: Int {
        // Parse formula and calculate from character stats
        // Example: "Defense" might be Dexterity + Fight + 3
        // Implementation depends on formula parsing system
        return 0  // Placeholder
    }

    var effectiveValue: Int {
        let base = calculatedBase
        let modifierSum = character.activeEffects
            .flatMap { $0.modifiers }
            .filter { $0.targetStat == self.name }
            .map { $0.calculateModifier(character: character) }
            .reduce(0, +)
        return base + modifierSum
    }
}
```

### Loadout Model

```swift
@Model
class Loadout {
    var id: UUID
    var name: String
    var activeEffectIDs: Set<UUID>    // Which effects are active
    var equippedGearIDs: Set<UUID>    // Which equipment is equipped
    var createdDate: Date

    // Ownership
    var character: Character

    // Phase 2A will add:
    // var modeSelections: [UUID: String]?       // effectID -> selected mode name
    // var mentalActionAllocations: [UUID: Int]? // effectID -> allocated mental actions

    init(name: String, character: Character) {
        self.id = UUID()
        self.name = name
        self.activeEffectIDs = []
        self.equippedGearIDs = []
        self.createdDate = Date()
        self.character = character
    }

    func apply(to character: Character) {
        // Deactivate all effects
        character.effects.forEach { $0.isActive = false }

        // Activate effects in this loadout
        character.effects
            .filter { activeEffectIDs.contains($0.id) }
            .forEach { $0.isActive = true }
    }

    func captureCurrentState(from character: Character) {
        activeEffectIDs = Set(character.activeEffects.map { $0.id })
        equippedGearIDs = Set(character.equipment.filter { $0.isEquipped }.map { $0.id })
    }
}
```

---

## Template System Protocols

### Core Template Protocol

```swift
protocol CharacterTemplate {
    var id: UUID { get }
    var name: String { get }
    var description: String { get }
    var templateScope: TemplateScope { get }
    var keywords: [String] { get }  // Searchable keywords for rules engine
    var sourceLibraryID: UUID? { get }
    var createdDate: Date { get }
    var modifiedDate: Date { get }
    var version: Int { get }
    var lastModifiedBy: String? { get }  // For import conflict resolution
}

protocol CharacterInstance {
    associatedtype Template: CharacterTemplate
    var id: UUID { get }
    var template: Template? { get }
    var overrideName: String? { get }
    var effectiveName: String { get }
    var templateScope: TemplateScope { get }
}

extension CharacterInstance {
    var effectiveName: String {
        overrideName ?? template?.name ?? "Unnamed"
    }
}
```

### Keyword System Implementation

**IMPORTANT:** Keywords are automatically generated and power the rules engine search.

```swift
protocol KeywordGenerating {
    func generateKeywords() -> [String]
}

extension Effect: KeywordGenerating {
    func generateKeywords() -> [String] {
        var keywords = [name, category]

        // Add level for occult effects
        if let level = level {
            keywords.append(String(level))
        }

        // Add type (Path/Paradigm for occult, equipment type for gear)
        if let type = type {
            keywords.append(type)
        }
        if let equipmentType = equipmentType {
            keywords.append(equipmentType)
        }

        // Add target stats
        keywords.append(contentsOf: modifiers.map { $0.targetStat })

        return keywords
    }
}
```

**Examples:**
- "Quickening" psi effect → `["Quickening", "Psi Power", "3", "Soma", "Initiative", "Defense", "Dodge"]`
- "Longsword" equipment → `["Longsword", "Equipment", "Melee Weapon", "Attack", "Damage"]`
- "La Destreza" maneuver → `["La Destreza", "Armed Combat Maneuver", "Melee", "Attack"]`

---

## Generic Components Pattern

### Generic Template Picker

```swift
struct TemplatePickerView<T: CharacterTemplate>: View {
    let contentType: ContentType
    let availableTemplates: [T]
    let onSelect: (T) -> Void

    @State private var searchText = ""

    var filteredTemplates: [T] {
        if searchText.isEmpty {
            return availableTemplates
        }
        return availableTemplates.filter { template in
            template.keywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        List {
            ForEach(filteredTemplates, id: \.id) { template in
                Button(action: { onSelect(template) }) {
                    VStack(alignment: .leading) {
                        Text(template.name)
                            .font(.headline)
                        Text(template.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search \(contentType.displayName)")
        .navigationTitle("Select \(contentType.displayName)")
    }
}
```

### Content Type Registry

```swift
enum ContentType: String, CaseIterable, Codable {
    // Core Stats
    case attribute
    case naturalSkill
    case learnedSkill
    case lore
    case tongue

    // Effects
    case benefice
    case affliction
    case psiEffect
    case theurgicalRitual

    // Combat & Actions
    case armedCombatManeuver
    case unarmedCombatManeuver
    case rangedCombatManeuver

    // Equipment
    case equipment
    case numinousInvestment

    // Derived Values
    case goalRoll
    case combatMetric

    var displayName: String {
        switch self {
        case .attribute: return "Attributes"
        case .naturalSkill: return "Natural Skills"
        case .learnedSkill: return "Learned Skills"
        case .lore: return "Lores"
        case .tongue: return "Tongues"
        case .benefice: return "Benefices"
        case .affliction: return "Afflictions"
        case .psiEffect: return "Psi Powers"
        case .theurgicalRitual: return "Theurgical Rituals"
        case .armedCombatManeuver: return "Armed Combat Maneuvers"
        case .unarmedCombatManeuver: return "Unarmed Combat Maneuvers"
        case .rangedCombatManeuver: return "Ranged Combat Maneuvers"
        case .equipment: return "Equipment"
        case .numinousInvestment: return "Numinous Investments"
        case .goalRoll: return "Goal Rolls"
        case .combatMetric: return "Combat Metrics"
        }
    }

    var iconName: String {
        switch self {
        case .attribute: return "star.fill"
        case .naturalSkill: return "brain.head.profile"
        case .learnedSkill: return "book.fill"
        case .lore: return "scroll.fill"
        case .tongue: return "bubble.left.and.bubble.right.fill"
        case .benefice: return "plus.circle.fill"
        case .affliction: return "minus.circle.fill"
        case .psiEffect: return "sparkles"
        case .theurgicalRitual: return "flame.fill"
        case .armedCombatManeuver: return "figure.fencing"
        case .unarmedCombatManeuver: return "figure.martial.arts"
        case .rangedCombatManeuver: return "scope"
        case .equipment: return "backpack.fill"
        case .numinousInvestment: return "crown.fill"
        case .goalRoll: return "target"
        case .combatMetric: return "shield.fill"
        }
    }
}
```

---

## SwiftData Relationship Patterns

### Cascade Delete Pattern

```swift
@Model
class Character {
    var id: UUID
    var name: String

    // Relationships with cascade delete
    @Relationship(deleteRule: .cascade, inverse: \Stat.character)
    var stats: [Stat] = []

    @Relationship(deleteRule: .cascade, inverse: \Effect.character)
    var effects: [Effect] = []

    @Relationship(deleteRule: .cascade, inverse: \Loadout.character)
    var loadouts: [Loadout] = []

    var activeEffects: [Effect] {
        effects.filter { $0.isActive }
    }

    func getStatValue(_ statName: String?) -> Int {
        guard let statName = statName else { return 0 }
        return stats.first(where: { $0.name == statName })?.effectiveValue ?? 0
    }
}
```

**WHY:** When a character is deleted, all owned data (stats, effects, loadouts) is automatically deleted. This prevents orphaned data and maintains referential integrity.

### Template Library Pattern

```swift
@Model
class TemplateLibrary {
    var id: UUID
    var name: String
    var scope: TemplateScope
    var importedDate: Date?
    var sourceUser: String?

    @Relationship(deleteRule: .cascade, inverse: \EffectTemplate.library)
    var effectTemplates: [EffectTemplate] = []

    @Relationship(deleteRule: .cascade, inverse: \StatTemplate.library)
    var statTemplates: [StatTemplate] = []

    init(name: String, scope: TemplateScope) {
        self.id = UUID()
        self.name = name
        self.scope = scope
        if scope == .imported {
            self.importedDate = Date()
        }
    }
}
```

---

## Export/Import Patterns

### JSON Structure

```swift
struct ExportFormat: Codable {
    let formatVersion: String
    let exportType: ExportType
    let exportDate: Date
    let creator: String?
    let content: ExportContent

    enum ExportType: String, Codable {
        case templateLibrary
        case character
        case characterCollection
    }

    struct ExportContent: Codable {
        let templates: [TemplateData]?
        let characters: [CharacterData]?
    }
}

struct TemplateData: Codable {
    let type: ContentType
    let id: UUID
    let name: String
    let description: String
    let keywords: [String]
    let version: Int
    let lastModifiedBy: String?
    // Type-specific data as needed
}
```

### Import Conflict Resolution

```swift
enum ImportConflictResolution {
    case replace    // Replace existing with imported
    case skip       // Keep existing, don't import
    case rename     // Import with modified name
}

struct ImportConflict {
    let existingTemplate: CharacterTemplate
    let importedTemplate: TemplateData
    let reason: ConflictReason

    enum ConflictReason {
        case nameMatch
        case idMatch
    }
}
```

---

## Reference from Claude.md

When implementing data models, reference this file for:
- Detailed property definitions
- SwiftData relationship configurations
- Method implementations
- Example usage patterns
- Export/import structures

This keeps Claude.md focused on high-level architecture while providing detailed implementation guidance when needed.
