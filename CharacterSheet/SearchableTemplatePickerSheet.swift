import SwiftUI

/// A lightweight, reusable picker sheet that includes an inline searchable list.
/// This is the closest “Menu with search” UX that still feels native on iOS.
///
/// Usage:
/// SearchableTemplatePickerSheet(
///   title: "Choose Template",
///   items: templates,
///   itemTitle: { $0.name },
///   itemSubtitle: { $0.templateDescription },
///   sectionTitle: { $0.category }, // optional
///   onSelect: { chosen in ... },
///   onCancel: { ... }
/// )
struct SearchableTemplatePickerSheet<Item: Identifiable>: View {

    let title: String
    let items: [Item]
    let itemTitle: (Item) -> String
    let itemSubtitle: (Item) -> String?
    let sectionTitle: ((Item) -> String?)?
    let onSelect: (Item) -> Void
    let onCancel: () -> Void

    @State private var searchText: String = ""

    init(
        title: String,
        items: [Item],
        itemTitle: @escaping (Item) -> String,
        itemSubtitle: @escaping (Item) -> String? = { _ in nil },
        sectionTitle: ((Item) -> String?)? = nil,
        onSelect: @escaping (Item) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.items = items
        self.itemTitle = itemTitle
        self.itemSubtitle = itemSubtitle
        self.sectionTitle = sectionTitle
        self.onSelect = onSelect
        self.onCancel = onCancel
    }

    private var filtered: [Item] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }

        return items.filter { item in
            let title = itemTitle(item)
            let subtitle = itemSubtitle(item) ?? ""
            return title.localizedCaseInsensitiveContains(q) || subtitle.localizedCaseInsensitiveContains(q)
        }
    }

    private var grouped: [(String, [Item])] {
        guard let sectionTitle else { return [("", filtered)] }

        let pairs: [(String, Item)] = filtered.map { item in
            (sectionTitle(item) ?? "", item)
        }

        let dict = Dictionary(grouping: pairs, by: { $0.0 })
        let keys = dict.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        return keys.map { key in
            (key, (dict[key] ?? []).map { $0.1 })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if grouped.count == 1, grouped.first?.0 == "" {
                    // No sections
                    ForEach(grouped.first?.1 ?? []) { item in
                        row(for: item)
                    }
                } else {
                    // Sectioned
                    ForEach(grouped, id: \.0) { (section, items) in
                        Section(section.isEmpty ? nil : section) {
                            ForEach(items) { item in
                                row(for: item)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for item: Item) -> some View {
        Button {
            onSelect(item)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(itemTitle(item))
                if let subtitle = itemSubtitle(item),
                   !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}
