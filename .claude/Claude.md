# Fading Suns Character Sheet - Phase 1 Documentation

## 🎯 CRITICAL: Current Phase Focus

**YOU MUST focus exclusively on Phase 1 (Local-First Foundation) features.**

Phase 2A/2B features are documented in `.claude/future-phases.md` for architectural context only—**do NOT implement them yet.** Data models include optional fields for Phase 2A (unused in Phase 1) to avoid future refactoring.

---

## Project Overview

**Fading Suns Character Sheet** is a comprehensive iOS application for managing characters in the Fading Suns tabletop RPG. The app provides character creation, stat tracking, skill management, combat metrics, goal rolls, equipment/gear management, combat maneuvers, occult effects (psi powers and theurgical rituals), and extensive customization capabilities.

### Key Differentiators

- **Template-based content system** with three tiers (local, character override, imported)
- **Victory Points modifier system** for formula-based effect calculations
- **Loadouts** for saving and switching between character configurations
- **Highly customizable page layouts** - character sheets, quick reference sheets, and stat blocks
  - Mini word processing environment with live stat elements
  - Multiple text blocks with different loadouts for side-by-side comparison
- **Extensible content framework** supporting 10+ different modifier/effect types
- **Robust export/import functionality** for sharing templates and characters

---

## WHY This Fresh Start Matters

**Previous iterations failed due to:**
- No comprehensive planning or documentation
- Monolithic views (1,500+ line files) that hit compiler limits and 60+ second build times
- Hardcoded templates with no extensibility
- No consideration of future multi-user/campaign features

**WHY THIS APPROACH SUCCEEDS:**
- **Architecture first** - Proper planning prevents refactoring later
- **Future-ready design** - Phase 1 data models support Phase 2A/2B without breaking changes
- **Maintainable code** - Section-based views (<400 lines) enable fast builds and parallel development
- **Extensible patterns** - Adding new content types takes 3-5 days, not 2-3 weeks

---

## Phase 1: Core Requirements (16-20 weeks)

**Primary Goal:** Build core character sheet with basic modifiers—architecture ready for complex features

### Character Management

- Main character list page (create, duplicate, delete, edit)
- **IMPORTANT: Template library management interface** (accessed from main page):
  - Export/import template libraries
  - Review, rename, edit, and delete templates
  - Libraries organized by element type (skills, lores, tongues, maneuvers, psi/theurgy, equipment, etc.)

### Stats & Metrics

**YOU MUST implement the three-tier hierarchy:**

1. **Stats** (user-defined base values):
   - Attributes, Natural Skills, Learned Skills, Lores, Tongues
   - Formula: `baseValue` + `modifiers` → `effectiveValue`
   - Display format: "base (effective)" when modified, "base" when not

2. **Metrics** (calculated values):
   - Defense, Initiative, Hit Points, etc.
   - Formula-based base (e.g., Defense = Dexterity + Fight + 3)
   - No user-defined base; calculated from constants + modifiers

3. **Goal Rolls** (attribute + skill combinations):
   - Display combined roll values
   - Show modifier breakdown

### Effects System

**CRITICAL: Effects support multiple modifiers** via `EffectModifier` array.

**Effect Types:**
- Psi effects, theurgical rituals, combat maneuvers (armed/unarmed/ranged)
- Equipment/gear, benefices, afflictions, numinous investments

**Modifier Types:**
- **Static modifiers:** Fixed values (e.g., "+2 to Defense")
- **Victory Points (VP) modifiers:** Formula-based (e.g., "+2 + VP")

**WHY THIS MATTERS:** Victory Points formula (`VP = (RollValue - 8) / 3`, rounded down) is core to Fading Suns mechanics. Many effects depend on this calculation. For sustained effects, assume roll of 8.

**Occult Effect Metadata:**
- `level: Int?` (1-10 for psi/theurgy)
- `type: String?` (Path for Psi, Paradigm for Theurgy)
- `equipmentType: String?` (melee weapon, armor, etc.)

### Template System

**YOU MUST use three-tier system for ALL content types:**

1. **Local templates** - User's personal library (scope: `.local`)
2. **Character overrides** - Character-specific branches (scope: `.characterOverride`)
3. **Imported templates** - From other users' export files (scope: `.imported`)

**WHY:** This architecture enables Phase 2B community features without refactoring.

### Loadouts

- Save snapshots of character's current state (active effects, equipped gear)
- Quick switching between configurations
- Create, rename, delete loadouts
- Foundation for Phase 2A advanced features (modes, per-page state)

### Export/Import

**Export:** Template libraries (`.fstemplate`), individual characters (`.fscharacter`), character collections
**Import:** Conflict resolution (Replace/Skip/Rename), version tracking, "last modified by" metadata
**Format:** JSON (human-readable, debuggable, extensible)

