#!/usr/bin/env bash
# Builds a Release DMG in dist/. Signs and notarizes when DEVELOPER_ID_APPLICATION
# and NOTARY_PROFILE are set; otherwise ad-hoc signs and warns.
set -euo pipefail

cd "$(dirname "$0")/.."

./build.sh

APP="build/Build/Products/Release/Pickmoji.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
DMG="dist/Pickmoji-${VERSION}.dmg"
mkdir -p dist
rm -f "$DMG" "$DMG.sha256"

ARCHS="$(lipo -archs "$APP/Contents/MacOS/Pickmoji")"
case "$ARCHS" in
  *arm64*x86_64*|*x86_64*arm64*) echo "Universal binary: $ARCHS" ;;
  *) echo "Expected a universal binary, got: $ARCHS" >&2; exit 1 ;;
esac

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

SIGNED=0
if [ -n "${DEVELOPER_ID_APPLICATION:-}" ] && [ -n "${NOTARY_PROFILE:-}" ]; then
  SIGNED=1
  echo "Signing app with: $DEVELOPER_ID_APPLICATION"
  codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$APP"
  codesign --verify --deep --strict --verbose=2 "$APP"

  echo "Notarizing app (profile: $NOTARY_PROFILE)..."
  ditto -c -k --keepParent "$APP" "$STAGING/Pickmoji.zip"
  xcrun notarytool submit "$STAGING/Pickmoji.zip" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
else
  echo "WARNING: DEVELOPER_ID_APPLICATION and/or NOTARY_PROFILE not set."
  echo "         Ad-hoc signing; the DMG will NOT be notarized and Gatekeeper will block it."
  codesign --force --deep --options runtime --sign - "$APP"
fi

# Build a writable image, fill it, then convert. `hdiutil create -srcfolder` often
# fails with "Resource busy" because a background scanner holds the temp volume
# for a few seconds; detaching with retries avoids that.
RW_DMG="$STAGING/rw.dmg"
MOUNT="$STAGING/mnt"
APP_SIZE_MB="$(du -sm "$APP" | cut -f1)"
hdiutil create -size "$((APP_SIZE_MB + 20))m" -fs HFS+ -volname "Pickmoji" -ov "$RW_DMG" >/dev/null
mkdir -p "$MOUNT"
DEVICE="$(hdiutil attach -nobrowse -readwrite -mountpoint "$MOUNT" "$RW_DMG" | awk '/^\/dev\// { print $1; exit }')"
cp -R "$APP" "$MOUNT/"
ln -s /Applications "$MOUNT/Applications"
sync
for attempt in $(seq 1 10); do
  hdiutil detach "$DEVICE" >/dev/null 2>&1 && break
  [ "$attempt" = 10 ] && { echo "Could not detach $DEVICE after 10 attempts" >&2; exit 1; }
  sleep 2
done
hdiutil convert "$RW_DMG" -format UDZO -ov -o "$DMG" >/dev/null
echo "Created $DMG"

if [ "$SIGNED" = 1 ]; then
  echo "Signing and notarizing DMG..."
  codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$DMG"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"

  echo "Gatekeeper assessment:"
  spctl -a -vv "$APP"
  spctl -a -vv -t open --context context:primary-signature "$DMG"
fi

(cd dist && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "Checksum: $(cat "$DMG.sha256")"

if [ "$SIGNED" = 0 ]; then
  echo
  echo "WARNING: This build is unsigned. See the 'Unsigned build' section of README.md"
  echo "         for how users can open it."
fi
