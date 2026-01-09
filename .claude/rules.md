# Coding Rules & Best Practices

## SwiftUI Conventions

### View File Size Limits
**Critical:** Keep view files manageable to avoid compiler issues and maintain readability.

- **Detail Views:** Max 400 lines
  - Break into sections if approaching limit
  - Extract sections into separate files
  - Use `@ViewBuilder` computed properties for complex layouts

- **Section Views:** Max 250 lines
  - One logical section per file (e.g., `SkillsSection.swift`)
  - Include related helper methods in same file
  - Extract reusable rows to separate components

- **Component Views:** Max 150 lines
  - Atomic UI elements (e.g., `StatCell.swift`, `SkillRow.swift`)
  - Should be reusable across multiple contexts
  - Single responsibility principle

- **Edit Views:** Max 200 lines
  - Forms for creating/editing individual items
  - Include validation logic in same file

**When to Extract:**
- View body exceeds 300 lines → Extract sections
- Code is duplicated 3+ times → Extract component
- Logic is complex → Extract to computed property or helper method
- Compiler warns about type-checking → Break into smaller pieces

### View Builder Best Practices

**Use `@ViewBuilder` for computed properties:**
```swift
// ✅ Good - Clean, reusable
@ViewBuilder
private var headerSection: some View {
    HStack {
        Text("Character Info")
        Spacer()
        Button("Edit") { /* ... */ }
    }
}

// ❌ Bad - Forces AnyView or complex type erasure
private var headerSection: AnyView {
    AnyView(
        HStack { /* ... */ }
    )
}
```

**Group related UI:**
```swift
// ✅ Good - Logical grouping
var body: some View {
    Form {
        characterInfoSection
        statsSection
        skillsSection
    }
}

// ❌ Bad - All inline, unreadable
var body: some View {
    Form {
        Section { TextField(...) }
        Section { VStack { HStack { /* 100 lines */ } } }
        // ...
    }
}
```

### State Management Patterns

**@State - UI-only state that doesn't persist:**
```swift
// ✅ Good - Expansion state, sheet presentation
@State private var isExpanded = false
@State private var showingAddSheet = false
@State private var selectedItem: Item?

// ❌ Bad - Don't use for data that should persist
@State private var characterName = ""  // Will be lost on view recreation
```

**@Bindable - For SwiftData model edits:**
```swift
// ✅ Good - Direct binding to model
@Bindable var character: RPGCharacter

TextField("Name", text: $character.name)  // Auto-saves to SwiftData

// ❌ Bad - Unnecessary intermediate state
@State private var tempName = ""
// Then manually sync tempName back to character
```

**@Query - For fetching SwiftData:**
```swift
// ✅ Good - Sorted, filtered queries
@Query(sort: \RPGCharacter.name) private var characters: [RPGCharacter]
@Query(filter: #Predicate<Skill> { $0.category == "Combat" })
private var combatSkills: [Skill]

// ❌ Bad - Fetching in view body
var body: some View {
    let chars = modelContext.fetch(/* ... */)  // Don't do this
}
```

**@Environment - For system services:**
```swift
// ✅ Good - Standard pattern
@Environment(\.modelContext) private var modelContext
@Environment(\.dismiss) private var dismiss

// Operations
modelContext.insert(newCharacter)
modelContext.delete(oldCharacter)
dismiss()
```

### Binding Patterns

**Creating bindings from Set/Dictionary:**
```swift
// ✅ Good - Explicit get/set
@State private var expandedIDs: Set<PersistentModelID> = []

func makeBinding(for id: PersistentModelID) -> Binding<Bool> {
    Binding(
        get: { expandedIDs.contains(id) },
        set: { isExpanded in
            if isExpanded {
                expandedIDs.insert(id)
            } else {
                expandedIDs.remove(id)
            }
        }
    )
}

// ❌ Bad - Loses state on view refresh
@State private var isExpanded = false
// Used directly without tracking which item
```

**Passing bindings to child views:**
```swift
// ✅ Good - Child can modify parent state
struct ParentView: View {
    @State private var count = 0

    var body: some View {
        ChildView(count: $count)
    }
}

struct ChildView: View {
    @Binding var count: Int

    var body: some View {
        Button("Increment") { count += 1 }
    }
}
```

### Navigation Patterns

**iOS 17+ NavigationStack:**
```swift
// ✅ Good - Type-safe navigation
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            CharacterListView()
                .navigationDestination(for: RPGCharacter.self) { character in
                    CharacterDetailView(character: character)
                }
        }
    }
}

// ❌ Bad - Avoid NavigationView (deprecated)
NavigationView {
    CharacterListView()
}
```

