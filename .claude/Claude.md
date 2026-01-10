# Fading Suns Character Sheet - Project Documentation

## Project Overview

**Fading Suns Character Sheet** is a comprehensive iOS (and eventually macOS) application for managing characters in the Fading Suns tabletop RPG. The app provides character creation, stat tracking, skill management, combat metrics, goal rolls, and extensive customization capabilities.

### Key Differentiators
- **Template-based content system** with three tiers (local, character override, imported/campaign)
- **Highly customizable page layouts** allowing users to design their own character sheets
- **Extensible content framework** supporting 10+ different modifier/effect types
- **Export/import functionality** for sharing templates and characters
- **CloudKit-ready architecture** designed for future multi-user campaign collaboration

## Development Philosophy

This is a **fresh start** rebuild of the application with proper architectural foundations. Previous iterations were built:
- Without comprehensive planning or documentation
- Without consideration of future multi-user/campaign features
- With monolithic views that hit compiler limits (1,500+ line files)
- With hardcoded templates and limited extensibility

This rebuild prioritizes:
- **Architecture first** - Proper planning before implementation
- **Incremental delivery** - Build in phases, test frequently
- **Future-ready design** - Local-first, but CloudKit-ready
- **Maintainability** - Section-based views, clear separation of concerns
- **Extensibility** - Plugin pattern for new content types

## Project Goals & Scope

### Phase 1: Local-First Foundation (16-20 weeks)
**Primary Goal:** Build core character sheet with basic modifiers - architecture ready for complex features

**Strategy:** Start simple, but architect for future complexity. Build the foundation that enables advanced features (modes, conditionals, per-page state) without requiring refactoring.

**Core Features:**
- Character creation and management (duplicate, delete)
- Comprehensive stat tracking (attributes, skills, combat metrics, goal rolls)
- Template system with three tiers:
  - **Local templates** - User's personal library
  - **Character overrides** - Character-specific branches from templates
  - **Imported templates** - Shared libraries from other users (via export/import)
- Export/import functionality for:
  - Template libraries (skills, lores, combat maneuvers, etc.)
  - Individual characters
  - Collections of characters
  - Conflict resolution on import: Replace existing, Skip, or Rename
  - Version tracking and "last modified by User X" metadata
- **Basic effects system:**
  - Effect types: Psi effects, theurgical rituals, combat maneuvers (armed/unarmed/ranged), equipment/gear, numinous investments
  - Simple active/inactive toggles (global state shared across all pages)
  - Two modifier types:
    - **Static modifiers:** Fixed values (e.g., "+2 to Attack", "-1 to Defense")
    - **Victory Points (VP) modifiers:** Formula-based (e.g., "+2 + VP" where VP = (RollValue - 8) / 3, rounded down)
  - Benefices and afflictions (permanent modifiers, no toggles needed)
- **Basic modifier calculation engine:**
  - Calculates effective values (base + all active modifiers)
  - For VP-based effects: Assumes roll of 8 (standard for sustained effects)
  - Shows modifier breakdown in detail view
  - Displays as "base (effective)" when modified, or just "base" when not
- **General Traits display:**
  - Non-numeric effects (Flight, Immunity to wound penalties, etc.)
  - Displayed in dedicated section when effects are active
- **Loadouts system:**
  - Save snapshots of character's current modifier state (active effects, equipped gear, etc.)
  - Quick switching between frequently-used configurations
  - Create, rename, and delete loadouts
  - Foundation for Phase 3 advanced customization features
- **Basic page customization:**
  - Reorder goal rolls and skills within sections (drag handles in edit mode)
  - Show/hide entire sections (toggle switches)
  - Reorder sections (simple drag-to-reorder)
  - Save 2-3 page layouts (different section arrangements)
