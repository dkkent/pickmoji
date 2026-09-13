import Foundation

struct Emoji: Codable, Hashable, Identifiable {
    struct Skin: Codable, Hashable {
        let emoji: String
        let tone: Int
    }

    let emoji: String
    let label: String
    let tags: [String]
    let group: Int
    let order: Int
    let skins: [Skin]

    var id: String { emoji }
    var supportsSkinTones: Bool { !skins.isEmpty }

    func variant(for tone: SkinTone) -> String {
        guard tone != .none else { return emoji }
        return skins.first { $0.tone == tone.rawValue }?.emoji ?? emoji
    }
}

enum SkinTone: Int, CaseIterable, Codable, Identifiable {
    case none = 0
    case light
    case mediumLight
    case medium
    case mediumDark
    case dark

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .none: return "Default"
        case .light: return "Light"
        case .mediumLight: return "Medium-light"
        case .medium: return "Medium"
        case .mediumDark: return "Medium-dark"
        case .dark: return "Dark"
        }
    }

    var modifier: String {
        switch self {
        case .none: return ""
        case .light: return "\u{1F3FB}"
        case .mediumLight: return "\u{1F3FC}"
        case .medium: return "\u{1F3FD}"
        case .mediumDark: return "\u{1F3FE}"
        case .dark: return "\u{1F3FF}"
        }
    }

    var sample: String { "\u{1F44B}" + modifier }
}

enum EmojiGroup: Int, CaseIterable, Identifiable {
    case smileys = 0
    case people = 1
    case component = 2
    case animals = 3
    case food = 4
    case travel = 5
    case activities = 6
    case objects = 7
    case symbols = 8
    case flags = 9

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .smileys: return "Smileys & Emotion"
        case .people: return "People & Body"
        case .component: return "Components"
        case .animals: return "Animals & Nature"
        case .food: return "Food & Drink"
        case .travel: return "Travel & Places"
        case .activities: return "Activities"
        case .objects: return "Objects"
        case .symbols: return "Symbols"
        case .flags: return "Flags"
        }
    }
}
