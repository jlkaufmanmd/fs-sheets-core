import SwiftUI

/// A lightweight searchable picker presented as a sheet.
/// Designed to be compiler-friendly (avoids heavy type inference).
struct SearchableTemplatePickerSheet<Template: Identifiable>: View {
    struct Row: Identifiable {
        let id: Template.ID
        let title: String
        let subtitle: String?
        let section: String
        let value: Template
        let searchText: String
    }

    let title: String
    let prompt: String

    /// Prebuilt rows (grouping + search text baked in).
    private let rows: [Row]

    /// Called when user picks a row.
    let onPick: (Template) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    init(
        title: String,
        prompt: String,
        templates: [Template],
        sectionTitle: (Template) -> String,
        rowTitle: (Template) -> String,
        rowSubtitle: (Template) -> String? = { _ in nil },
        rowSearchText: (Template) -> String = { _ in "" },
        onPick: @escaping (Template) -> Void
    ) {
        self.title = title
        self.prompt = prompt
        self.onPick = onPick

        self.rows = templates.map { t in
            let sec = sectionTitle(t).trimmingCharacters(in: .whitespacesAndNewlines)
            let main = rowTitle(t).trimmingCharacters(in: .whitespacesAndNewlines)
            let sub = rowSubtitle(t)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let extra = rowSearchText(t).trimmingCharacters(in: .whitespacesAndNewlines)

            let combinedSearch = ([main, sub, sec, extra]
                .compactMap { $0 }
                .joined(separator: " ")
                .lowercased()
            )

            return Row(
                id: t.id,
                title: main,
                subtitle: (sub?.isEmpty == true) ? nil : sub,
                section: sec.isEmpty ? "Other" : sec,
                value: t,
                searchText: combinedSearch
            )
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredRows.isEmpty {
                    ContentUnavailableView("No matches", systemImage: "magnifyingglass", description: Text("Try a different search."))
                } else {
                    ForEach(sectionNames, id: \.self) { section in
                        let sectionRows = filteredRowsBySection[section] ?? []
                        if !sectionRows.isEmpty {
                            Section {
                                ForEach(sectionRows) { row in
                                    TemplateRowView(row: row) {
                                        onPick(row.value)
                                        dismiss()
                                    }
                                }
                            } header: {
                                Text(section)
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .top) {
                if !prompt.isEmpty {
                    Text(prompt)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        .background(.ultraThinMaterial)
                }
            }
        }
    }

    private var filteredRows: [Row] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return rows.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending } }
        return rows
            .filter { $0.searchText.contains(q) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private var filteredRowsBySection: [String: [Row]] {
        Dictionary(grouping: filteredRows, by: { $0.section })
    }

    private var sectionNames: [String] {
        filteredRowsBySection.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

private struct TemplateRowView<TemplateID: Hashable>: View {
    let row: SearchableTemplatePickerSheet<AnyIdentifiable<TemplateID>>.Row
    let action: () -> Void

    init(
        row: SearchableTemplatePickerSheet<AnyIdentifiable<TemplateID>>.Row,
        action: @escaping () -> Void
    ) {
        self.row = row
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                if let sub = row.subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// Type erasure so TemplateRowView can be compiler-friendly without reintroducing heavy generics.
struct AnyIdentifiable<ID: Hashable>: Identifiable {
    let id: ID
}