- Content expansion framework supporting:
  - **Core content types:** Attributes, natural skills, learned skills, lores, tongues, goal rolls, combat metrics
  - **New effect types in Phase 1:** Benefices, afflictions, psi effects (basic), theurgical rituals (basic), combat maneuvers (basic), equipment, numinous investments

**Platform:**
- iOS 17+ (iPhone and iPad)
- SwiftUI + SwiftData
- Local persistence with robust export/import for sharing

**What's Deferred to Phase 2A:**
- ❌ Mode systems:
  - Named modes (e.g., Aggressive/Balanced/Defensive with different modifier sets)
  - Numeric modes (e.g., allocate X mental actions for X-scaled modifiers)
  - Dual-mode effects (combined named + numeric modes)
- ❌ Conditional modifiers (e.g., "+2 when inventing")
- ❌ Per-page state (different active effects on different custom pages)
- ❌ Custom dashboard pages (filtered item subsets) - only section reordering in Phase 1
- ❌ Multiple action penalties system
- ❌ Mental/physical action allocation and budgeting

**Success Criteria:**
- All views under 400 lines (section-based architecture)
- Can add new content types in 3-5 days each
- Export/import works reliably
- App performs well on iPhone SE through iPad Pro
- Data model is CloudKit-ready (proper relationships, ownership patterns)
- **Architecture enables Phase 2 features without refactoring core models**

### Phase 2A: Advanced Effects System (6-8 weeks, future)
**Primary Goal:** Add complex modifier calculations and per-page state management

**Features:**
- **Mode systems:**
  - **Named modes:** Effects with discrete options (e.g., Aggressive/Balanced/Defensive stance)
  - **Numeric modes:** Effects that scale with resource allocation (e.g., X mental actions → +X modifier)
  - **Dual-mode effects:** Some effects combine both (e.g., choose named mode AND allocate mental actions, with each mode producing different X-scaled effects)
  - Per-effect mode selection with different modifier sets per mode
- **Mental action allocation:**
  - Character has total mental action budget (base + modifiers from effects/gear)
  - User allocates mental actions to active occult effects
  - Validation prevents over-allocation
  - Modifiers scale with allocated mental actions
- **Multiple action system:**
  - Character-level mode: 1, 2, or 3 general actions
  - Automatic penalty calculation (-0/-3/-5 for baseline, modified by effects)
  - Effects that reduce multiple action penalties (e.g., La Destreza maneuver)
  - Physical/Mental/General action types with separate budgets
- **Conditional modifiers:**
  - Effects with conditional applicability (e.g., "+2 Tech when inventing")
  - Per-goal-roll toggle for each applicable conditional
  - Global state: toggling ON applies to all goal rolls with that conditional
  - Visual flagging for goal rolls showing conditional-modified values
- **Custom dashboard pages:**
  - Create multiple custom pages (e.g., "Melee Combat", "Ranged Combat", "Social")
  - Each page shows filtered subset of items (selected goal rolls, metrics, etc.)
  - Per-page active state (different effects active on different pages)
  - Per-page mode selections (different configurations per page)
  - Dropdown menus for quick effect toggling on dashboard pages
  - **Visual flagging:** Elements showing non-global state configurations are visually marked (shaded/colored) to indicate they assume different equipment or modes
- **Advanced modifier display:**
  - Full breakdown in detail view showing all contributing effects
  - Separate display for base, permanent modifiers (benefices/afflictions), and toggleable effects
  - Clear indication of mode-dependent and conditional modifiers
- **Loadouts integration:**
  - Loadouts (created in Phase 1) can be assigned per custom page
  - Custom formatted text blocks can reference different loadouts for live stat display
  - Foundation for "word processor"-style custom views with loadout-specific live elements

**Note:** Phase 2A builds directly on Phase 1's modifier engine. The architecture from Phase 1 must enable these features without refactoring core models.

### Phase 2B: Advanced Customization & macOS (6-8 weeks, future)
**Primary Goal:** Full page builder and macOS optimization

