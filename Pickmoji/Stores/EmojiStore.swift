import Foundation

struct EmojiSearchIndex {
    private struct Entry {
        let emoji: Emoji
        let label: String
        let words: [String]
        let tags: [String]
    }

    private let entries: [Entry]

    init(emoji: [Emoji]) {
        entries = emoji.map { item in
            let label = item.label.lowercased()
            return Entry(
                emoji: item,
                label: label,
                words: label.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init),
                tags: item.tags.map { $0.lowercased() }
            )
        }
    }

    var all: [Emoji] { entries.map(\.emoji) }

    func search(_ rawQuery: String) -> [Emoji] {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return all }
        let tokens = query.split(separator: " ").map(String.init)

        return entries
            .compactMap { entry -> (tier: Int, order: Int, emoji: Emoji)? in
                guard let tier = tier(for: entry, query: query, tokens: tokens) else { return nil }
                return (tier, entry.emoji.order, entry.emoji)
            }
            .sorted { lhs, rhs in
                lhs.tier != rhs.tier ? lhs.tier < rhs.tier : lhs.order < rhs.order
            }
            .map(\.emoji)
    }

    private func tier(for entry: Entry, query: String, tokens: [String]) -> Int? {
        if entry.label.hasPrefix(query) { return 0 }
        if entry.words.contains(where: { $0.hasPrefix(query) }) { return 1 }
        if entry.tags.contains(where: { $0.hasPrefix(query) }) { return 1 }
        for token in tokens {
            let inLabel = entry.label.contains(token)
            let inTags = entry.tags.contains { $0.contains(token) }
            if !inLabel && !inTags { return nil }
        }
        return entry.label.contains(query) ? 2 : 3
    }
}

final class EmojiStore: ObservableObject {
    @Published private(set) var isLoaded = false
    @Published private(set) var sectionsByGroup: [(group: EmojiGroup, emoji: [Emoji])] = []

    private var index = EmojiSearchIndex(emoji: [])
    private var byString: [String: Emoji] = [:]

    static func bundledDataURL() -> URL {
        guard let url = Bundle.main.url(forResource: "emoji", withExtension: "json") else {
            fatalError("emoji.json is missing from the app bundle")
        }
        return url
    }

    static func decode(_ data: Data) throws -> [Emoji] {
        try JSONDecoder().decode([Emoji].self, from: data)
    }

    func loadInBackground(from url: URL = bundledDataURL()) {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = try! Data(contentsOf: url)
            let emoji = EmojiRenderability.filter(try! Self.decode(data)).sorted { $0.order < $1.order }
            let index = EmojiSearchIndex(emoji: emoji)
            let byString = Dictionary(uniqueKeysWithValues: emoji.map { ($0.emoji, $0) })
            let groups = EmojiGroup.allCases.compactMap { group -> (group: EmojiGroup, emoji: [Emoji])? in
                let members = emoji.filter { $0.group == group.rawValue }
                return members.isEmpty ? nil : (group, members)
            }
            DispatchQueue.main.async {
                self.index = index
                self.byString = byString
                self.sectionsByGroup = groups
                self.isLoaded = true
            }
        }
    }

    func search(_ query: String) -> [Emoji] {
        index.search(query)
    }

    func emoji(for string: String) -> Emoji? {
        byString[string]
    }
}
