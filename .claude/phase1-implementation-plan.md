# Phase 1 Implementation Plan
**Created:** 2026-01-11
**Status:** Draft - Awaiting User Approval

---

## Executive Summary

This plan outlines a systematic approach to implementing Phase 1 of the Fading Suns Character Sheet iOS application. The implementation is structured into **10 major phases** with **~40 implementation steps**, designed to build incrementally while maintaining architectural integrity.

**Estimated Duration:** 16-20 weeks (as specified in Claude.md)
**Critical Success Factor:** Maintaining <400 line file size limit to ensure fast builds and maintainability

---

## Critical Questions for User Clarification

Before beginning implementation, the following questions need answers:

### 1. Standard Attributes & Skills

**Question:** What are the canonical Fading Suns attributes and natural skills?

**Context:** We need to know what attributes and skills to include as default options in the template system. While users can create custom stats, having the standard Fading Suns stats available will improve UX.

**Example structures I'm assuming (please confirm or correct):**
- **Attributes:** Strength, Dexterity, Endurance, Intelligence, Perception, Tech, Introvert, Extrovert, Passion, Calm, Faith
- **Natural Skills:** Vigor, Impress, Melee, Fight, Shoot, Dodge, Observe, Sneak, Lockpicking, Stoic Gaze, Charm, Empathy, Knavery

### 2. Hardcoded Metric Formulas

**Question:** What are the exact formulas for the hardcoded metrics?

**Context:** The documentation mentions Defense, Initiative, and Hit Points as examples. I need the complete list of metrics and their formulas.

**Examples I'm assuming (please provide complete list):**
- **Defense:** Dexterity + Fight + 3
- **Initiative:** Perception + Observe
- **Hit Points:** Endurance × 2
- **Vitality:** Strength + Endurance + Vigor
- **Attack (Melee):** Dexterity + Melee
- **Attack (Ranged):** Dexterity + Shoot

### 3. Content Type Implementation Priority

**Question:** Should we implement ALL content types in Phase 1 from the start, or prioritize a core subset?

**Options:**
- **Option A (Full Implementation):** Implement all content types (attributes, skills, lores, tongues, innate qualities, psi, theurgy, maneuvers, equipment, loadouts) from the beginning
- **Option B (Incremental):** Start with core types (attributes, skills, innate qualities, equipment) and expand to occult/maneuvers later in Phase 1

**Recommendation:** Option A - Implementing the full protocol-based architecture from the start prevents refactoring and validates the extensibility pattern early.

### 4. Template Library Management UI

**Question:** How should users access the template library management interface?

**Options:**
- **Option A:** Dedicated tab in main tab bar (Characters | Templates | Settings)
- **Option B:** Modal sheet accessible from character list (toolbar button "Manage Templates")
- **Option C:** Side menu/drawer navigation

**Recommendation:** Option A - Dedicated tab provides clearest access and matches the importance of template management.

### 5. Goal Rolls Definition

**Question:** Are goal rolls pre-defined combinations (like "Attack Roll" = Dexterity + Fight) or can users create custom combinations?

**Context:** The documentation mentions "Goal Rolls (attribute + skill combinations)" but doesn't specify if these are hardcoded or user-defined.

**Options:**
- **Option A:** Pre-defined common rolls (Attack, Defense Roll, Perception Roll, etc.)
- **Option B:** Fully user-defined (users pick any attribute + skill combination)
- **Option C:** Pre-defined with ability to create custom

**Recommendation:** Option C - Provides best UX with flexibility.

### 6. Page Layouts Scope

**Question:** For "Save 2-3 page layouts" - does this mean 2-3 total layouts for the entire app, or 2-3 layouts per character?

**Context:** Section reordering and show/hide functionality - should this be global or per-character?

**Recommendation:** Per-character layouts provide more flexibility, but global layouts are simpler for Phase 1.

---

## Architecture Overview

### Data Model Hierarchy

