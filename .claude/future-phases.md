# Future Phases - Phase 2A, 2B, and Beyond

**Purpose:** Documentation of features planned for Phase 2A and Phase 2B. This content is NOT for Phase 1 implementation—it's preserved here for architectural context and future planning.

**IMPORTANT:** During Phase 1 development, focus exclusively on Phase 1 features. Reference this file only when making architectural decisions that must support future phases without refactoring.

---

## Phase 2A: Advanced Effects System (6-8 weeks, future)

**Primary Goal:** Add complex modifier calculations and per-page state management

**Timing:** After Phase 1 complete and stable

### Features

#### Mode Systems

**Named Modes:**
- Effects with discrete options (e.g., Aggressive/Balanced/Defensive stance)
- Each mode provides different modifier sets
- User selects one mode per effect
- Example: "Combat Stance" with three modes:
  - Aggressive: +2 Attack, -2 Defense
  - Balanced: +0 Attack, +0 Defense
  - Defensive: -2 Attack, +2 Defense

**Numeric Modes:**
- Effects that scale with resource allocation (e.g., X mental actions → +X modifier)
- User allocates numeric value (within budget constraints)
- Modifier scales proportionally
- Example: "Psi Shield" - allocate X mental actions → +X to Defense

**Dual-Mode Effects:**
- Some effects combine both named and numeric modes
- Choose named mode AND allocate numeric resources
- Each named mode produces different scaling effects
- Example: "Farsenses" has two paths (Far Sight vs Far Hand) and each scales with mental action allocation differently

**Implementation Notes:**
- Effect model already includes `availableModes: [String]?` field (unused in Phase 1)
- Effect model already includes `mentalActionScaling: Bool?` field (unused in Phase 1)
- Per-effect mode selection storage: `[UUID: String]` mapping in character state

#### Mental Action Allocation

**Budget System:**
- Character has total mental action budget (base + modifiers from effects/gear)
- Base budget: 0 mental actions (must use general actions unless modified)
- Effects/gear can grant additional mental actions (e.g., "+2 Mental Actions")
- User allocates mental actions to active occult effects
- Validation prevents over-allocation

**UI Requirements:**
- Visual budget display showing used/available mental actions
- Per-effect allocation controls (steppers or sliders)
- Real-time validation and error messaging
- Quick allocation presets (e.g., "All to Psi Shield")

**Modifier Scaling:**
- Effects with `mentalActionScaling: true` calculate modifiers based on allocated actions
- Typically: +X per mental action allocated
- Some effects have threshold requirements (e.g., "minimum 2 mental actions")

#### Multiple Action System

**Character-Level Mode:**
- User selects: 1, 2, or 3 general actions for this turn
- Automatic penalty calculation:
  - 1 action: -0 global modifier
  - 2 actions: -3 global modifier
  - 3 actions: -5 global modifier

**Penalty Reduction Effects:**
- Some effects reduce multiple action penalties
- Example: "La Destreza" maneuver - if one action is melee, penalties become -0/-3 instead of -0/-3/-5
- Effects modify the penalty calculation, not the base penalties

**Action Type Budgets:**
- **General Actions:** Baseline 1, can be used for any task type
- **Physical Actions:** Baseline 0, bonus actions specifically for physical tasks
- **Mental Actions:** Baseline 0, bonus actions specifically for mental/occult tasks
- Effects/gear can modify all three budgets independently

**Physical Action Consumption:**
- Some maneuvers cost physical actions when declared active
- Example: Maneuver costs 1 physical action but provides +2 to Attack rolls
- Budget tracking must account for:
  - Bonus actions granted by effects/gear
  - Actions consumed by active maneuvers
  - Net available actions = granted - consumed

#### Conditional Modifiers

**Conditional Applicability:**
- Effects with situational applicability (e.g., "+2 Tech when inventing")
- Effect model includes `conditionalDescription: String?` field (unused in Phase 1)
- Per-goal-roll toggle for each applicable conditional

