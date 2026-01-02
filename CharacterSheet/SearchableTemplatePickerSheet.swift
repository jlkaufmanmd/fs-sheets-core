import SwiftUI
import SwiftData

/// A lightweight searchable picker presented as a sheet.
/// Use this anywhere you need "tap to choose a template" with an inline search field.
struct SearchableTemplatePickerSheet<Item: Identifiable>: View {
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let prompt: String
    let items: [Item]
    
    /// Primary label (what shows as the row title).
    let name: (Item) -> String
    
    /// Optional secondary label (row subtitle).
    let subtitle: ((Item) -> String)?
    
    /// Called when user selects an item.
    let onPick: (Item) -> Void
    
    @State private var searchText: String = ""
    
    init(
        title: String,
        prompt: String = "Search…",
        items: [Item],
        name: @escaping (Item) -> String,
        subtitle: ((Item) -> String)? = nil,
        onPick: @escaping (Item) -> Void
    ) {
        self.title = title
        self.prompt = prompt
        self.items = items
        self.name = name
        self.subtitle = subtitle
        self.onPick = onPick
    }
    
    private var filtered: [Item] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }
        return items.filter { name($0).localizedCaseInsensitiveContains(q) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search.")
                    )
                } else {
                    ForEach(filtered) { item in
                        Button {
                            onPick(item)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(name(item))
                                if let subtitle, !subtitle(item).isEmpty {
                                    Text(subtitle(item))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: prompt)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