### Keyword System (Rules Engine Support)

**IMPORTANT:** Keywords are automatically generated and include:
- name (always), category (always), subcategories (if applicable)
- level (for occult effects: 1-10)
- type (Path/Paradigm for occult; equipment type for gear)

**Examples:**
- "Quickening" psi effect → `["Quickening", "Psi Power", "Soma", "3"]`
- "Longsword" equipment → `["Longsword", "Equipment", "Melee Weapon"]`

### Basic Page Customization

- Reorder goal rolls and skills within sections (drag handles in edit mode)
- Show/hide entire sections (toggle switches)
- Reorder sections (drag-to-reorder)
- Save 2-3 page layouts (different section arrangements)

**Phase 2A adds:** Custom dashboard pages with per-page state, conditionals, mode systems
(See `.claude/future-phases.md` for details—DO NOT implement in Phase 1)

---

## Data Model Principles

**CRITICAL: Architecture must support Phase 2A/2B without refactoring.**

### Core Concepts

1. **Character** - Root aggregate owning all related data
2. **Stat** - Parent type for user-defined base values (Attributes, Skills, Lores, Tongues)
3. **Metric** - Calculated values (Defense, Initiative, Hit Points)
4. **Effect** - Modifiers that can be active/inactive (psi, gear, maneuvers, etc.)
5. **EffectModifier** - Individual modifier within an effect (multiple per effect)
6. **Loadout** - Saved snapshot of character state
7. **Template** - Reusable definitions for content
8. **Library** - Container for templates (local or imported)

### Relationships

- **Cascade delete:** Deleting character deletes all owned data
- **Explicit inverses:** All relationships have `inverse:` parameter (SwiftData best practice)
- **Optional templates:** Character instances can be override-only (no template reference)
- **Ownership tracking:** `templateScope` field indicates local/override/imported
- **Version tracking:** `version` and `lastModifiedBy` fields for import conflict resolution

### Future-Ready Design

**YOU MUST include Phase 2A optional fields (unused in Phase 1):**

```swift
@Model
class Effect {
    // Phase 1 fields (use these)
    var name: String
    var category: String
    var level: Int?
    var type: String?
    var isActive: Bool
    var modifiers: [EffectModifier]  // Multiple modifiers per effect!

    // Phase 2A fields (DO NOT USE in Phase 1, but must exist)
    var availableModes: [String]?
    var mentalActionScaling: Bool?
    var conditionalDescription: String?
}
```

**WHY:** Adding fields now prevents data migrations and refactoring later.

**See `.claude/implementation-patterns.md` for detailed code examples.**

---

## View Architecture

**CRITICAL: All views MUST be under 400 lines. Previous 1,500-line views hit compiler limits and were unmaintainable.**

### File Size Limits (NON-NEGOTIABLE)

- **Main detail view** < 400 lines
- **Section files** < 250 lines each
- **Reusable components** < 150 lines
- **Edit views** < 200 lines

**WHY THIS MATTERS:**
- Previous monolithic views caused 60+ second build times
- Impossible code reviews and constant merge conflicts
- No reusability across views
- Section-based architecture cuts build time by 80%

### Section-Based Pattern

```
CharacterDetailView.swift (< 400 lines)
├── CharacterInfoSection.swift (~100 lines)
├── AttributesSection.swift (~150 lines)
├── SkillsSection.swift (~200 lines)
├── GoalRollsSection.swift (~150 lines)
├── CombatMetricsSection.swift (~100 lines)
└── TraitsSection.swift (~80 lines)
```

### State Management