**Sheets and Alerts:**
```swift
// ✅ Good - Boolean for simple sheets
@State private var showingAddCharacter = false

.sheet(isPresented: $showingAddCharacter) {
    AddCharacterView()
}

// ✅ Good - Optional item for sheets with data
@State private var editingCharacter: RPGCharacter?

.sheet(item: $editingCharacter) { character in
    EditCharacterView(character: character)
}
```

## SwiftData Conventions

### Model Declarations

**Basic model structure:**
```swift
// ✅ Good - Explicit relationships, cascade deletes
@Model
final class RPGCharacter {
    var name: String
    var createdDate: Date

    @Relationship(deleteRule: .cascade, inverse: \Stat.character)
    var stats: [Stat] = []

    @Relationship(deleteRule: .cascade, inverse: \CharacterSkill.character)
    var skills: [CharacterSkill] = []

    init(name: String) {
        self.name = name
        self.createdDate = Date()
    }
}
```

**CloudKit-ready models:**
```swift
// ✅ Good - Only supported types, proper relationships
@Model
final class SkillTemplate {
    var id: UUID  // Unique identifier
    var name: String
    var category: String
    var createdDate: Date
    var modifiedDate: Date

    @Relationship(inverse: \TemplateLibrary.skillTemplates)
    var library: TemplateLibrary?

    // ❌ Bad - Avoid unsupported types
    // var metadata: [String: Any]  // Not supported by CloudKit
    // var customStruct: MyCustomType  // Must be Codable and stored as Data
}
```

**Unique constraints:**
```swift
// ⚠️ Careful - Unique constraints prevent multi-scope templates
// DON'T use @Attribute(.unique) if you need local + imported versions

// ❌ Bad for our use case
@Attribute(.unique) var name: String

// ✅ Good - Allow duplicates, filter by scope
var name: String
var templateScope: TemplateScope

// Filter in queries instead:
#Predicate<SkillTemplate> { template in
    template.templateScope == .local && template.name == searchName
}
```

### Relationship Patterns

**One-to-many with cascade delete:**
```swift
// Parent
@Model
final class Character {
    @Relationship(deleteRule: .cascade, inverse: \Stat.character)
    var stats: [Stat] = []
}

// Child
@Model
final class Stat {
    var character: Character?
}
```

**Optional relationships (for templates):**
```swift
@Model
final class CharacterSkill {
    // May reference template, or be override-only
    @Relationship(deleteRule: .nullify, inverse: \SkillTemplate.usages)
    var template: SkillTemplate?

    var overrideName: String?

    var effectiveName: String {
        overrideName ?? template?.name ?? "Unknown"
    }
}
```

### Query Best Practices

**Sorting:**
```swift
// ✅ Good - Sort in @Query
@Query(sort: \RPGCharacter.name) private var characters: [RPGCharacter]

// ❌ Bad - Sorting in view (inefficient for large datasets)
var body: some View {
    ForEach(characters.sorted { $0.name < $1.name }) { char in
        // ...
    }
}
```

**Filtering:**
```swift
// ✅ Good - Predicate filtering
@Query(filter: #Predicate<Skill> { skill in
    skill.category == "Combat" && skill.value > 5
}) private var eliteCombatSkills: [Skill]

// ⚠️ Acceptable - Post-filter for complex logic
@Query private var allSkills: [Skill]
private var eliteCombatSkills: [Skill] {
    allSkills.filter { $0.category == "Combat" && $0.value > 5 }
}
```

**Computed queries in views:**
```swift
// ✅ Good - Query in parent, pass filtered data to children
struct CharacterDetailView: View {
    @Bindable var character: RPGCharacter

    private var combatSkills: [CharacterSkill] {
        character.skills.filter { $0.category == "Combat" }
    }

    var body: some View {
        SkillsSection(skills: combatSkills)
    }
}
```

## Component Architecture

### Section Components

**Template for section views:**
```swift
import SwiftUI
import SwiftData

struct SkillsSection: View {
    @Bindable var character: RPGCharacter
    @Binding var expandedIDs: Set<PersistentModelID>

    var body: some View {
        Section {
            sectionHeader
            skillsList
            addButton
        }
    }

    @ViewBuilder
    private var sectionHeader: some View {
        HStack {
            Text("Skills")
                .font(.headline)
            Spacer()
            Text("\(character.skills.count)")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var skillsList: some View {
        ForEach(character.skills) { skill in
            SkillRow(
                skill: skill,
                isExpanded: makeBinding(for: skill.id)
            )
        }
    }

    private func makeBinding(for id: PersistentModelID) -> Binding<Bool> {
        Binding(
            get: { expandedIDs.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedIDs.insert(id)
                } else {
                    expandedIDs.remove(id)
                }
            }
        )
    }

    // ... add button implementation
}
```

