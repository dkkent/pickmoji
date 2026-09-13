#!/usr/bin/env bash
# Builds Pickmoji (Release, universal). With --install, copies it to /Applications.
set -euo pipefail

cd "$(dirname "$0")"

INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    -h|--help)
      echo "usage: ./build.sh [--install]"
      exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

command -v xcodegen >/dev/null || { echo "xcodegen is required: brew install xcodegen" >&2; exit 1; }
xcode-select -p | grep -q "Xcode.app" || {
  echo "Full Xcode is required (xcode-select currently points at $(xcode-select -p))." >&2
  echo "Install Xcode, then: sudo xcode-select -s /Applications/Xcode.app" >&2
  exit 1
}

xcodegen generate
xcodebuild -quiet -scheme Pickmoji -configuration Release -derivedDataPath build \
  ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY="-" build

APP="build/Build/Products/Release/Pickmoji.app"
echo "Built $APP ($(lipo -archs "$APP/Contents/MacOS/Pickmoji"))"

if [ "$INSTALL" = 1 ]; then
  if pgrep -xq Pickmoji; then
    echo "Quitting running Pickmoji..."
    osascript -e 'quit app "Pickmoji"' || pkill -x Pickmoji || true
    sleep 1
  fi
  rm -rf /Applications/Pickmoji.app
  cp -R "$APP" /Applications/Pickmoji.app
  echo "Installed /Applications/Pickmoji.app"
  echo "Launch it from /Applications or with: open -a Pickmoji"
fi