**Global State:**
- Toggling conditional ON applies to ALL goal rolls with that conditional
- Example: "When inventing" toggle affects all Tech, Think, and craft-related rolls
- Not per-page state (that's custom dashboards feature)

**Visual Flagging:**
- Goal rolls showing conditional-modified values are visually marked
- Indicates that displayed value assumes conditional is active
- Clear distinction from permanent modifiers

#### Custom Dashboard Pages

**Multi-Page System:**
- Create multiple custom pages (e.g., "Melee Combat", "Ranged Combat", "Social", "Occult")
- Each page shows filtered subset of items (selected goal rolls, metrics, traits)
- User curates which elements appear on each page

**Per-Page State (MAJOR FEATURE):**
- Different effects active on different pages
- Different mode selections per page
- Different mental action allocations per page
- Enables true "loadout per scenario" functionality

**Quick Access Controls:**
- Dropdown menus for quick effect toggling on dashboard pages
- One-tap mode switching
- Preset allocation buttons

**Visual Flagging:**
- Elements showing non-global state configurations are visually marked (shaded/colored/badged)
- Indicates that displayed value assumes specific page configuration
- Differentiates from "universal" values that apply everywhere

#### Advanced Modifier Display

**Full Breakdown View:**
- Detail view shows all contributing effects
- Separate sections for:
  - Base value
  - Permanent modifiers (benefices/afflictions)
  - Toggleable effects (active on this page)
  - Mode-dependent modifiers
  - Conditional modifiers (if active)
- Total calculation with intermediate steps

**Mode & Conditional Indicators:**
- Clear indication of which mode is selected
- Visual flag for conditionals (active/inactive)
- Tooltip or expandable detail for why modifier applies

#### Loadouts Integration with Phase 2A

**Per-Page Loadout Assignment:**
- Loadouts (created in Phase 1) can be assigned to custom dashboard pages
- Quick switching between loadout configurations
- Each page can have its own loadout

**Live Stat References in Text Blocks:**
- Custom formatted text blocks can reference different loadouts
- Side-by-side comparison: "With Quickening: [Loadout A stats] vs Without: [Loadout B stats]"
- Foundation for "word processor"-style custom views with loadout-specific live elements

**Loadout Enhancements:**
- Loadout model gains mode selection storage: `var modeSelections: [UUID: String]?`
- Loadout model gains mental action allocation: `var mentalActionAllocations: [UUID: Int]?`
- Loadouts now capture complete character configuration state

---

## Phase 2B: Advanced Customization & macOS (6-8 weeks, future)

**Primary Goal:** Full page builder and macOS optimization

**Timing:** After Phase 2A complete and stable

### Features

#### Advanced Page Builder

**Drag-and-Drop Designer:**
- Visual page builder beyond Phase 2A's filtered dashboards
- Drag elements from palette to canvas
- Resize, reposition, and style elements
- Multi-column custom layouts

**Custom Styling:**
- Per-section formatting options
- Font size, color, spacing controls
- Background colors and borders
- Custom icons and visual themes

**"Word Processor" Mode:**
- Rich text editing environment
- Inline live stat elements (update dynamically)
- Multiple text blocks per page
- Each block can reference different loadout for stat display
- Side-by-side comparisons with live data

#### macOS Optimization

**Mac-Specific UI:**
- NavigationSplitView (sidebar + detail + inspector)
- Multi-window support:
  - Character list in one window
  - Character details in another
  - Template library in third window
- Keyboard shortcuts for common operations
- Menu bar integration

**Large Screen Layouts:**
- Optimized layouts for 27"+ displays
- Unlimited sections/pages (no mobile space constraints)
- Three-column layouts where appropriate
- Inspector panel for properties and settings

**Platform-Specific Code:**
- Use `#if os(macOS)` for Mac-specific UI
- Environment size classes for responsive layouts
- Separate view modifiers for Mac vs iOS behavior
- Shared core logic, platform-optimized presentation

#### Export/Import of Custom Formatting

**Shareable Page Designs:**
- Export custom page layouts as `.fslayout` files
- Import layouts created by other users
- Community-shared templates for common scenarios
- Version compatibility tracking

---

## Platform Strategy: macOS Details

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
1. **Primary audience** - Most tabletop gamers use phones/tablets at the table
2. **Information hierarchy** - Smaller screens force good design decisions
3. **Faster development** - Single platform target, easier testing
4. **Easier to expand** - iOS → Mac is easier than Mac → iOS (compression is harder than expansion)

### Future: macOS Support (Phase 2B)

**Mac-specific enhancements:**
- NavigationSplitView (sidebar + detail)
- Multi-window support (character list in one window, details in another)
- Full page customization builder
- Keyboard shortcuts (Cmd+N for new character, Cmd+E for edit mode, etc.)
- Menu bar integration (File > Export, Edit > Duplicate Character, etc.)
- Unlimited sections/pages (no space constraints)

**Technical approach:**
- Same SwiftUI codebase with platform conditionals
- Use `#if os(macOS)` for platform-specific UI
- Environment size classes for responsive layouts
- Separate view modifiers for Mac vs iOS behavior
- Shared data models and business logic

---

## Additional Future Features (Beyond Phase 2B)

### Features Under Consideration

**Dice Rolling Integration:**
- In-app dice roller with goal roll integration
- Automatic Victory Point calculation
- Roll history and statistics
- Integration with physical dice (Bluetooth dice)

**Character Portraits & Images:**
- Portrait image for character
- Gallery of associated images (tokens, concept art)
- Image library organization
- Support for custom icons per stat/effect

**PDF Export:**
- Generate printable character sheets
- Multiple template options
- Custom formatting support
- Print optimization

**Print Layouts:**
- Printer-friendly page layouts
- Black & white optimized
- Multiple columns for space efficiency
- Header/footer customization

---

## Detailed Actions System (Phase 2A Feature)

**Purpose:** Characters have limited actions per turn. Using multiple actions incurs global penalties.

### Action Types

**General Actions:**
- Can be used for any action type (physical, mental, social, etc.)
- Baseline: 1 general action per turn
- Modified by effects/gear (rare)

**Physical Actions:**
- Bonus actions specifically for physical tasks
- Baseline: 0 physical actions (must use general unless modified)
- Modified by effects/gear (e.g., "+1 Physical Action" from equipment)
- Cannot be used for mental or social tasks

**Mental Actions:**
- Bonus actions specifically for mental/occult tasks
- Baseline: 0 mental actions (must use general unless modified)
- Modified by effects/gear (e.g., "+2 Mental Actions" from psi training)
- Allocated to occult effects for sustained concentration
- Cannot be used for physical or social tasks

### Multiple Action Penalties

**Baseline Character (1 general action):**
```
- 1 action:  -0 global modifier
- 2 actions: -3 global modifier
- 3 actions: -5 global modifier
```

**With Penalty Reduction Effects:**
- Some maneuvers reduce penalties (e.g., La Destreza maneuver)
- Example: La Destreza - if one action is melee, penalties become -0/-3 instead of -0/-3/-5
- Some effects add bonus actions without penalties (e.g., "+1 Physical Action" allows 2 physical + 1 general at -0)

**Penalty Application:**
- Global modifier applies to ALL actions taken during turn
- Effects can modify penalty calculation
- Some effects grant penalty-free bonus actions in specific categories

### Physical Actions (Detailed)

**Baseline Behavior:**
- Baseline character: 0 physical actions
- Must use general actions for physical tasks unless modified

**Bonus Physical Actions:**
- Effects/gear can grant additional physical actions (e.g., "+1 Physical Action")
- Bonus actions don't incur multiple action penalties
- Example: Character with "+1 Physical Action" can take 1 general + 1 physical at -0 penalty

**Action-Consuming Maneuvers:**
- Some maneuvers cost physical actions when declared active
- Example: Maneuver costs 1 physical action but provides +2 to Attack rolls
- User declares active at beginning of turn → loses 1 physical action, gains modifier
- Budget tracking: Available = Granted - Consumed

**Budget Calculation:**
```
Physical Action Budget:
1. Start with base (usually 0)
2. Add bonus actions from effects/gear
3. Subtract actions consumed by active maneuvers
4. Net available = base + granted - consumed
```

### Mental Actions (Detailed)

**Baseline Behavior:**
- Baseline character: 0 mental actions
- Must use general actions for occult effects unless modified

**Bonus Mental Actions:**
- Effects/gear can grant additional mental actions (e.g., "+2 Mental Actions")
- Common sources: Psi training, occult gear, benefices

**Allocation System:**
- Character allocates mental actions among active occult effects
- Each effect requires minimum allocation (usually 1, some require 2+)
- Modifiers scale with allocated mental actions
- Validation prevents over-allocation

**Budget Enforcement:**
- System tracks total available vs. allocated
- UI shows real-time budget status
- Error messaging if over-allocated
- Auto-adjustment when effects deactivated

### Implementation Requirements

**Phase 2A Data Model Changes:**

1. **Character model additions:**
   - `var generalActionsBase: Int = 1`
   - `var physicalActionsBase: Int = 0`
   - `var mentalActionsBase: Int = 0`
   - `var multipleActionMode: Int = 1` // 1, 2, or 3 general actions this turn
   - `var mentalActionAllocations: [UUID: Int] = [:]` // effectID -> allocated mental actions

2. **Effect model additions:**
   - `var physicalActionCost: Int?` // Actions consumed when active
   - `var mentalActionScaling: Bool?` // Whether modifier scales with allocation
   - `var minimumMentalActions: Int?` // Minimum allocation required

3. **Computed properties:**
   - `var availableGeneralActions: Int` // base + modifiers
   - `var availablePhysicalActions: Int` // base + granted - consumed
   - `var availableMentalActions: Int` // base + granted
   - `var allocatedMentalActions: Int` // sum of allocations
   - `var multipleActionPenalty: Int` // calculated from mode and effects

4. **UI Components:**
   - Multiple action mode selector (1/2/3 actions)
   - Mental action allocation controls per effect
   - Budget display (used/available for each type)
   - Real-time penalty calculator
   - Visual indicators for penalty-affected stats

### Example Scenario

**Character Configuration:**
```
Character Stats:
- Base: 1 general, 0 physical, 0 mental
- Equipped: Powered Armor (+1 Physical Action)
- Active: Psi Training (+2 Mental Actions)
- Total: 1 general, 1 physical, 2 mental
```

**Turn Configuration:**
```
- Using: 3 general actions (baseline penalty: -5)
- Active maneuver: La Destreza (one action is melee, reduces penalty to -3)
- Mental allocation: 2 actions to "Psi Shield" effect
```

**Result:**
```
Available Actions:
- Can perform 3 general + 1 physical + 2 mental actions

Global Modifier:
- -3 (instead of -5, due to La Destreza penalty reduction)

Effect Modifiers:
- Psi Shield active with 2 mental actions allocated
- Modifier scales: +2 to Defense (1 per mental action)
```

---

## Architectural Implications for Phase 1

**CRITICAL:** Phase 1 data models must support Phase 2A/2B features without refactoring.

**Phase 1 Model Design:**
- Include optional fields for Phase 2A features (unused, but present)
- Use extensible patterns for modifier calculations
- Design relationships to support per-page state
- Plan for action budget tracking fields

**Optional Fields Strategy:**
- Add fields now, populate later
- Avoids breaking changes and data migrations
- Fields marked with "Phase 2A" comments
- Ignored in Phase 1, populated in Phase 2A

**Example:**
```swift
@Model
class Effect {
    // Phase 1 fields
    var name: String
    var isActive: Bool

    // Phase 2A fields (unused in Phase 1)
    var availableModes: [String]?    // Named modes
    var mentalActionScaling: Bool?   // Numeric scaling
    var conditionalDescription: String?
    var physicalActionCost: Int?
}
```

**Modifier Calculation Extensibility:**
- Phase 1: Simple active/inactive toggle with VP formulas
- Phase 2A: Add mode selection, mental action scaling, conditionals
- Architecture must support adding complexity without rewriting calculation engine

**CustomPage Model:**
- Exists in Phase 1 (stores section order)
- Gains per-page state in Phase 2A (active effects, mode selections, mental allocations)
- Phase 1 design must anticipate this expansion

---

## Reference from Claude.md

Phase 1 developers should:
- ✅ Design data models with Phase 2A optional fields
- ✅ Use extensible calculation patterns
- ✅ Consider per-page state architecture
- ❌ Do NOT implement Phase 2A features yet
- ❌ Do NOT let Phase 2A complexity influence Phase 1 UI

This file preserves architectural context while keeping Phase 1 focused and simple.
