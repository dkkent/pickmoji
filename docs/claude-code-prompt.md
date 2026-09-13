# Pickmoji — Claude Code build prompt (v1)

Build **Pickmoji**, a native macOS menu bar app for searching emoji and copying them to the clipboard. This repo folder is empty; set everything up from scratch.

## Stack and constraints
- Swift + SwiftUI, target macOS 13+.
- Generate the Xcode project with **XcodeGen** (`project.yml` checked in, `.xcodeproj` gitignored). Install it with `brew install xcodegen` if it's missing.
- Menu bar only: `LSUIElement = YES` (no Dock icon, no main window).
- Use **AppKit `NSStatusItem` + `NSPopover`** hosting SwiftUI views. Do NOT use SwiftUI `MenuBarExtra`: it can't be opened programmatically, and the global hotkey needs to toggle the popover.
- Only third-party dependency: `sindresorhus/KeyboardShortcuts` (MIT) via SPM, for the global hotkey.
- No network access at runtime. No analytics.
- Signing: "Sign to Run Locally" (ad-hoc). There is no paid Apple Developer account.

## Emoji data (licensing matters)
- Bundle **emojibase-data** `en/data.json` (MIT; derived from Unicode CLDR, Unicode License v3). Pin a specific version and document where it came from in `Resources/DATA_SOURCE.md`.
- Add a `scripts/update-emoji-data.sh` that downloads the pinned version from npm/jsDelivr and trims it to the fields we use (emoji, label, tags, group, order, skins) so the bundled JSON stays small.
- Render emoji as **text** with the system font. Do NOT bundle any emoji images.
- Hide emoji the current OS can't render: at load time, check each one with CoreText against the Apple Color Emoji font (all glyphs present, and not a multi-glyph fallback for ZWJ sequences) and drop the failures, or filter by emojibase `version` against the running OS. Pick whichever is more reliable and explain the choice.
- Add `LICENSES/` with the emojibase MIT license, the Unicode License v3 text, and the KeyboardShortcuts MIT license. Put the app's own `LICENSE` (MIT) at the repo root.

## v1 features
1. **Popover** (~360×420): search field at the top, focused automatically when the popover opens. Below it, a scrollable grid of emoji grouped by category, with section headers.
2. **Search**: case-insensitive match on label and tags; prefix matches rank above substring matches. Filter as you type. Arrow keys move the selection, Return copies, Esc closes.
3. **Click to copy**: write the emoji to `NSPasteboard.general` as plain text, show a brief "Copied 😀" confirmation, then close the popover after ~0.4s.
4. **Recent/frequent row**: pinned at the top when the search is empty. Track use counts plus last-used time in `UserDefaults`; show the top 16, sorted by a simple frecency score. Put a "Clear recents" item in settings.
5. **Skin tones**: a default skin-tone setting (none plus 5 tones) applies to every emoji that supports skins. Option-click or right-click an emoji that supports skins to open a small tone picker for a one-off choice. Store the default in `UserDefaults`.
6. **Global hotkey**: default ⌃⌥E (confirm it doesn't clash with common system shortcuts), configurable with the KeyboardShortcuts recorder in settings. It toggles the popover anchored to the status item.
7. **Settings**: a small settings view (gear button in the popover footer): hotkey recorder, default skin tone, launch at login (`SMAppService.mainApp`), clear recents, an About/credits section listing the data and library licenses, and Quit.
8. **Status item icon**: a simple SF Symbol (e.g. `face.smiling`) as a template image so it follows light/dark menu bar.

## Code organization
- `EmojiStore` (loads, filters, searches), `UsageStore` (recents/frecency), `Settings` (UserDefaults-backed), `StatusItemController` (NSStatusItem/NSPopover/hotkey), SwiftUI views for grid, search, tone picker, settings.
- Keep search fast: precompute a lowercase search index at load time; no per-keystroke JSON work.

## Verification (do all of these before you say it's done)
- `xcodegen generate && xcodebuild -scheme Pickmoji -configuration Release build` succeeds with no warnings you introduced.
- Unit tests (XCTest) for: search ranking, frecency ordering, skin-tone variant selection, and the unrenderable-emoji filter.
- Launch the built app and confirm: the icon appears in the menu bar, the popover opens, search works, click copies, recents update, and the hotkey toggles the popover. Tell me exactly what you checked by running it and what I still need to check by hand.

## Release packaging (signing-agnostic)
Build packaging so it works today without a paid Apple Developer account, and upgrades to full Developer ID signing later just by setting env vars. Don't restructure anything.
- Build a **Universal** binary (arm64 + x86_64): `ONLY_ACTIVE_ARCH=NO` for Release. Verify with `lipo -archs`.
- Enable Hardened Runtime in the target (notarization requires it, and it doesn't hurt ad-hoc builds).
- `scripts/package.sh`:
  - Release build → `dist/Pickmoji-<version>.dmg` with a drag-to-Applications alias (use `hdiutil`; no extra dependencies), plus `dist/Pickmoji-<version>.dmg.sha256`.
  - If `DEVELOPER_ID_APPLICATION` (signing identity) and `NOTARY_PROFILE` (a `notarytool` keychain profile) are set: sign the app and the DMG separately with `--options runtime --timestamp`, submit with `xcrun notarytool submit --wait`, then `xcrun stapler staple` both the app and the DMG, and run `xcrun stapler validate` and `spctl -a -vv` as checks.
  - Otherwise, ad-hoc sign (`codesign --force --deep -s -`) and print a clear warning that the build is unsigned.
- Add a `build.sh --install` convenience script that builds Release and copies the app to `/Applications` for people building from source.
- README: what it does, a screenshot/GIF placeholder, install from DMG, build from source (`./build.sh --install`), and how to verify the checksum. Include an "Unsigned build" section: on macOS 15+, Control-click → Open no longer works. Users must try to open it once, then go to System Settings → Privacy & Security → "Open Anyway", or run `xattr -dr com.apple.quarantine /Applications/Pickmoji.app`. Remove that section once the builds are notarized.
- Put the release steps in `RELEASING.md`: bump the version, run package.sh, create a GitHub Release with the DMG and checksum. Don't set up a Homebrew cask while builds are unsigned (Homebrew is deprecating unsigned casks).

Git: initialize the repo, commit in logical steps, and don't push anywhere.