```
ModelContainer (SwiftData)
├── Character (root aggregate)
│   ├── Stats (user-defined: attributes, skills, lores, tongues)
│   ├── Metrics (calculated: defense, initiative, HP, etc.)
│   ├── Effects (modifiers: psi, theurgy, maneuvers, equipment, innate)
│   │   └── EffectModifiers (multiple per effect)
│   ├── Loadouts (saved configurations)
│   └── PageLayouts (section arrangements)
├── TemplateLibrary (containers)
│   ├── StatTemplates
│   ├── EffectTemplates
│   └── (other template types)
└── AppSettings (global configuration)
```

### Key Architectural Patterns

1. **Protocol-Based Content System**
   - `CharacterTemplate` protocol for all template types
   - `CharacterInstance` protocol for all character-owned instances
   - Generic components work with any template type

2. **Modifier Calculation Pipeline**
   ```
   Base Value → Active Effects → Effect Modifiers → Target Stat → Calculated Modifier → Effective Value
   ```

3. **VP Calculation** (Victory Points)
   ```swift
   VP = (rollValue - 8) / 3  // Integer division (rounded down)
   rollValue = attributeValue + skillValue  // For sustained effects, assume 8
   ```

4. **Section-Based View Architecture**
   ```
   CharacterDetailView (<400 lines)
   ├── CharacterInfoSection.swift (~80 lines)
   ├── AttributesSection.swift (~150 lines)
   ├── SkillsSection.swift (~200 lines)
   ├── MetricsSection.swift (~100 lines)
   ├── EffectsSection.swift (~150 lines)
   └── LoadoutsSection.swift (~100 lines)
   ```

---

## Implementation Phases

### Phase 0: Project Setup & Core Infrastructure (Week 1)

**Goal:** Establish folder structure and base protocols

**Tasks:**
1. Create folder structure matching Claude.md organization
2. Delete template files (Item.swift, default ContentView)
3. Implement enum definitions (TemplateScope, ModifierType, ContentType)
4. Implement core protocols (CharacterTemplate, CharacterInstance, KeywordGenerating)
5. Set up SwiftData model container schema

**Files Created:**
- `Models/Core/Enums.swift` (~100 lines)
- `Models/Core/Protocols.swift` (~150 lines)
- `Models/Core/ContentType.swift` (~120 lines)
- Update `CharacterSheetApp.swift` with proper schema

**Success Criteria:**
- Project compiles without errors
- Protocols defined and ready for conformance
- Folder structure matches documentation

---

### Phase 1: Core Data Models (Week 2-3)

**Goal:** Implement all SwiftData models with proper relationships

**Tasks:**
1. Implement `Character` model (root aggregate)
2. Implement `Stat` model (user-defined values)
3. Implement `Metric` model (calculated values)
4. Implement `Effect` model (with template reference)
5. Implement `EffectModifier` model (multiple per effect)
6. Implement `Loadout` model (saved configurations)
7. Implement template models (StatTemplate, EffectTemplate, etc.)
8. Implement `TemplateLibrary` model
9. Add Phase 2A optional fields (unused in Phase 1)
10. Configure all SwiftData relationships with cascade delete and explicit inverses

**Files Created:**
- `Models/Character/RPGCharacter.swift` (~200 lines)
- `Models/Character/Stat.swift` (~150 lines)
- `Models/Character/Metric.swift` (~120 lines)
- `Models/Character/Effect.swift` (~200 lines)
- `Models/Character/EffectModifier.swift` (~150 lines)
- `Models/Character/Loadout.swift` (~100 lines)
- `Models/Templates/TemplateProtocol.swift` (~80 lines)
- `Models/Templates/StatTemplate.swift` (~150 lines)
- `Models/Templates/EffectTemplate.swift` (~150 lines)
- `Models/Templates/TemplateLibrary.swift` (~120 lines)

**Success Criteria:**
- All models compile and conform to protocols
- SwiftData relationships configured correctly
- Models include Phase 2A optional fields
- Character.getStatValue() method works
- Effect.calculateModifier() method works
- VP calculation validates correctly

---

### Phase 2: Formula & Calculation Engine (Week 3-4)

**Goal:** Implement VP calculation and modifier propagation system

