//
//  GoalRollTemplatePickerSheet.swift
//  CharacterSheet
//
//  Created by Jacob Kaufman on 1/1/26.
//


import SwiftUI
import SwiftData

// MARK: - Goal Roll Template Picker (searchable)
struct GoalRollTemplatePickerSheet: View {
    var templates: [GoalRollTemplate]
    var onPick: (GoalRollTemplate) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var filtered: [GoalRollTemplate] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return templates }
        return templates.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.userKeywords.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { t in
                    Button {
                        onPick(t)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.name)
                            if !t.templateDescription.isEmpty {
                                Text(t.templateDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Goal Roll")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Skill Template Picker (searchable + grouped)
struct SkillTemplatePickerSheet: View {
    var templates: [SkillTemplate]
    var onPick: (SkillTemplate) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private let categoryOrder = ["Learned Skills", "Lores", "Tongues"]

    private var filtered: [SkillTemplate] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return templates }
        return templates.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.category.localizedCaseInsensitiveContains(q) ||
            $0.userKeywords.localizedCaseInsensitiveContains(q)
        }
    }

    private var grouped: [(String, [SkillTemplate])] {
        categoryOrder.compactMap { cat in
            let items = filtered
                .filter { $0.category == cat }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { (cat, items) in
                    Section(cat) {
                        ForEach(items) { t in
                            Button {
                                onPick(t)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.name)
                                    if !t.templateDescription.isEmpty {
                                        Text(t.templateDescription)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Skill")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search skills / lores / tongues")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}