### Row Components

**Template for row views:**
```swift
import SwiftUI
import SwiftData

struct SkillRow: View {
    @Bindable var skill: CharacterSkill
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 4) {
            mainContent
            if isExpanded {
                expandedDetails
            }
        }
        .contextMenu {
            contextMenuItems
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        HStack {
            Text(skill.effectiveName)
                .onTapGesture { isExpanded.toggle() }
            Spacer()
            valueControls
        }
    }

    @ViewBuilder
    private var valueControls: some View {
        Stepper(value: $skill.value, in: 0...20) {
            Text("\(skill.value)")
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let description = skill.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button("Edit") { /* ... */ }
        Button("Duplicate") { /* ... */ }
        Button("Delete", role: .destructive) { /* ... */ }
    }
}
```

## Code Style Guidelines

### Naming Conventions

**Files:**
- Views: `CharacterDetailView.swift`, `SkillRow.swift`
- Models: `RPGCharacter.swift`, `SkillTemplate.swift`
- Services: `ExportService.swift`, `ImportService.swift`
- Extensions: `String+Extensions.swift`, `View+Modifiers.swift`

**Variables:**
- Properties: `camelCase` - `characterName`, `expandedIDs`
- Constants: `camelCase` - `maxSkillValue`, `defaultCategory`
- Private: Prefix with `private` - `private var isExpanded`
- Published/Bindable: No prefix - `@Bindable var character`

**Functions:**
- Actions: Verb phrases - `addSkill()`, `deleteCharacter()`, `validateInput()`
- Computed: Noun phrases - `var effectiveName: String { ... }`
- Helpers: Private and descriptive - `private func makeBinding(for:) -> Binding<Bool>`

### Comments

**When to comment:**
```swift
// ✅ Good - Complex logic needs explanation
// Calculate effective skill value including all modifiers from benefices,
// afflictions, and temporary effects. Cap at maximum of 20.
var effectiveValue: Int {
    let base = baseValue
    let modifiers = activeModifiers.reduce(0) { $0 + $1.value }
    return min(base + modifiers, 20)
}

// ✅ Good - Workarounds need explanation
// SwiftUI compiler can't handle complex expressions in body.
// Extracting to computed property resolves type-checking issue.
@ViewBuilder
private var complexLayout: some View {
    // ...
}

// ❌ Bad - Obvious code doesn't need comments
// Get character name
let name = character.name  // This is obvious
```

**Documentation comments:**
```swift
/// Creates a new skill instance from a template.
///
/// - Parameters:
///   - template: The skill template to instance
///   - character: The character that will own this skill
/// - Returns: A new `CharacterSkill` linked to the template
func createSkill(from template: SkillTemplate, for character: RPGCharacter) -> CharacterSkill {
    // Implementation
}
```

### Code Organization Within Files

**Order of declarations:**
1. Type declaration and inheritance
2. Properties (@State, @Binding, @Query, stored properties)
3. Initializer (if needed)
4. `body` property
5. Computed properties (@ViewBuilder vars)
6. Helper methods (private funcs)
7. Nested types (if any)

**Example:**
```swift
struct CharacterDetailView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Bindable var character: RPGCharacter
    @State private var showingAddSheet = false
    @State private var expandedIDs: Set<PersistentModelID> = []

    // MARK: - Body
    var body: some View {
        Form {
            characterInfoSection
            statsSection
        }
        .navigationTitle(character.name)
    }

    // MARK: - Sections
    @ViewBuilder
    private var characterInfoSection: some View {
        // ...
    }

    // MARK: - Helpers
    private func makeBinding(for id: PersistentModelID) -> Binding<Bool> {
        // ...
    }
}
```

## Error Handling

### SwiftData Operations

**Always handle potential failures:**
```swift
// ✅ Good - Graceful error handling
func deleteCharacter(_ character: RPGCharacter) {
    do {
        modelContext.delete(character)
        try modelContext.save()
    } catch {
        print("Failed to delete character: \(error)")
        // Show alert to user
        showError = true
        errorMessage = "Could not delete character. Please try again."
    }
}

// ⚠️ Acceptable for Phase 1 - SwiftData auto-saves, but explicit is better
func deleteCharacter(_ character: RPGCharacter) {
    modelContext.delete(character)
    // Auto-saves, but no error handling
}
```

### Import/Export Operations

