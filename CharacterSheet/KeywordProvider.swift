import Foundation

protocol KeywordProvider {
    var keywordsForRules: [String] { get }
}

enum KeywordUtil {
    nonisolated static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