- **@State** - Local view state (UI-only, doesn't persist)
- **@Bindable** - Direct binding to SwiftData models (for edits)
- **@Query** - Fetching data from SwiftData
- **@Environment(\.modelContext)** - Database operations (insert, delete)
- **No ViewModels in Phase 1** - Keep it simple, views talk directly to models

---

## Content Expansion Framework

**Goal:** Add new content types (benefices, rituals, equipment) in **3-5 days each**, not 2-3 weeks.

### Strategy

1. **Template Protocol** - All templates conform to common protocol
2. **Generic Components** - Reusable UI for template-based content
3. **Type Registry** - Central registration of content types (`ContentType` enum)
4. **Formula Engine** - Shared calculation system for effects/modifiers

**See `.claude/implementation-patterns.md` for detailed patterns.**

---

## Key Architectural Decisions

### Local-First with Export/Import

**WHY:** Export/import provides robust sharing without real-time sync complexity. Version tracking and conflict resolution on import provides sufficient collaboration support. CloudKit would add 40-50% to timeline.

**IMPACT:** Users can share characters, templates, and custom formatting setups via files. No internet dependency. Full control over data.

### iOS First, macOS Later

**WHY:** Mobile is primary use case (at the gaming table). Small screens force good information hierarchy decisions. Expanding to Mac is easier than compressing Mac to iOS.

**IMPACT:** Faster Phase 1 delivery. Better mobile experience. Phase 2B adds Mac features.

### Section-Based Views, Not Monolithic

**WHY:** Previous 1,500-line view caused compiler errors, 60+ second builds, impossible code reviews, and merge conflicts on every feature.

**IMPACT:** Section-based architecture cuts build time by 80%, enables parallel development, and makes code reviewable.

### Template Protocol Pattern for Content Expansion

**WHY:** Need to support 10+ content types. Hardcoding each type would result in massive code duplication.

**IMPACT:** Protocol + generics allows adding new types in 3-5 days instead of 2-3 weeks.

### JSON Export Format, Not Proprietary Binary

**WHY:** JSON is human-readable, debuggable, extensible, and easy to version. Users can manually edit exports if needed.

**IMPACT:** Easier troubleshooting. Better long-term maintainability. Community can create tools.

---

## Code Organization

```
CharacterSheet/
├── App/
│   ├── CharacterSheetApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Character/
│   │   ├── RPGCharacter.swift
│   │   ├── Stat.swift
│   │   ├── Effect.swift
│   │   └── Loadout.swift
│   ├── Templates/
│   │   ├── TemplateProtocol.swift
│   │   ├── StatTemplate.swift
│   │   ├── EffectTemplate.swift
│   │   └── TemplateLibrary.swift
│   └── Export/
│       └── ExportFormat.swift
├── Views/
│   ├── CharacterList/
│   │   └── CharacterListView.swift
│   ├── CharacterDetail/
│   │   ├── CharacterDetailView.swift
│   │   └── Sections/
│   │       ├── AttributesSection.swift
│   │       ├── SkillsSection.swift
│   │       └── ...
│   └── Components/
│       ├── StatCell.swift
│       └── TemplatePickerView.swift
├── Services/
│   ├── ExportService.swift
│   └── ImportService.swift
└── Utilities/
    └── FormulaEngine.swift
```

---

## Git Workflow

- **Main branch:** Stable, deployable code
- **Feature branches:** `claude/feature-name-SESSION_ID`
- **Commit messages:** "Add X", "Fix Y", "Refactor Z"
- **Push frequently:** Keep remote in sync after each working feature

---

## Success Criteria (Phase 1)

See `.claude/phase1-checklist.md` for detailed testable criteria.

**Phase 1 Complete When:**
- [ ] All character functionality working (create, edit, delete, duplicate)
- [ ] All content types implemented (stats, skills, rolls, combat, effects, gear, loadouts)
- [ ] Export/import working reliably with conflict resolution
- [ ] **All views under 400 lines** (CRITICAL)
- [ ] App performs well on iPhone SE through iPad Pro
- [ ] Data model validated as Phase 2A-ready (no refactoring needed)
- [ ] User can create custom template library and share with others

**Quality Bars:**
- Build time < 30 seconds
- App launch < 2 seconds
- Smooth scrolling (60fps) in character detail view
- Zero data loss scenarios

---

## Reference Documentation

**IMPORTANT:** Reference these files during development, but they are NOT loaded automatically:

- **`.claude/rules.md`** - Coding standards and SwiftUI/SwiftData best practices
- **`.claude/implementation-patterns.md`** - Detailed code examples and patterns
- **`.claude/future-phases.md`** - Phase 2A/2B features (DO NOT implement yet)
- **`.claude/phase1-checklist.md`** - Testable success criteria

---

## Tech Stack

- **Language:** Swift 5.10+
- **UI Framework:** SwiftUI (iOS 17+)
- **Persistence:** SwiftData
- **Minimum Target:** iOS 17.0
- **Platforms:** iOS (iPhone, iPad); Phase 2B adds macOS 14+

---

## Working with This Project

**IMPORTANT: When exploring the codebase:**
- Use Task tool with `subagent_type=Explore` (not direct Grep/Glob)
- This preserves context budget for implementation work

**CRITICAL: Before implementing any feature:**
1. **Read existing related files FIRST**
2. Understand current patterns before modifying
3. **NEVER propose changes to code you haven't read**

**WHY:** Ad-hoc exploration consumes 2-3x more tokens than targeted exploration. Token budget preservation enables deeper implementation work.

---

## Revision History

- 2026-01-09: Initial documentation created for fresh start rebuild
- 2026-01-10: Compressed to 150-200 lines with emphasis markers; moved Phase 2A/2B to future-phases.md; moved code examples to implementation-patterns.md; added WHY motivational context
