import Foundation

final class UsageStore: ObservableObject {
    struct Record: Codable, Equatable {
        var count: Int
        var lastUsed: Date
    }

    static let defaultsKey = "usage"

    @Published private(set) var records: [String: Record]

    private let defaults: UserDefaults
    private let now: () -> Date

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        if let data = defaults.data(forKey: Self.defaultsKey),
           let stored = try? JSONDecoder().decode([String: Record].self, from: data) {
            records = stored
        } else {
            records = [:]
        }
    }

    func record(_ emoji: String) {
        let current = records[emoji] ?? Record(count: 0, lastUsed: now())
        records[emoji] = Record(count: current.count + 1, lastUsed: now())
        persist()
    }

    func clear() {
        records = [:]
        persist()
    }

    func top(_ limit: Int = 16) -> [String] {
        let current = now()
        return records
            .map { (emoji: $0.key, score: Self.score($0.value, now: current), lastUsed: $0.value.lastUsed) }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                if lhs.lastUsed != rhs.lastUsed { return lhs.lastUsed > rhs.lastUsed }
                return lhs.emoji < rhs.emoji
            }
            .prefix(limit)
            .map(\.emoji)
    }

    /// Frecency: use count weighted by how recently the emoji was last used.
    static func score(_ record: Record, now: Date) -> Double {
        let age = now.timeIntervalSince(record.lastUsed)
        let hour = 3600.0
        let weight: Double
        switch age {
        case ..<(4 * hour): weight = 100
        case ..<(24 * hour): weight = 70
        case ..<(3 * 24 * hour): weight = 50
        case ..<(7 * 24 * hour): weight = 30
        case ..<(30 * 24 * hour): weight = 10
        default: weight = 5
        }
        return Double(record.count) * weight
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
