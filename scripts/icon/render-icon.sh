#!/usr/bin/env bash
# Renders scripts/icon/icon.svg into the AppIcon asset catalog at every macOS
# size. Needs Google Chrome (headless rasteriser) and sips (macOS built-in).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SVG="$ROOT/scripts/icon/icon.svg"
OUT="$ROOT/Pickmoji/Resources/Assets.xcassets/AppIcon.appiconset"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -x "$CHROME" ] || { echo "Google Chrome not found at $CHROME" >&2; exit 1; }

cat > "$TMP/page.html" <<EOF
<!doctype html><html><head><style>html,body{margin:0;width:1024px;height:1024px;background:transparent}img{display:block}</style></head>
<body><img src="file://$SVG" width="1024" height="1024"></body></html>
EOF

"$CHROME" --headless --disable-gpu --hide-scrollbars --window-size=1024,1024 \
  --default-background-color=00000000 --screenshot="$TMP/icon-1024.png" \
  "file://$TMP/page.html" 2>/dev/null

mkdir -p "$OUT"
rm -f "$OUT"/*.png

# size:scale pairs required by the macOS AppIcon set
entries=""
for spec in 16:1 16:2 32:1 32:2 128:1 128:2 256:1 256:2 512:1 512:2; do
  size="${spec%%:*}"; scale="${spec##*:}"
  px=$((size * scale))
  file="icon_${size}x${size}@${scale}x.png"
  sips -z "$px" "$px" "$TMP/icon-1024.png" --out "$OUT/$file" >/dev/null
  entries="$entries    { \"filename\": \"$file\", \"idiom\": \"mac\", \"scale\": \"${scale}x\", \"size\": \"${size}x${size}\" },
"
done

cat > "$OUT/Contents.json" <<EOF
{
  "images": [
${entries%,
}
  ],
  "info": { "author": "xcode", "version": 1 }
}
EOF

echo "Wrote $(ls "$OUT"/*.png | wc -l | tr -d ' ') icon sizes to $OUT"