**Validate before processing:**
```swift
// ✅ Good - Validation and error reporting
func importTemplates(from url: URL) throws -> [SkillTemplate] {
    guard url.pathExtension == "fstemplate" else {
        throw ImportError.invalidFileType
    }

    let data = try Data(contentsOf: url)
    let decoded = try JSONDecoder().decode(TemplateExport.self, from: data)

    guard decoded.formatVersion == "1.0" else {
        throw ImportError.unsupportedVersion(decoded.formatVersion)
    }

    return decoded.templates
}
```

## Performance Guidelines

### View Updates

**Minimize view redraws:**
```swift
// ✅ Good - Specific identity for ForEach
ForEach(skills, id: \.persistentModelID) { skill in
    SkillRow(skill: skill)
}

// ❌ Bad - Equatable forces full comparison on every update
ForEach(skills) { skill in
    SkillRow(skill: skill)
}
```

**Lazy loading for large lists:**
```swift
// ✅ Good - Lazy loading for 50+ items
LazyVStack {
    ForEach(characters) { character in
        CharacterRow(character: character)
    }
}

// ❌ Bad - Eager loading creates all views upfront
VStack {
    ForEach(characters) { character in
        CharacterRow(character: character)
    }
}
```

### Data Fetching

**Fetch only what you need:**
```swift
// ✅ Good - Query with sort and filter
@Query(
    filter: #Predicate<Skill> { $0.category == "Combat" },
    sort: \Skill.name
) private var combatSkills: [Skill]

// ❌ Bad - Fetch everything, filter in memory
@Query private var allSkills: [Skill]
private var combatSkills: [Skill] {
    allSkills.filter { $0.category == "Combat" }.sorted { $0.name < $1.name }
}
```

## Testing Considerations

### Manual Testing Checklist

**For each feature:**
- [ ] Test on iPhone SE (smallest screen)
- [ ] Test on iPhone 15 (standard screen)
- [ ] Test on iPad Pro (largest screen)
- [ ] Test with empty data (new user)
- [ ] Test with full data (many characters, skills, etc.)
- [ ] Test edge cases (very long names, max values, etc.)
- [ ] Test rotation (portrait and landscape on iPad)

**Data operations:**
- [ ] Create → Verify saved
- [ ] Edit → Verify changes persist
- [ ] Delete → Verify cascade deletes
- [ ] Export → Verify file is valid
- [ ] Import → Verify data loads correctly

### Code Review Checklist

Before committing:
- [ ] No compiler warnings
- [ ] No force unwraps (`!`) without justification
- [ ] All view files under size limits
- [ ] Proper use of @State vs @Bindable vs @Query
- [ ] Relationships have inverse declarations
- [ ] Delete rules are appropriate (cascade vs nullify)
- [ ] Error handling for file operations
- [ ] Comments for complex logic

## Phase 1 Specific Rules

### What to Build Now
- ✅ Local-only persistence
- ✅ Export/import functionality
- ✅ Template system with local and imported scopes
- ✅ Section-based view architecture
- ✅ Basic page customization (show/hide sections)

### What to Defer
- ❌ CloudKit sync (Phase 2)
- ❌ User authentication (Phase 2)
- ❌ Campaign management (Phase 2)
- ❌ Real-time collaboration (Phase 2)
- ❌ Advanced page builder (Phase 3)
- ❌ Mac-specific features (Phase 3)

### CloudKit-Ready Patterns (Use Now, Enables Phase 2)
- ✅ Track createdDate and modifiedDate on all models
- ✅ Use explicit inverse relationships
- ✅ Include owner/creator fields (even if unused in Phase 1)
- ✅ Use UUID for cross-device identity
- ✅ Avoid unsupported types (use Data for complex objects)

## Anti-Patterns to Avoid

**Don't:**
- ❌ Create 500+ line view files (extract sections)
- ❌ Use `@State` for persisted data (use @Bindable + SwiftData)
- ❌ Use `AnyView` (use @ViewBuilder instead)
- ❌ Put business logic in views (extract to models or services)
- ❌ Force unwrap optionals without justification (use `guard` or `if let`)
- ❌ Hardcode template data (use data-driven approach)
- ❌ Skip inverse relationships on SwiftData models (breaks CloudKit sync)
- ❌ Use `@Attribute(.unique)` on templates (prevents multi-scope)

## Summary

**Key Principles:**
1. **Keep views small** - Under 400 lines for detail views, under 150 for components
2. **Use proper state** - @State for UI, @Bindable for models, @Query for fetching
3. **Design for CloudKit** - Even in Phase 1, use CloudKit-ready patterns
4. **Section-based architecture** - Break complex views into logical sections
5. **Data-driven content** - No hardcoded templates, use registry pattern
6. **Export/import first** - Build sharing before sync
7. **iOS first, Mac later** - Mobile is primary, desktop is enhancement
8. **Incremental delivery** - Ship features one at a time, test frequently
