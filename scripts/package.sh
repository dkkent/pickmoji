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
  codesign --force --deep --sign - "$APP"
fi

cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -quiet -volname "Pickmoji" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
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
