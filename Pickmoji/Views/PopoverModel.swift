import AppKit
import Combine
import Foundation

struct GridSection: Identifiable {
    struct Item: Identifiable, Hashable {
        let id: String
        let emoji: Emoji
    }

    let id: String
    let title: String
    let items: [Item]
}

enum MoveDirection {
    case up, down, left, right
}

@MainActor
final class PopoverModel: ObservableObject {
    static let columns = 8
    static let recentsLimit = 16
    static let closeDelay: TimeInterval = 0.4

    @Published var query = "" {
        didSet { if query != oldValue { rebuild(selectFirst: true) } }
    }
    @Published private(set) var sections: [GridSection] = []
    @Published var selectedID: String?
    @Published var tonePickerID: String?
    @Published private(set) var copiedEmoji: String?
    @Published var showingSettings = false
    @Published private(set) var focusRequest = 0

    let store: EmojiStore
    let usage: UsageStore
    let settings: Settings
    var requestClose: (() -> Void)?

    private var cancellables: Set<AnyCancellable> = []

    init(store: EmojiStore, usage: UsageStore, settings: Settings) {
        self.store = store
        self.usage = usage
        self.settings = settings
        store.$isLoaded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rebuild(selectFirst: false) }
            .store(in: &cancellables)
    }

    var selectedItem: GridSection.Item? {
        guard let id = selectedID else { return nil }
        for section in sections {
            if let item = section.items.first(where: { $0.id == id }) { return item }
        }
        return nil
    }

    func display(_ emoji: Emoji) -> String {
        emoji.variant(for: settings.defaultSkinTone)
    }

    func didOpen() {
        rebuild(selectFirst: false)
        focusRequest += 1
    }

    func reset() {
        query = ""
        selectedID = nil
        tonePickerID = nil
        copiedEmoji = nil
        showingSettings = false
    }

    func rebuild(selectFirst: Bool) {
        var built: [GridSection] = []
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            let recents = usage.top(Self.recentsLimit).compactMap { store.emoji(for: $0) }
            if !recents.isEmpty {
                built.append(GridSection(id: "recents", title: "Recently used",
                                         items: recents.map { .init(id: "recents-\($0.emoji)", emoji: $0) }))
            }
            for (group, emoji) in store.sectionsByGroup {
                built.append(GridSection(id: "group-\(group.rawValue)", title: group.title,
                                         items: emoji.map { .init(id: "g\(group.rawValue)-\($0.emoji)", emoji: $0) }))
            }
        } else {
            let results = store.search(trimmed)
            built.append(GridSection(id: "results", title: "Results",
                                     items: results.map { .init(id: "r-\($0.emoji)", emoji: $0) }))
        }
        sections = built
        if selectFirst {
            selectedID = trimmed.isEmpty ? nil : built.first?.items.first?.id
        } else if selectedItem == nil {
            selectedID = nil
        }
    }

    func move(_ direction: MoveDirection) {
        guard !sections.isEmpty else { return }
        guard let location = location(of: selectedID) else {
            selectedID = sections.first { !$0.items.isEmpty }?.items.first?.id
            return
        }
        let (sectionIndex, itemIndex) = location
        let columns = Self.columns
        let items = sections[sectionIndex].items
        let row = itemIndex / columns
        let column = itemIndex % columns

        switch direction {
        case .left:
            if itemIndex > 0 {
                selectedID = items[itemIndex - 1].id
            } else if let previous = previousSection(before: sectionIndex) {
                selectedID = previous.items.last?.id
            }
        case .right:
            if itemIndex + 1 < items.count {
                selectedID = items[itemIndex + 1].id
            } else if let next = nextSection(after: sectionIndex) {
                selectedID = next.items.first?.id
            }
        case .down:
            let target = (row + 1) * columns + column
            if target < items.count {
                selectedID = items[target].id
            } else if (row + 1) * columns < items.count {
                selectedID = items[items.count - 1].id
            } else if let next = nextSection(after: sectionIndex) {
                selectedID = next.items[min(column, next.items.count - 1)].id
            }
        case .up:
            if row > 0 {
                selectedID = items[(row - 1) * columns + column].id
            } else if let previous = previousSection(before: sectionIndex) {
                let lastRow = (previous.items.count - 1) / columns
                selectedID = previous.items[min(lastRow * columns + column, previous.items.count - 1)].id
            }
        }
    }

    func copySelected() {
        guard let item = selectedItem else { return }
        copy(display(item.emoji), base: item.emoji)
    }

    func copy(_ text: String, base: Emoji) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        usage.record(base.emoji)
        tonePickerID = nil
        copiedEmoji = text
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.closeDelay) { [weak self] in
            guard let self, self.copiedEmoji == text else { return }
            self.requestClose?()
        }
    }

    private func location(of id: String?) -> (Int, Int)? {
        guard let id else { return nil }
        for (sectionIndex, section) in sections.enumerated() {
            if let itemIndex = section.items.firstIndex(where: { $0.id == id }) {
                return (sectionIndex, itemIndex)
            }
        }
        return nil
    }

    private func nextSection(after index: Int) -> GridSection? {
        sections[(index + 1)...].first { !$0.items.isEmpty }
    }

    private func previousSection(before index: Int) -> GridSection? {
        sections[..<index].last { !$0.items.isEmpty }
    }
}
