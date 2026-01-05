import Foundation

protocol KeywordProvider {
    var keywordsForRules: [String] { get }
}

enum KeywordUtil {
    nonisolated static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Converts category names to singular keyword form
    /// Example: "Natural Skills" → "natural skill", "Lores" → "lore"
    nonisolated static func categoryToKeyword(_ category: String) -> String {
        let normalized = normalize(category)

        // Convert plural category names to singular keyword form
        if normalized == "natural skills" { return "natural skill" }
        if normalized == "learned skills" { return "learned skill" }
        if normalized == "lores" { return "lore" }
        if normalized == "tongues" { return "tongue" }

        // Otherwise return as-is (e.g., "Body", "Mind", "Spirit", "Occult")
        return normalized
    }

    nonisolated static func splitUserKeywords(_ s: String) -> [String] {
        s.split(separator: ",")
            .map { normalize(String($0)) }
            .filter { !$0.isEmpty }
    }

    nonisolated static func make(base: [String], user: String) -> [String] {
        var set = Set(base.map(normalize))
        set.formUnion(splitUserKeywords(user))
        return Array(set).sorted()
    }
}

