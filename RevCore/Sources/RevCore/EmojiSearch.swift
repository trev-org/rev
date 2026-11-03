import Foundation

/// Ranked shortcode, keyword, and Unicode/CLDR label search.
///
/// Any matching emoji with usage history ranks before an unused match, ordered by descending
/// frecency. Equal frecency (including all never-used emoji) falls back to match quality:
/// exact shortcode > exact keyword/label word > shortcode prefix > keyword/label-word prefix >
/// shortcode/label substring > fuzzy subsequence, then the shorter matched term and emoji
/// database order.
public struct EmojiSearch: Sendable {
    public enum Tier: Int, Comparable, Sendable {
        case exactShortcode = 0
        case exactKeywordOrLabel
        case shortcodePrefix
        case keywordOrLabelPrefix
        case shortcodeOrLabelSubstring
        case fuzzy
        /// Query-free result selected from usage history.
        case history

        public static func < (a: Tier, b: Tier) -> Bool { a.rawValue < b.rawValue }
    }

    public struct Result: Equatable, Sendable {
        public let emoji: Emoji
        /// The shortcode, keyword, label word, or full label that matched.
        public let matchedName: String
        public let tier: Tier

        /// A shortcode suitable for display in the picker.
        public var displayName: String {
            emoji.names.contains(matchedName) ? matchedName : emoji.primaryName
        }
    }

    public let store: EmojiStore
    public let usage: UsageStore?

    public init(store: EmojiStore, usage: UsageStore? = nil) {
        self.store = store
        self.usage = usage
    }

    public func search(_ rawQuery: String, limit: Int = .max) -> [Result] {
        guard limit > 0 else { return [] }
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let usageScores = usage?.scores() ?? [:]
        var scored: [(Result, Double, Int)] = []

        if query.isEmpty {
            // The current app waits for two shortcode characters before opening its picker, but
            // query-free history results make this core API useful to future hotkey/empty states.
            for emoji in store.emoji {
                guard let score = usageScores[emoji.emoji], score > 0 else { continue }
                scored.append((
                    Result(emoji: emoji, matchedName: emoji.primaryName, tier: .history),
                    score,
                    emoji.primaryName.count
                ))
            }
        } else {
            for emoji in store.emoji {
                guard let (tier, name) = Self.match(query, emoji) else { continue }
                scored.append((
                    Result(emoji: emoji, matchedName: name, tier: tier),
                    usageScores[emoji.emoji] ?? 0,
                    name.count
                ))
            }
        }

        scored.sort { a, b in
            if a.1 != b.1 { return a.1 > b.1 }
            if a.0.tier != b.0.tier { return a.0.tier < b.0.tier }
            if a.2 != b.2 { return a.2 < b.2 }
            return a.0.emoji.order < b.0.emoji.order
        }
        return scored.prefix(limit).map { $0.0 }
    }

    static func match(_ q: String, _ e: Emoji) -> (Tier, String)? {
        var best: (Tier, String)?
        func consider(_ t: Tier, _ n: String) {
            if best == nil || t < best!.0 || (t == best!.0 && n.count < best!.1.count) { best = (t, n) }
        }

        let shortcodes = e.names.map { ($0.lowercased(), $0) }
        let keywords = e.keywords.map { ($0.lowercased(), $0) }
        let label = (e.label.lowercased(), e.label)
        let labelWords = words(in: e.label).map { ($0, $0) }

        for (normalized, original) in shortcodes where normalized == q {
            consider(.exactShortcode, original)
        }
        for (normalized, original) in keywords + labelWords where normalized == q {
            consider(.exactKeywordOrLabel, original)
        }
        if !label.0.isEmpty, label.0 == q {
            consider(.exactKeywordOrLabel, label.1)
        }
        for (normalized, original) in shortcodes where normalized.hasPrefix(q) {
            consider(.shortcodePrefix, original)
        }
        for (normalized, original) in keywords + labelWords where normalized.hasPrefix(q) {
            consider(.keywordOrLabelPrefix, original)
        }
        for (normalized, original) in shortcodes where normalized.contains(q) {
            consider(.shortcodeOrLabelSubstring, original)
        }
        if !label.0.isEmpty, label.0.contains(q) {
            consider(.shortcodeOrLabelSubstring, label.1)
        }

        // Fuzzy matching is a fallback only. It must not hide a real keyword or label match.
        if best == nil, q.count >= 2 {
            for (normalized, original) in shortcodes + keywords + labelWords + [label]
            where !normalized.isEmpty && isSubsequence(q, of: normalized) {
                consider(.fuzzy, original)
            }
        }
        return best
    }

    static func words(in value: String) -> [String] {
        value.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    static func isSubsequence(_ q: String, of s: String) -> Bool {
        var it = s.makeIterator()
        outer: for c in q {
            while let x = it.next() { if x == c { continue outer } }
            return false
        }
        return true
    }
}