**Features:**
- Drag-and-drop page designer (beyond Phase 2A's filtered dashboards)
- Multi-column custom layouts
- Custom styling and formatting options per section
- "Word processor"-style custom views with live elements referencing loadouts
- Multi-window support on macOS
- Keyboard shortcuts and menu bar integration
- Optimized layouts for large screens
- Advanced filtering and organization
- Export/import of custom formatting setups (shareable with other users)

**Note:** Phase 2B builds on Phase 1 & 2A. Initial Phase 1 will support macOS with basic adaptive layouts, but advanced Mac features are deferred.

## Platform Strategy: iOS First, macOS Later

### Initial Release: iOS 17+ (Phase 1)
**iPhone:**
- Single-column layout
- 2-3 predefined page templates
- Essential information prioritized
- Minimal customization (show/hide sections)

**iPad:**
- Two-column layout where appropriate
- Better use of horizontal space
- More sections visible simultaneously
- Moderate customization (section reordering)

**Why iOS First:**
1. Primary audience (most tabletop gamers use phones/tablets at the table)
2. Smaller screens force good information hierarchy decisions
3. Faster development and testing
4. Easier to expand to Mac than compress Mac to iOS

### Future: macOS Support (Phase 3)
**Mac-specific enhancements:**
- NavigationSplitView (sidebar + detail)
- Multi-window support (character list in one window, details in another)
- Full page customization builder
- Keyboard shortcuts
- Menu bar integration
- Unlimited sections/pages (no space constraints)

**Technical approach:**
- Same SwiftUI codebase
- Use `#if os(macOS)` for platform-specific UI
- Environment size classes for responsive layouts
- Separate view modifiers for Mac vs iOS behavior

## Technical Architecture

### Tech Stack
- **Language:** Swift 5.10+
- **UI Framework:** SwiftUI (iOS 17+)
- **Persistence:** SwiftData
- **Minimum Target:** iOS 17.0
- **Platforms:** iOS (iPhone, iPad), future macOS 14+

### Data Model Principles

**Core Concepts:**
1. **Character** - Root aggregate owning all related data
2. **Stat** - Parent type for all user-defined base values (Attributes, Natural Skills, Learned Skills, Lores, Tongues)
   - All Stats have: `baseValue` + `modifiers` → `effectiveValue`
3. **Metric** - Calculated values with formula-based base (e.g., Defense, Initiative, Hit Points)
   - No user-defined base; calculated from constants + modifiers
4. **Effect** - Modifiers that can be active/inactive (Psi effects, gear, maneuvers, etc.)
   - Two types: Static modifiers (+2) or Victory Points modifiers (+2 + VP)
5. **Loadout** - Saved snapshot of character's modifier state (active effects, equipped gear, modes)
6. **Template** - Reusable definitions for skills, effects, etc.
7. **Library** - Container for templates (local or imported)

**Relationship Patterns:**
- **Cascade delete** - Deleting character deletes all owned data
- **Explicit inverses** - All relationships have `inverse:` parameter (SwiftData best practice)
- **Optional relationships** - Templates are optional (character can have override-only instances)
- **Ownership tracking** - Every template has a `templateScope` indicating local vs imported
- **Version tracking** - Templates and characters track version and "last modified by" metadata for import conflict resolution

**Future-Ready Design Philosophy:**

Even though Phase 1 implements simple features, data models must support Phase 2A complexity without refactoring:

**CloudKit-Ready (Phase 2B):**
- No unsupported types (only String, Int, Double, Bool, Date, Data, UUID)
- Relationships use CloudKit-compatible patterns
- Unique identifiers for all entities
- Owner/creator tracking (even if not used in Phase 1)
- Audit fields (createdDate, modifiedDate) for future sync

**Phase 2A-Ready (Advanced Effects):**
- Effect models include optional fields for modes (unused in Phase 1, populated in Phase 2A):
  - `availableModes: [String]?` - Named modes (e.g., ["Attack", "Balanced", "Defensive"])
  - `mentalActionScaling: Bool?` - Whether modifier scales with mental action input
  - `conditionalDescription: String?` - Condition for applicability (e.g., "when inventing")
- Modifier calculations use extensible pattern (can add conditional logic later)
- CustomPage model exists in Phase 1 (stores section order) but gains per-page state in Phase 2A
- Character model includes action budget fields (general/physical/mental) even if unused in Phase 1

**Key Principle:** Add optional fields now, populate them later. Avoids breaking changes and data migrations.

**Data Model Hierarchy:**

```
┌─────────────────────────────────────────────────┐
│                  Character                       │
│  - name, description                            │
│  - loadouts: [Loadout]                          │
└──────────────────┬──────────────────────────────┘
                   │
      ┌────────────┼────────────┬─────────────┐
      ▼            ▼            ▼             ▼
   Stats       Metrics      Effects      GoalRolls
   (Stat)      (Metric)     (Effect)
      │                         │
      ├── Attribute             ├── Psi Effect
      ├── NaturalSkill          ├── Ritual
      ├── LearnedSkill          ├── Maneuver
      ├── Lore                  ├── Equipment
      └── Tongue                └── Numinous Investment

      All reference templates (optional):
                  ▼
         TemplateLibrary
         (Local or Imported)
```

**Three-Tier Template System:**

1. **Local Templates** (scope: `.local`)
   - User's personal library
   - Created by user in-app
   - Stored in user's local database
   - Can be exported to share with others

2. **Character Overrides** (scope: `.characterOverride`)
   - Character-specific branch from template
   - Not saved back to any library
   - Exists only for that character
   - Example: Character has "Dodge +2" while template says "Dodge"

3. **Imported Templates** (scope: `.imported`)
   - Imported from another user's export file
   - Read-only reference (can't edit original)
   - Can create character override to branch from imported template
   - Tracked with version and "last modified by User X" metadata

**Implementation Pattern:**
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

@Model
class Effect {
    var name: String
    var modifierType: ModifierType
    var isActive: Bool

    // For static modifiers
    var staticValue: Int?

    // For Victory Points modifiers
    var baseBonus: Int?              // e.g., 2 for Quickening
    var rollAttribute: String?       // e.g., "Introvert"
    var rollSkill: String?           // e.g., "Vigor"

    // Future Phase 2A fields (optional, unused in Phase 1)
    var availableModes: [String]?    // Named modes
    var mentalActionScaling: Bool?   // Numeric scaling
    var conditionalDescription: String?

    func calculateModifier(character: Character) -> Int {
        switch modifierType {
        case .static:
            return staticValue ?? 0
        case .victoryPoints:
            let base = baseBonus ?? 0
            // Assume roll of 8 for sustained effects
            let rollValue = character.getStatValue(rollAttribute) +
                            character.getStatValue(rollSkill)
            let vp = (rollValue - 8) / 3  // Integer division (rounded down)
            return base + vp
        }
    }
}

@Model
class Stat {
    var name: String
    var baseValue: Int
    var character: Character

    var effectiveValue: Int {
        let modifiers = character.activeEffects
            .filter { $0.appliesTo(stat: self) }
            .map { $0.calculateModifier(character: character) }
            .reduce(0, +)
        return baseValue + modifiers
    }
}

@Model
class Loadout {
    var name: String
    var activeEffectIDs: Set<UUID>    // Which effects are active
    var equippedGearIDs: Set<UUID>    // Which equipment is equipped
    // Phase 2A will add mode selections, mental action allocations
}
```

### View Architecture Principles

**Section-Based Organization:**
All detail views must be broken into logical sections, each in its own file.

**Example: CharacterDetailView**
```
CharacterDetailView.swift (< 400 lines)
├── CharacterInfoSection.swift (~100 lines)
├── AttributesSection.swift (~150 lines)
├── SkillsSection.swift (~200 lines)
├── GoalRollsSection.swift (~150 lines)
├── CombatMetricsSection.swift (~100 lines)
└── TraitsSection.swift (~80 lines)
```

**Rules:**
- **Main detail view** < 400 lines (coordinator, state management, modifiers)
- **Section files** < 250 lines each
- **Reusable components** < 150 lines (StatCell, SkillRow, etc.)
- **Edit views** < 200 lines

**Component Hierarchy:**
```
View
├── Section (logical grouping, e.g., "Skills")
│   ├── Row (individual item, e.g., "Dodge")
│   │   └── Cell (atomic UI, e.g., value stepper)
│   └── Header/Footer
└── Modifiers (alerts, sheets, navigation)
```

**State Management:**
- **@State** - Local view state (UI-only, doesn't persist)
- **@Bindable** - Direct binding to SwiftData models (for edits)
- **@Query** - Fetching data from SwiftData
- **@Environment(\.modelContext)** - Database operations (insert, delete)
- **No ViewModels in Phase 1** - Keep it simple, views talk directly to models
- **Phase 2 consideration** - May introduce ViewModels for sync/conflict handling

### Content Expansion Framework

**Goal:** Add new content types (benefices, rituals, equipment, etc.) in 3-5 days each, not 2-3 weeks.

**Strategy:**
1. **Template Protocol** - All templates conform to common protocol
2. **Generic Components** - Reusable UI for template-based content
3. **Type Registry** - Central registration of content types
4. **Formula Engine** - Shared calculation system for effects/modifiers

**Template Protocol Example:**
```swift
protocol CharacterTemplate {
    var name: String { get }
    var templateScope: TemplateScope { get }
    var keywords: [String] { get }
    var sourceLibraryID: UUID? { get }
}

protocol CharacterInstance {
    associatedtype Template: CharacterTemplate
    var template: Template? { get }
    var overrideName: String? { get }
    var effectiveName: String { get }
}
```

**Generic Template Picker:**
```swift
struct TemplatePickerView<T: CharacterTemplate>: View {
    let availableTemplates: [T]
    let onSelect: (T) -> Void

    // Generic picker works for any template type
}
```

**Content Type Registry:**
```swift
enum ContentType: String, CaseIterable {
    case attribute, naturalSkill, learnedSkill, lore, tongue
    case benefice, affliction, psiEffect, theurgicalRitual
    case armedCombatManeuver, unarmedCombatManeuver, rangedCombatManeuver
    case equipment, numinousInvestment
    case goalRoll, combatMetric

    var displayName: String { /* ... */ }
    var iconName: String { /* ... */ }
}
```

**Adding New Content Type (Example: Benefices):**
1. Create `BeneficeTemplate` model (conform to `CharacterTemplate`)
2. Create `CharacterBenefice` model (conform to `CharacterInstance`)
3. Add to `ContentType` enum
4. Create `BeneficeSection` view (copy pattern from `SkillsSection`)
5. Add section to `CharacterDetailView`
6. Add to export/import logic
7. Done! (3-5 days of work)

### Export/Import System

**Purpose:** Share templates and characters without requiring CloudKit/iCloud.

**Format:** JSON files with `.fstemplate` or `.fscharacter` extensions

**Export Capabilities:**
1. **Template Library Export** (`.fstemplate`)
   - All skills, lores, tongues, etc. from user's library
   - Can export entire library or filtered subset
   - Includes metadata (creator, created date, version)

2. **Character Export** (`.fscharacter`)
   - Complete character with all stats, skills, rolls, etc.
   - Includes embedded template data (for templates with overrides)
   - Can export single character or multiple

**Import Behavior:**
1. **Import Template Library:**
   - Templates imported with `templateScope = .imported`
   - Name conflicts: Offer to rename or skip
   - Track `sourceLibraryID` for provenance

2. **Import Character:**
   - Character's templates are imported as `.imported` scope
   - Character's overrides preserved as `.characterOverride`
   - User becomes local owner of imported character

**File Format Structure:**
```json
{
  "formatVersion": "1.0",
  "exportType": "templateLibrary",
  "exportDate": "2026-01-09T10:30:00Z",
  "creator": "Optional Creator Name",
  "templates": [
    {
      "type": "skill",
      "name": "Dodge",
      "category": "Combat",
      "keywords": ["defense", "agility"],
      "description": "Avoid attacks"
    }
  ]
}
```

**UI Integration:**
- Share sheet for exports (standard iOS share)
- Document picker for imports
- Preview before importing (show what will be added)
- Undo support for imports (in case of mistakes)

## Development Workflow

### Planning Process
1. **Architecture docs first** (this file + rules.md)
2. **Plan Mode for major features** - Use Claude Code's Plan Mode to design implementation before coding
3. **Incremental implementation** - Build one section/feature at a time
4. **Test after each increment** - Verify functionality before moving on
5. **Commit frequently** - Small, focused commits with clear messages

### Code Organization
```
CharacterSheet/
├── App/
│   ├── CharacterSheetApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Character/
│   │   ├── RPGCharacter.swift
│   │   ├── Stat.swift
│   │   └── CharacterSkill.swift
│   ├── Templates/
│   │   ├── TemplateProtocol.swift
│   │   ├── SkillTemplate.swift
│   │   └── TemplateLibrary.swift
│   └── Export/
│       └── ExportFormat.swift
├── Views/
│   ├── CharacterList/
│   │   └── CharacterListView.swift
│   ├── CharacterDetail/
│   │   ├── CharacterDetailView.swift
│   │   └── Sections/
│   │       ├── CharacterInfoSection.swift
│   │       ├── AttributesSection.swift
│   │       ├── SkillsSection.swift
│   │       └── ...
│   └── Components/
│       ├── StatCell.swift
│       ├── SkillRow.swift
│       └── TemplatePickerView.swift
├── Services/
│   ├── ExportService.swift
│   └── ImportService.swift
└── Utilities/
    ├── FormulaEngine.swift
    └── Extensions/
```

### Git Workflow
- **Main branch** - Stable, deployable code
- **Feature branches** - `claude/feature-name-SESSION_ID`
- **Commit messages** - Follow convention: "Add X", "Fix Y", "Refactor Z"
- **Push after each working feature** - Keep remote in sync

### Testing Strategy (Phase 1)
- Manual testing in iOS Simulator (iPhone SE, iPhone 15, iPad Pro)
- Export/import validation (round-trip testing)
- Data migration testing (if models change)
- Phase 2+ will add unit tests for sync/conflict logic

## Key Design Decisions

### Decision: Local-First with Export/Import
**Rationale:** Export/import provides robust sharing functionality without the complexity of real-time sync. Users can share characters, templates, and custom formatting setups via files. Version tracking and conflict resolution on import provides sufficient collaboration support.

### Decision: iOS First, macOS Later
**Rationale:** Mobile is primary use case (at the gaming table). Small screens force good design decisions. Expanding to Mac is easier than compressing Mac to iOS.

### Decision: Section-Based Views, Not Monolithic
**Rationale:** Previous 1,500-line view hit compiler limits and was unmaintainable. Section-based architecture keeps files small, testable, and reusable.

### Decision: Template Protocol Pattern for Content Expansion
**Rationale:** Need to support 10+ content types. Hardcoding each type individually would result in massive code duplication. Protocol + generics allows adding new types in days, not weeks.

### Decision: JSON Export Format, Not Proprietary Binary
**Rationale:** JSON is human-readable, debuggable, and extensible. Easy to version and migrate. Users can manually edit exports if needed.

### Decision: No ViewModels in Phase 1
**Rationale:** SwiftUI + SwiftData work well together with @Bindable. ViewModels add complexity without clear benefit for local-only app. May add in Phase 2 for sync orchestration.

## Success Metrics

**Phase 1 Complete When:**
- [ ] All character functionality working (create, edit, delete, duplicate)
- [ ] All content types implemented (stats, skills, rolls, combat, + 3 new types)
- [ ] Export/import working reliably
- [ ] All views under 400 lines
- [ ] App runs smoothly on iPhone SE through iPad Pro
- [ ] No compiler errors or warnings
- [ ] Data model validated as CloudKit-ready
- [ ] User can create custom template library and share with others

**Quality Bars:**
- Build time < 30 seconds
- App launch < 2 seconds
- Smooth scrolling (60fps) in character detail view
- Zero data loss scenarios
- Graceful handling of import errors

## Future Considerations (Not Phase 1)

### Additional Future Features
- Dice rolling integration
- Character portraits and images
- PDF export
- Print layouts

### Detailed Actions System (Phase 2A Feature)

**Purpose:** Characters have limited actions per turn. Using multiple actions incurs global penalties.

**Action Types:**
- **General Actions** - Can be used for any action type (physical, mental, social, etc.)
- **Physical Actions** - Bonus actions specifically for physical tasks
- **Mental Actions** - Bonus actions specifically for mental/occult tasks

**Multiple Action Penalties:**
```
Baseline Character (1 general action):
- 1 action:  -0 global modifier
- 2 actions: -3 global modifier
- 3 actions: -5 global modifier

With Effects/Gear:
- Some maneuvers reduce penalties (e.g., La Destreza: if one action is melee, penalties become -0/-3 instead of -0/-3/-5)
- Some effects add bonus actions (e.g., "+1 Physical Action" allows 2 physical + 1 general at -0)
```

**Physical Actions:**
- Baseline character: 0 physical actions (must use general actions for physical tasks)
- Effects/gear can grant additional physical actions (e.g., "+1 Physical Action")
- **Action-consuming maneuvers:** Some maneuvers cost physical actions when declared active
  - Example: Maneuver costs 1 physical action but provides +2 to Attack rolls
  - User declares active at beginning of turn → loses 1 physical action, gains modifier
  - Budget must account for both bonus actions granted AND actions consumed by active maneuvers

**Mental Actions:**
- Baseline character: 0 mental actions (must use general actions for occult effects)
- Effects/gear can grant additional mental actions (e.g., "+2 Mental Actions")
- Character allocates mental actions among active occult effects
- **Budget enforcement:** System prevents allocating more mental actions than available

**Implementation Requirements:**
1. Character has base action values (general=1, physical=0, mental=0 by default)
2. Effects/gear modify action budgets ("+1 Physical Action", "+2 Mental Actions")
3. Character-level mode selection: Using 1, 2, or 3 general actions this turn
4. Multiple action penalty automatically applied based on mode and active effects
5. Mental action allocation UI with validation (can't exceed available)
6. Real-time recalculation when effects activated/deactivated

**Example Scenario:**
```
Character Stats:
- Base: 1 general, 0 physical, 0 mental
- Equipped: Powered Armor (+1 Physical Action)
- Active: Psi Training (+2 Mental Actions)
- Total: 1 general, 1 physical, 2 mental

Turn Configuration:
- Using: 3 general actions (penalty: -5)
- Active maneuver: La Destreza (one action is melee, reduces penalty to -3)
- Mental allocation: 2 actions to "Psi Shield" effect

Result:
- Can perform 3 general + 1 physical + 2 mental actions
- Global modifier: -3 (instead of -5, due to La Destreza)
- Psi Shield active with 2 mental actions allocated (modifier scales with input)
```

## Questions & Decisions Needed

### Open Questions
*(To be filled in during development)*

### Decision Log
*(Track major decisions made during implementation)*

## References & Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)

## Revision History

- 2026-01-09: Initial documentation created for fresh start rebuild