**Tasks:**
1. Create `FormulaEngine` utility class
2. Implement VP calculation (assume roll of 8 for sustained effects)
3. Implement metric formula parser (for "Dexterity + Fight + 3" style formulas)
4. Implement modifier aggregation logic (sum all applicable modifiers)
5. Implement effective value calculation for Stats
6. Implement effective value calculation for Metrics
7. Write unit tests for VP calculation edge cases
8. Write unit tests for formula parsing

**Files Created:**
- `Utilities/FormulaEngine.swift` (~250 lines)
- `Utilities/VPCalculator.swift` (~100 lines)
- `Utilities/ModifierAggregator.swift` (~150 lines)

**Success Criteria:**
- VP calculation: (8-8)/3 = 0, (11-8)/3 = 1, (14-8)/3 = 2
- Static modifiers calculate correctly (+2 always equals +2)
- VP modifiers calculate correctly (+2+VP with Intro 5 + Vigor 6 = +2+1 = +3)
- Multiple modifiers sum correctly
- Formula parser handles all metric formulas
- Metrics update when dependent stats change

---

### Phase 3: Character List View (Week 4)

**Goal:** Create, view, duplicate, and delete characters

**Tasks:**
1. Implement `CharacterListView` (~250 lines)
2. Add create character sheet/modal
3. Add duplicate character functionality
4. Add delete character with confirmation dialog
5. Implement @Query for fetching characters
6. Add search/filter functionality
7. Add toolbar with "New Character" button
8. Handle empty state UI

**Files Created:**
- `Views/CharacterList/CharacterListView.swift` (~200 lines)
- `Views/CharacterList/CreateCharacterSheet.swift` (~150 lines)
- `Views/CharacterList/CharacterRow.swift` (~80 lines)

**Success Criteria:**
- Can create new character with name
- Can duplicate existing character
- Can delete character (cascade deletes all owned data)
- Search works correctly
- Empty state shows helpful message
- All operations < 400 lines per file

---

### Phase 4: Character Detail View Foundation (Week 5-6)

**Goal:** Build section-based detail view architecture

**Tasks:**
1. Create `CharacterDetailView` shell (~300 lines max)
2. Implement navigation from list to detail
3. Create section container pattern
4. Implement `CharacterInfoSection` (name, description, edit mode)
5. Implement edit mode toggle
6. Set up section visibility state management
7. Add toolbar with edit/done buttons

**Files Created:**
- `Views/CharacterDetail/CharacterDetailView.swift` (~250 lines)
- `Views/CharacterDetail/Sections/CharacterInfoSection.swift` (~100 lines)

**Success Criteria:**
- Detail view shows selected character
- Edit mode toggles correctly
- Back navigation works
- Character name editable
- File stays under 400 lines

---

### Phase 5: Stats Implementation (Week 6-7)

**Goal:** Implement all stat types (attributes, skills, lores, tongues)

**Tasks:**
1. Implement `AttributesSection` with add/edit/delete
2. Implement `SkillsSection` (natural + learned)
3. Implement `LoresSection`
4. Implement `TonguesSection`
5. Create `StatEditSheet` (reusable for all stat types)
6. Create `StatCell` component (shows "base (effective)" format)
7. Implement base value editing (stepper or number field)
8. Show modifier breakdown on tap
9. Handle description field for skills/lores/tongues (not attributes)

**Files Created:**
- `Views/CharacterDetail/Sections/AttributesSection.swift` (~150 lines)
- `Views/CharacterDetail/Sections/SkillsSection.swift` (~200 lines)
- `Views/CharacterDetail/Sections/LoresSection.swift` (~120 lines)
- `Views/CharacterDetail/Sections/TonguesSection.swift` (~120 lines)
- `Views/Components/StatCell.swift` (~120 lines)
- `Views/Components/StatEditSheet.swift` (~180 lines)
- `Views/Components/ModifierBreakdownView.swift` (~100 lines)

**Success Criteria:**
- Can add/edit/delete all stat types
- Stats show "base (effective)" when modified
- Stats show just "base" when unmodified
- Modifier breakdown shows all active effects
- Description field required for skills/lores/tongues
- All sections under 250 lines

---

### Phase 6: Metrics Implementation (Week 7-8)

**Goal:** Implement calculated metrics with hardcoded formulas

