<img src="Pickmoji/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="128" height="128" alt="Pickmoji icon: a cursor booping a smiley">

# Pickmoji

A small Mac app for finding an emoji and copying it, fast.

Press **Control + Option + E** (shown as ⌃⌥E on Mac keyboards), type a few
letters, press Return. The emoji is copied and ready to paste. Pickmoji sits in
the menu bar at the top of your screen, next to the clock. It has no Dock icon
and no window.

- **Search by name or keyword.** Type part of a name, like "heart" or "party".
  Emoji whose names start with what you typed come first.
- **Keyboard or mouse.** Arrow keys move, Return copies, Esc closes. Or just
  click an emoji.
- **Recently used.** The emoji you use most, and most recently, sit in a row at
  the top.
- **Skin tones.** Choose a default skin tone in settings. For a one-time
  change, right-click an emoji (or hold Option and click).
- **Works from any app.** Change the shortcut in settings, and have Pickmoji
  start when you log in.
- **Private.** It never connects to the internet and collects nothing about
  you.

Runs on macOS 13 (Ventura) or newer, on both Apple silicon and Intel Macs.

## Install

1. Download `Pickmoji-<version>.dmg` from the
   [latest release](https://github.com/dkkent/pickmoji/releases/latest). It is
   about 1 MB.
2. Open that file. A window appears showing the Pickmoji icon and an
   Applications folder. Drag the icon onto the folder.
3. Open your Applications folder and double-click Pickmoji. **The first time,
   your Mac will refuse to open it.** That is expected; the next section
   explains why and how to get past it in about a minute.
4. Once it is running, look for the smiley face in the menu bar at the top
   right of your screen. Click it, or press Control + Option + E.

### Your Mac will block it the first time. Here is why, and the fix.

Apple checks and approves apps from developers who pay for an Apple developer
account. Pickmoji does not have that yet, so your Mac treats it as an app from
an unknown developer and refuses to open it. The app is safe: it is free, its
code is all here, and it never connects to the internet. Your Mac just has no
way to know that. Getting Apple's approval is on the to-do list; once that is
done, this section goes away and Pickmoji will open like any other app.

To open it anyway, you only have to do this once:

1. Double-click Pickmoji in your Applications folder. A message says it could
   not be opened. Click **Done** (not "Move to Trash").
2. Open **System Settings**, click **Privacy & Security** in the sidebar, and
   scroll down to the Security section. There is a message about Pickmoji with
   an **Open Anyway** button. Click it.
3. Confirm when your Mac asks. Pickmoji opens, and from now on it opens
   normally.

Older advice on the web says to Control-click the app and choose Open. On
macOS 15 and newer that no longer works; use the steps above.

If you are comfortable with Terminal, this one command does the same thing:

```sh
xattr -dr com.apple.quarantine /Applications/Pickmoji.app
```

### Verify the checksum

Every release comes with a small `.sha256` file next to the DMG. You can use it
to confirm the download was not changed on the way to you. If you do not know
what that is, you can safely skip this.

```sh
cd ~/Downloads
shasum -a 256 -c Pickmoji-<version>.dmg.sha256
```

You should see `Pickmoji-<version>.dmg: OK`.

## Build from source

If you would rather not download a prebuilt app, you can build it yourself.
Requires Xcode 26 or later and [XcodeGen](https://github.com/yonaslab/XcodeGen)
(`brew install xcodegen`).

```sh
git clone https://github.com/dkkent/pickmoji.git && cd pickmoji
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

The emoji pictures themselves are drawn by macOS with its own emoji font. No
emoji artwork is included in this repository.

## License

MIT. See [LICENSE](LICENSE) and the third-party notices in
[LICENSES/](LICENSES/).
