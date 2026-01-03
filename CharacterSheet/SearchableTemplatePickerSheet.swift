import SwiftUI

struct SearchableTemplatePickerSheet<Item: Identifiable>: View {
    let title: String
    let prompt: String?
    let items: [Item]
    let name: (Item) -> String
    let subtitle: (Item) -> String?
    let onPick: (Item) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    init(
        title: String,
        prompt: String? = nil,
        items: [Item],
        name: @escaping (Item) -> String,
        subtitle: @escaping (Item) -> String? = { _ in nil },
        onPick: @escaping (Item) -> Void
    ) {
        self.title = title
        self.prompt = prompt
        self.items = items
        self.name = name
        self.subtitle = subtitle
        self.onPick = onPick
    }

    private var filteredItems: [Item] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }
        return items.filter { name($0).localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            List {
                if let prompt, !prompt.isEmpty {
                    Section {
                        Text(prompt)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    ForEach(filteredItems) { item in
                        Button {
                            onPick(item)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name(item))
                                    .foregroundStyle(.primary)

                                if let sub = subtitle(item), !sub.isEmpty {
                                    Text(sub)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