**Tasks:**
1. Implement `MetricsSection` (Defense, Initiative, HP, etc.)
2. Create default metrics for new characters
3. Implement formula display (show "Defense = Dex + Fight + 3")
4. Implement effective value calculation
5. Show modifier breakdown for metrics
6. Create `MetricCell` component (shows effective value only)
7. Handle metric value updates when dependent stats change

**Files Created:**
- `Views/CharacterDetail/Sections/MetricsSection.swift` (~150 lines)
- `Views/Components/MetricCell.swift` (~100 lines)
- `Models/Character/MetricDefaults.swift` (~120 lines)

**Success Criteria:**
- All metrics display correctly
- Metrics update when dependent stats change
- Metrics support VP modifiers correctly
- Always show effective value (not "base (effective)")
- Modifier breakdown accessible
- Section under 250 lines

---

### Phase 7: Effects System (Week 8-10)

**Goal:** Implement all effect types with multiple modifiers support

**Tasks:**
1. Implement `EffectsSection` (list of effects grouped by type)
2. Create `EffectEditSheet` (create/edit effects)
3. Create `EffectModifierEditView` (add/edit individual modifiers)
4. Implement toggle on/off functionality
5. Implement effect type filtering (psi, theurgy, maneuvers, equipment, innate)
6. Add metadata fields (level, type/path/paradigm, equipment type)
7. Create `EffectCell` component (shows active state, name, modifier summary)
8. Implement keyword generation for effects
9. Support multiple modifiers per effect (array of EffectModifier)
10. Implement static modifier editing
11. Implement VP modifier editing (base + attribute + skill)

**Files Created:**
- `Views/CharacterDetail/Sections/EffectsSection.swift` (~200 lines)
- `Views/Effects/EffectEditSheet.swift` (~250 lines)
- `Views/Effects/EffectModifierEditView.swift` (~200 lines)
- `Views/Effects/EffectModifierRow.swift` (~80 lines)
- `Views/Components/EffectCell.swift` (~120 lines)
- `Views/Effects/EffectTypeFilterView.swift` (~100 lines)

**Success Criteria:**
- Can create effects of all types
- Can add multiple modifiers to single effect
- Toggle on/off works and updates affected stats
- Static modifiers work (+2 to Defense)
- VP modifiers work (+2+VP to Attack)
- Metadata (level, type, equipment type) saves correctly
- All files under 400 lines

---

### Phase 8: Template System (Week 10-12)

**Goal:** Implement three-tier template system (local, override, imported)

**Tasks:**
1. Create `TemplateLibraryView` (browse templates by type)
2. Create `TemplatePickerView` (generic, works for any template type)
3. Implement template creation from character instance
4. Implement character instance creation from template
5. Implement character override system (instance overrides template)
6. Handle template scope tagging (.local, .characterOverride, .imported)
7. Create template edit functionality
8. Create template delete functionality
9. Implement template search by keywords
10. Show template vs override indicators in UI

**Files Created:**
- `Views/Templates/TemplateLibraryView.swift` (~250 lines)
- `Views/Templates/TemplatePickerView.swift` (~180 lines)
- `Views/Templates/TemplateEditSheet.swift` (~200 lines)
- `Views/Templates/TemplateRow.swift` (~80 lines)
- `Services/TemplateService.swift` (~200 lines)

**Success Criteria:**
- Can create local templates from instances
- Can create instances from templates
- Character overrides work correctly
- Template picker searchable by keywords
- Template scopes display correctly
- Can edit/delete templates
- All views under 400 lines

---

### Phase 9: Loadouts System (Week 12-13)

**Goal:** Save and switch between character configurations

**Tasks:**
1. Implement `LoadoutsSection` (list of loadouts)
2. Create `LoadoutEditSheet` (create/rename loadout)
3. Implement "Capture Current State" functionality
4. Implement "Apply Loadout" functionality
5. Show loadout metadata (created date, active effects count)
6. Handle delete loadout
7. Create `LoadoutCell` component

