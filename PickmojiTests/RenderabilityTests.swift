import XCTest
@testable import Pickmoji

final class RenderabilityTests: XCTestCase {
    func testPlainEmojiIsRenderable() {
        XCTAssertTrue(EmojiRenderability.isRenderable("😀"))
        XCTAssertTrue(EmojiRenderability.isRenderable("❤️"))
    }

    func testSequencesTheFontSupportsAreRenderable() {
        XCTAssertTrue(EmojiRenderability.isRenderable("🇬🇧"), "flag")
        XCTAssertTrue(EmojiRenderability.isRenderable("1️⃣"), "keycap")
        XCTAssertTrue(EmojiRenderability.isRenderable("👨‍👩‍👧‍👦"), "ZWJ family")
        XCTAssertTrue(EmojiRenderability.isRenderable("🏴󠁧󠁢󠁥󠁮󠁧󠁿"), "tag sequence flag")
        XCTAssertTrue(EmojiRenderability.isRenderable("👋🏽"), "skin tone")
    }

    func testTwoGlyphCompositionsAreRenderable() {
        XCTAssertTrue(EmojiRenderability.isRenderable("👩‍❤️‍💋‍👨"), "kiss is drawn as two composed glyphs")
        XCTAssertTrue(EmojiRenderability.isRenderable("🧑🏻‍🤝‍🧑🏿"), "mixed-tone handshake")
    }

    func testUnsupportedSequencesAreNotRenderable() {
        XCTAssertFalse(EmojiRenderability.isRenderable("😀\u{200D}🚀"), "invalid ZWJ sequence falls back to two glyphs")
        XCTAssertFalse(EmojiRenderability.isRenderable("🇦🇦"), "invalid flag pair")
        XCTAssertFalse(EmojiRenderability.isRenderable("\u{10FFFD}"), "no glyph in any font")
        XCTAssertFalse(EmojiRenderability.isRenderable("a"), "not an emoji font glyph")
        XCTAssertFalse(EmojiRenderability.isRenderable(""))
    }

    func testFilterDropsUnrenderableEmojiAndSkins() {
        let good = Emoji(emoji: "👋", label: "waving hand", tags: [], group: 1, order: 1,
                         skins: [.init(emoji: "👋🏻", tone: 1), .init(emoji: "👋\u{200D}🚀", tone: 2)])
        let bad = Emoji(emoji: "😀\u{200D}🚀", label: "bogus", tags: [], group: 0, order: 2, skins: [])

        let filtered = EmojiRenderability.filter([good, bad])
        XCTAssertEqual(filtered.map(\.emoji), ["👋"])
        XCTAssertEqual(filtered[0].skins.map(\.emoji), ["👋🏻"])
    }

    func testBundledDataMostlySurvivesFiltering() throws {
        let data = try Data(contentsOf: EmojiStore.bundledDataURL())
        let all = try EmojiStore.decode(data)
        let kept = EmojiRenderability.filter(all)
        XCTAssertGreaterThan(kept.count, all.count * 9 / 10)
    }
}
