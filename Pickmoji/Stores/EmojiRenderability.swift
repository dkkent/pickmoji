import CoreText
import Foundation

/// Renderable = one CoreText run in Apple Color Emoji, no missing glyphs, one emoji advance wide.
/// Width is the deciding check: Apple composes couples/handshakes from two glyphs in one cell,
/// whereas unsupported ZWJ sequences and invalid flag pairs fall back to two full-width glyphs.
enum EmojiRenderability {
    private static let font = CTFontCreateWithName("Apple Color Emoji" as CFString, 24, nil)
    private static let fontName = CTFontCopyPostScriptName(font) as String
    private static let referenceWidth = lineWidth(for: line("\u{1F600}"))
    private static let widthTolerance = 1.1

    static func isRenderable(_ string: String) -> Bool {
        let line = line(string)
        guard let runs = CTLineGetGlyphRuns(line) as? [CTRun], runs.count == 1 else { return false }
        let run = runs[0]

        let attributes = CTRunGetAttributes(run) as NSDictionary
        guard let runFont = attributes[kCTFontAttributeName],
              CTFontCopyPostScriptName(runFont as! CTFont) as String == fontName
        else { return false }

        let glyphCount = CTRunGetGlyphCount(run)
        guard glyphCount > 0 else { return false }
        var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
        CTRunGetGlyphs(run, CFRange(location: 0, length: glyphCount), &glyphs)
        guard !glyphs.contains(0) else { return false }

        return lineWidth(for: line) <= referenceWidth * widthTolerance
    }

    /// Drops emoji the OS can't draw and strips unrenderable skin variants.
    static func filter(_ emoji: [Emoji]) -> [Emoji] {
        emoji.compactMap { item in
            guard isRenderable(item.emoji) else { return nil }
            let skins = item.skins.filter { isRenderable($0.emoji) }
            if skins.count == item.skins.count { return item }
            return Emoji(emoji: item.emoji, label: item.label, tags: item.tags,
                         group: item.group, order: item.order, skins: skins)
        }
    }

    private static func line(_ string: String) -> CTLine {
        let attributed = NSAttributedString(
            string: string,
            attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
        )
        return CTLineCreateWithAttributedString(attributed)
    }

    private static func lineWidth(for line: CTLine) -> Double {
        CTLineGetTypographicBounds(line, nil, nil, nil)
    }
}
