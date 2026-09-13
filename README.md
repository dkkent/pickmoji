# Pickmoji

A tiny macOS menu bar app for finding an emoji and copying it to the clipboard.

Press **⌃⌥E** (or click the 🙂 in the menu bar), type a few letters, press
Return. The emoji is on your clipboard and the popover is gone.

![Pickmoji screenshot placeholder](docs/screenshot.png)

- Search by name or keyword; prefix matches rank first
- Arrow keys to move, Return to copy, Esc to close
- Recently used row, ranked by how often and how recently
- Default skin tone setting, or Option-click / right-click any emoji for a one-off tone
- Configurable global hotkey, launch at login
- No network access, no analytics, no bundled emoji images (macOS draws them)

Requires macOS 13 Ventura or later. Universal (Apple silicon and Intel).

## Install from the DMG

1. Download `Pickmoji-<version>.dmg` from the
   [latest release](../../releases/latest).
2. Open it and drag **Pickmoji** to **Applications**.
3. Open Pickmoji. It lives in the menu bar; there is no Dock icon or window.

### Verify the checksum

Each release ships a `.sha256` file next to the DMG:

```sh
cd ~/Downloads
shasum -a 256 -c Pickmoji-<version>.dmg.sha256
```

You should see `Pickmoji-<version>.dmg: OK`.

### Unsigned build

Releases are currently ad-hoc signed and not notarized, so Gatekeeper will
refuse to open the app the first time. On macOS 15 and later, Control-click →
Open no longer bypasses this. Either:

1. Try to open Pickmoji once (it will be blocked), then go to
   **System Settings → Privacy & Security**, scroll down, and click
   **Open Anyway** next to the Pickmoji message.

or remove the quarantine flag from Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/Pickmoji.app
```

If you would rather not trust a downloaded binary, build it from source below.

## Build from source

Requires Xcode 26 or later and [XcodeGen](https://github.com/yonaslab/XcodeGen)
(`brew install xcodegen`).

```sh
git clone <this repo> && cd pickmoji
./build.sh --install
```

That generates the Xcode project, builds a Release universal binary, and
copies `Pickmoji.app` to `/Applications`. Without `--install` it only builds
into `build/Build/Products/Release/`.

To work on it in Xcode: `xcodegen generate && open Pickmoji.xcodeproj`.

Run the tests with `xcodebuild -scheme Pickmoji test`.

## Emoji data

Names and keywords come from
[emojibase-data](https://github.com/milesj/emojibase) 17.0.0 (MIT), which
derives them from Unicode CLDR (Unicode License v3). The bundled JSON is
trimmed by `scripts/update-emoji-data.sh`; see
[Pickmoji/Resources/DATA_SOURCE.md](Pickmoji/Resources/DATA_SOURCE.md) for
what is kept and how emoji the current OS cannot render are filtered out.

## License

MIT. See [LICENSE](LICENSE) and the third-party notices in
[LICENSES/](LICENSES/).
