import XCTest
@testable import Pickmoji

final class SkinToneTests: XCTestCase {
    private let wave = Emoji(
        emoji: "👋", label: "waving hand", tags: ["hand", "wave"], group: 1, order: 1,
        skins: [
            .init(emoji: "👋🏻", tone: 1),
            .init(emoji: "👋🏼", tone: 2),
            .init(emoji: "👋🏽", tone: 3),
            .init(emoji: "👋🏾", tone: 4),
            .init(emoji: "👋🏿", tone: 5),
        ]
    )

    private let rocket = Emoji(emoji: "🚀", label: "rocket", tags: [], group: 5, order: 1, skins: [])

    func testDefaultToneReturnsBaseEmoji() {
        XCTAssertEqual(wave.variant(for: .none), "👋")
    }

    func testEachToneSelectsMatchingSkin() {
        XCTAssertEqual(wave.variant(for: .light), "👋🏻")
        XCTAssertEqual(wave.variant(for: .mediumLight), "👋🏼")
        XCTAssertEqual(wave.variant(for: .medium), "👋🏽")
        XCTAssertEqual(wave.variant(for: .mediumDark), "👋🏾")
        XCTAssertEqual(wave.variant(for: .dark), "👋🏿")
    }

    func testEmojiWithoutSkinsIgnoresTone() {
        for tone in SkinTone.allCases {
            XCTAssertEqual(rocket.variant(for: tone), "🚀")
        }
        XCTAssertFalse(rocket.supportsSkinTones)
        XCTAssertTrue(wave.supportsSkinTones)
    }

    func testMissingToneFallsBackToBase() {
        let partial = Emoji(emoji: "👋", label: "waving hand", tags: [], group: 1, order: 1,
                            skins: [.init(emoji: "👋🏻", tone: 1)])
        XCTAssertEqual(partial.variant(for: .dark), "👋")
        XCTAssertEqual(partial.variant(for: .light), "👋🏻")
    }

    func testToneSamplesUseFitzpatrickModifiers() {
        XCTAssertEqual(SkinTone.allCases.count, 6)
        XCTAssertEqual(SkinTone.none.sample, "👋")
        XCTAssertEqual(SkinTone.medium.sample, "👋🏽")
        XCTAssertEqual(SkinTone.allCases.map(\.sample), wave.skins.map(\.emoji).inserting("👋", at: 0))
    }

    func testDefaultToneRoundTripsThroughSettings() {
        let suite = "PickmojiTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let settings = Settings(defaults: defaults)
        XCTAssertEqual(settings.defaultSkinTone, .none)
        settings.defaultSkinTone = .mediumDark
        XCTAssertEqual(Settings(defaults: defaults).defaultSkinTone, .mediumDark)
    }
}

private extension Array {
    func inserting(_ element: Element, at index: Int) -> [Element] {
        var copy = self
        copy.insert(element, at: index)
        return copy
    }
}