**Files Created:**
- `Views/CharacterDetail/Sections/LoadoutsSection.swift` (~150 lines)
- `Views/Loadouts/LoadoutEditSheet.swift` (~120 lines)
- `Views/Components/LoadoutCell.swift` (~80 lines)

**Success Criteria:**
- Can create loadout from current state
- Can apply loadout (restores saved state)
- Can rename loadout
- Can delete loadout
- Loadout shows which effects are active
- Switching loadouts updates character state correctly

---

### Phase 10: Export/Import System (Week 13-15)

**Goal:** Share characters and templates via file export/import

**Tasks:**
1. Implement `ExportService` (generates JSON files)
2. Implement `ImportService` (parses JSON files)
3. Create export format structures (ExportFormat, TemplateData, CharacterData)
4. Implement character export (.fscharacter file)
5. Implement template library export (.fstemplate file)
6. Implement import conflict detection (name/ID matching)
7. Create `ImportConflictSheet` (Replace/Skip/Rename UI)
8. Implement version tracking
9. Implement "last modified by" metadata
10. Add Share Sheet integration (iOS native sharing)
11. Add Document Picker integration (file selection)
12. Validate imported data before insertion
13. Handle malformed file errors gracefully

**Files Created:**
- `Services/ExportService.swift` (~250 lines)
- `Services/ImportService.swift` (~300 lines)
- `Models/Export/ExportFormat.swift` (~200 lines)
- `Views/Export/ExportSheet.swift` (~150 lines)
- `Views/Import/ImportConflictSheet.swift` (~180 lines)

**Success Criteria:**
- Can export single character to .fscharacter file
- Can export template library to .fstemplate file
- Can import character from file
- Can import template library from file
- Conflict resolution UI works (Replace/Skip/Rename)
- Round-trip testing: export → import produces identical data
- Handles malformed files without crashing
- Version tracking works correctly

---

### Phase 11: Goal Rolls (Week 15-16)

**Goal:** Display attribute + skill roll combinations

**Tasks:**
1. Implement `GoalRollsSection` (list of goal rolls)
2. Create `GoalRollEditSheet` (create custom rolls)
3. Implement pre-defined common rolls (Attack, Defense Roll, etc.)
4. Show combined value (attribute + skill + modifiers)
5. Show modifier breakdown for rolls
6. Create `GoalRollCell` component

**Files Created:**
- `Views/CharacterDetail/Sections/GoalRollsSection.swift` (~180 lines)
- `Views/GoalRolls/GoalRollEditSheet.swift` (~150 lines)
- `Views/Components/GoalRollCell.swift` (~100 lines)
- `Models/Character/GoalRoll.swift` (~100 lines)

**Success Criteria:**
- Can create custom goal rolls
- Pre-defined rolls available
- Shows combined value correctly
- Modifier breakdown accessible
- Section under 250 lines

---

### Phase 12: Page Customization (Week 16-17)

**Goal:** Reorder sections, show/hide, and save layouts

**Tasks:**
1. Implement section reordering (drag handles in edit mode)
2. Implement section show/hide toggles
3. Implement goal roll reordering within section
4. Implement skill reordering within section
5. Create `PageLayout` model (saves section order + visibility)
6. Implement save layout functionality
7. Implement switch layout functionality
8. Create `PageLayoutPicker` component

**Files Created:**
- `Models/Character/PageLayout.swift` (~150 lines)
- `Views/PageLayout/PageLayoutPicker.swift` (~120 lines)
- `Views/PageLayout/SectionOrderEditor.swift` (~150 lines)

**Success Criteria:**
- Can reorder sections via drag handles
- Can show/hide sections
- Can reorder goal rolls within sections
- Can reorder skills within sections
- Can save 2-3 page layouts
- Can switch between layouts
- Customizations persist across app restarts

---

### Phase 13: Polish & Testing (Week 17-20)

**Goal:** Ensure quality bars are met and all functionality works correctly

