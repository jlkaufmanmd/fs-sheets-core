# Phase 1 Success Checklist

**Purpose:** Testable success criteria for Phase 1 completion. Use this checklist to validate that Phase 1 is complete before moving to Phase 2A.

**IMPORTANT:** ALL criteria must be met before Phase 1 is considered complete.

---

## Core Functionality

### Character Management
- [ ] Create new character with name and description
- [ ] Edit existing character (name, description, stats)
- [ ] Delete character (with confirmation)
- [ ] Duplicate character (creates independent copy)
- [ ] Character list view shows all characters
- [ ] Character detail view displays all character data

### Stats & Metrics
- [ ] **Attributes** - User can define base values (e.g., Strength: 5)
- [ ] **Natural Skills** - User can define base values
- [ ] **Learned Skills** - User can define base values
- [ ] **Lores** - User can define base values
- [ ] **Tongues** - User can define base values
- [ ] **Metrics** - Calculated values display correctly (Defense, Initiative, Hit Points)
- [ ] **Goal Rolls** - Display attribute + skill combinations
- [ ] All stats show "base (effective)" format when modifiers active
- [ ] All stats show just "base" when no modifiers active

### Effects System
- [ ] **Psi Effects** - Can create, edit, delete
- [ ] **Theurgical Rituals** - Can create, edit, delete
- [ ] **Combat Maneuvers** - Can create, edit, delete (armed/unarmed/ranged)
- [ ] **Equipment/Gear** - Can create, edit, delete
- [ ] **Benefices** - Can create, edit, delete (permanent modifiers)
- [ ] **Afflictions** - Can create, edit, delete (permanent negative modifiers)
- [ ] **Numinous Investments** - Can create, edit, delete
- [ ] Effects can be toggled active/inactive
- [ ] **Multiple modifiers per effect** - Single effect can modify multiple stats
- [ ] **Static modifiers** - Fixed value modifiers work correctly (e.g., +2 to Defense)
- [ ] **Victory Points modifiers** - Formula-based modifiers work correctly (e.g., +2 + VP)
- [ ] VP calculation uses assumed roll of 8 for sustained effects
- [ ] VP calculation: VP = (RollValue - 8) / 3, rounded down
- [ ] Active effects correctly modify stat effective values
- [ ] Modifier breakdown visible in detail views

### Occult Effect Metadata
- [ ] **Level** - 1-10 range supported for psi/theurgy effects
- [ ] **Type** - Path (Psi) or Paradigm (Theurgy) tracked correctly
- [ ] Metadata displays in effect detail views
- [ ] Metadata included in export/import

### Equipment Metadata
- [ ] **Equipment Type** - Type tracking (melee weapon, armor, etc.)
- [ ] Equipment can be marked as equipped/unequipped
- [ ] Equipment metadata displays correctly

### Loadouts System
- [ ] Create new loadout with name
- [ ] Capture current state (active effects, equipped gear)
- [ ] Apply loadout to character (restores saved state)
- [ ] Rename loadout
- [ ] Delete loadout
- [ ] Switch between loadouts smoothly

### Template System
- [ ] **Local templates** - Create personal template library
- [ ] **Character overrides** - Character-specific branches from templates
- [ ] **Imported templates** - Import templates from other users
- [ ] Templates support all content types (stats, effects, gear, maneuvers, etc.)
- [ ] Template picker shows available templates by type
- [ ] Character instances reference template correctly
- [ ] Override names work correctly (character name overrides template name)

### Template Library Management (Main Page)
- [ ] Template library interface accessible from main character list page
- [ ] Libraries organized by element type (skills, lores, tongues, maneuvers, psi/theurgy, equipment)
- [ ] Export template library to file
- [ ] Import template library from file
- [ ] Review templates in library (browsable list)
- [ ] Rename templates
- [ ] Edit templates
- [ ] Delete templates (with confirmation)
- [ ] Remove templates with errors or obsolete entries

### Export/Import System
- [ ] **Export single character** - Generates `.fscharacter` file
- [ ] **Export multiple characters** - Collection export works
- [ ] **Export template library** - Generates `.fstemplate` file
- [ ] **Import character** - Loads from `.fscharacter` file
- [ ] **Import template library** - Loads from `.fstemplate` file
- [ ] **Conflict resolution** - Name conflicts offer Replace/Skip/Rename options
- [ ] **Version tracking** - Templates track version number
- [ ] **Last modified by** - Templates track last modifier
- [ ] Exported files are valid JSON
- [ ] Imported data validates before insertion
- [ ] Round-trip testing: Export → Import produces identical character
- [ ] Import preserves character overrides correctly
- [ ] Import handles template scope correctly (imported templates marked as `.imported`)

### Keyword System
- [ ] Keywords automatically generated for all templates
- [ ] Keywords include: name, category
- [ ] Keywords include subcategories (if applicable)
- [ ] Keywords include level (for occult effects)
- [ ] Keywords include type (Path/Paradigm for occult, equipment type for gear)
- [ ] Search/filter by keywords works correctly
- [ ] Example: "Quickening" → ["Quickening", "Psi Power", "Soma", "3"]
- [ ] Example: "Longsword" → ["Longsword", "Equipment", "Melee Weapon"]

### Page Customization (Basic)
- [ ] Reorder goal rolls within sections (drag handles in edit mode)
- [ ] Reorder skills within sections
- [ ] Show/hide entire sections (toggle switches)
- [ ] Reorder sections (drag-to-reorder)
- [ ] Save 2-3 page layouts (different section arrangements)
- [ ] Switch between saved page layouts
- [ ] Customizations persist across app restarts