**Tasks:**
1. Test on iPhone SE (small screen validation)
2. Test on iPhone 15 (standard screen)
3. Test on iPad Pro (large screen, two-column layout)
4. Verify all file sizes under 400 lines
5. Measure and optimize build time (target < 30 seconds)
6. Measure and optimize app launch (target < 2 seconds)
7. Test scrolling performance (60fps)
8. Test with 10+ templates per type
9. Test with 5+ loadouts
10. Test round-trip export/import with real data
11. Fix any discovered bugs
12. Add confirmation dialogs for destructive actions
13. Improve empty state UI
14. Add SF Symbols icons consistently
15. Validate Phase 2A readiness (no refactoring needed)

**Success Criteria:**
- All checklist items in phase1-checklist.md are checked
- Build time < 30 seconds
- App launch < 2 seconds
- Smooth 60fps scrolling
- No crashes or data loss
- Works correctly on iPhone SE, iPhone 15, iPad Pro
- User acceptance testing passes

---

## File Size Tracking

**CRITICAL:** All files must stay under these limits:

| File Type | Limit | Enforcement |
|-----------|-------|-------------|
| Main detail view | 400 lines | STRICT |
| Section files | 250 lines | STRICT |
| Reusable components | 150 lines | STRICT |
| Edit views | 200 lines | STRICT |
| Service files | 300 lines | RECOMMENDED |
| Model files | 250 lines | RECOMMENDED |

**WHY:** Previous 1,500-line monolithic views caused 60+ second build times and were unmaintainable.

---

## Testing Strategy

### Unit Testing
- VP calculation edge cases (negative VP, very high rolls)
- Formula parsing (complex formulas, malformed input)
- Modifier aggregation (multiple effects, same stat)
- Import validation (malformed JSON, version conflicts)

### Integration Testing
- Character CRUD operations
- Template system (create from instance, instance from template)
- Loadout save/restore functionality
- Export/import round-trip

### Manual Testing
- Small screen (iPhone SE) - ensure readability
- Standard screen (iPhone 15) - optimal layout
- Large screen (iPad Pro) - two-column layouts where appropriate
- Real-world data (10+ templates per type, 5+ loadouts)

---

## Risk Mitigation

### Risk 1: File Size Creep
**Mitigation:** Strict review after each section implementation. If approaching 400 lines, split immediately.

### Risk 2: Build Time Regression
**Mitigation:** Measure build time weekly. If exceeds 30 seconds, investigate and refactor.

### Risk 3: SwiftData Relationship Complexity
**Mitigation:** Test cascade delete and relationship behavior early in Phase 1. Validate with sample data.

### Risk 4: VP Calculation Bugs
**Mitigation:** Comprehensive unit tests in Phase 2. Test edge cases (roll of 8, negative results, very high rolls).

### Risk 5: Export/Import Data Loss
**Mitigation:** Round-trip testing. Export → Import must produce identical character. Validate before deployment.

---

## Success Metrics

At the end of Phase 1, the following must be true:

1. ✅ All functionality in phase1-checklist.md working
2. ✅ All views under 400 lines (STRICT)
3. ✅ Build time < 30 seconds
4. ✅ App launch < 2 seconds
5. ✅ 60fps scrolling in character detail view
6. ✅ Zero data loss scenarios
7. ✅ Works on iPhone SE, iPhone 15, iPad Pro
8. ✅ User can create character, add stats/effects, export/import, use loadouts
9. ✅ Template system validated with 10+ templates per type
10. ✅ Architecture validated as Phase 2A-ready (no refactoring needed)

---

## Next Steps

1. **USER REVIEW:** Please review this plan and answer the 6 critical questions above
2. **PLAN APPROVAL:** Approve the overall implementation approach
3. **BEGIN PHASE 0:** Set up project structure and core infrastructure
4. **ITERATIVE DEVELOPMENT:** Implement phases 1-13 sequentially
5. **TESTING & VALIDATION:** Ensure all quality bars met
6. **PHASE 1 COMPLETE:** Move to Phase 2A planning

---

## Notes

**Documentation Updates:** This plan should be updated as we encounter issues or make architectural decisions. Any changes to approach should be documented with rationale.

**Flexibility:** While this plan is comprehensive, we may discover better approaches during implementation. Changes are acceptable if they improve maintainability and don't compromise Phase 2A readiness.

**Communication:** If uncertain about any implementation detail, ask for clarification rather than guessing. Quality and correctness are more important than speed.