---

## Architecture & Code Quality

### View Architecture
- [ ] **All detail views < 400 lines** (CRITICAL)
- [ ] **Section files < 250 lines each**
- [ ] **Reusable components < 150 lines**
- [ ] **Edit views < 200 lines**
- [ ] CharacterDetailView uses section-based architecture
- [ ] Sections in separate files (CharacterInfoSection, AttributesSection, etc.)
- [ ] No monolithic views (no files >400 lines)

### Data Model Architecture
- [ ] Character is root aggregate (owns all related data)
- [ ] Cascade delete works correctly (deleting character deletes all owned data)
- [ ] All relationships have explicit `inverse:` parameter
- [ ] Templates are optional (character can have override-only instances)
- [ ] Ownership tracking via `templateScope` field
- [ ] Version tracking on all templates
- [ ] Unique UUIDs for all entities
- [ ] **Phase 2A optional fields present** (availableModes, mentalActionScaling, conditionalDescription)
- [ ] Phase 2A fields remain unused in Phase 1 (no population, no UI)

### Content Expansion Framework
- [ ] Template protocol implemented
- [ ] Generic components work with any template type
- [ ] Content type registry complete
- [ ] Adding new content type takes 3-5 days (not 2-3 weeks)
- [ ] Pattern validated with at least 3 different content types

### State Management
- [ ] @State used correctly (local view state only)
- [ ] @Bindable used correctly (direct SwiftData binding)
- [ ] @Query used correctly (fetching from SwiftData)
- [ ] @Environment(\.modelContext) used correctly (insert/delete operations)
- [ ] No ViewModels in Phase 1 (not needed)

---

## Quality Bars

### Performance
- [ ] **Build time < 30 seconds** (full clean build)
- [ ] **App launch < 2 seconds** (cold start)
- [ ] **Smooth scrolling** (60fps in character detail view)
- [ ] No lag when toggling effects on/off
- [ ] No lag when switching between characters
- [ ] Modifier calculations instant (<100ms)

### Reliability
- [ ] **Zero data loss scenarios** - All operations preserve data correctly
- [ ] Graceful handling of import errors (validation, error messages)
- [ ] Undo support where appropriate (character deletion, template deletion)
- [ ] No crashes under normal usage
- [ ] No crashes when importing malformed files

### Testing
- [ ] Manual testing on **iPhone SE** (small screen)
- [ ] Manual testing on **iPhone 15** (standard size)
- [ ] Manual testing on **iPad Pro** (large screen)
- [ ] All features work on all tested devices
- [ ] Layouts adapt appropriately to screen size
- [ ] No compiler errors
- [ ] No compiler warnings

### Platform Support
- [ ] App runs on iOS 17+
- [ ] App runs on iPhone (all sizes)
- [ ] App runs on iPad (all sizes)
- [ ] Adaptive layouts for iPhone vs iPad
- [ ] Single-column layout on iPhone
- [ ] Two-column layout on iPad (where appropriate)

---

## User Experience

### General UX
- [ ] Intuitive navigation (users can find features without documentation)
- [ ] Clear visual hierarchy (important info stands out)
- [ ] Consistent UI patterns across screens
- [ ] Appropriate use of SF Symbols icons
- [ ] Clear button labels and actions
- [ ] Confirmation dialogs for destructive actions

### Data Entry
- [ ] Easy to create new character
- [ ] Easy to add stats and effects
- [ ] Template picker is searchable
- [ ] Keyboard input works smoothly
- [ ] Steppers/sliders feel responsive
- [ ] Form validation provides clear error messages

### Modifier Display
- [ ] Clear display of base vs effective values
- [ ] Modifier breakdown accessible in detail view
- [ ] Easy to see which effects are active
- [ ] Easy to understand why a value changed
- [ ] Victory Points formula visible when applicable

### General Traits Display
- [ ] Non-numeric effects display in dedicated section (e.g., "Flight", "Immunity to wound penalties")
- [ ] Only shown when effects are active
- [ ] Clear grouping by effect source

---

## Documentation

### Code Documentation
- [ ] Claude.md up to date and accurate
- [ ] rules.md up to date and accurate
- [ ] implementation-patterns.md references correct
- [ ] Key architectural decisions documented with WHY rationale
- [ ] Complex calculations have inline comments

### Git Workflow
- [ ] Clean commit history
- [ ] Descriptive commit messages
- [ ] Feature branch properly named (claude/feature-name-SESSION_ID)
- [ ] All work pushed to remote repository

---

## Final Validation

### Before Proceeding to Phase 2A

- [ ] **All above checkboxes checked** ✓
- [ ] User acceptance testing complete (user validates core workflows)
- [ ] Performance validated on target devices
- [ ] Export/import validated with real-world data
- [ ] Template system validated with 10+ templates per type
- [ ] Loadouts system validated with 5+ loadouts
- [ ] Architecture review confirms Phase 2A readiness (no refactoring needed)

**Phase 1 Complete!** 🎉 Ready to proceed to Phase 2A planning.

---

## Notes Section

*(Use this space during development to track issues, decisions, or items that need follow-up)*

**Open Items:**
-

**Known Issues:**
-

**Deferred to Phase 2:**
-

**Architectural Decisions Made:**
-
