#!/usr/bin/env bash
# Downloads the pinned emojibase-data release and trims it to the fields
# Pickmoji uses. Run from anywhere; writes Pickmoji/Resources/emoji.json.
set -euo pipefail

EMOJIBASE_VERSION="${EMOJIBASE_VERSION:-17.0.0}"
URL="https://cdn.jsdelivr.net/npm/emojibase-data@${EMOJIBASE_VERSION}/en/data.json"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO_ROOT/Pickmoji/Resources/emoji.json"

command -v jq >/dev/null || { echo "jq is required (brew install jq)" >&2; exit 1; }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "Downloading emojibase-data@${EMOJIBASE_VERSION} ..."
curl -fsSL "$URL" -o "$tmp"

# Keep: emoji, label, tags, group, order, skins (uniform skin tones only).
# Drop: entries without a group (regional indicators) and group 2 (components:
# skin-tone modifiers and hair pieces, which are not pickable on their own).
# Mixed-tone skins (tone is an array) are dropped; the tone picker offers the
# five uniform tones only.
jq -c '
  [ .[]
    | select(.group != null and .group != 2)
    | {
        emoji,
        label,
        tags: (.tags // []),
        group,
        order,
        skins: ([ .skins[]? | select(.tone | type == "number") | { emoji, tone } ])
      }
  ]
  | sort_by(.order)
' "$tmp" > "$OUT"

count="$(jq 'length' "$OUT")"
skins="$(jq '[.[].skins | length] | add' "$OUT")"
size="$(du -h "$OUT" | cut -f1)"
echo "Wrote $OUT"
echo "  $count emoji, $skins skin variants, $size"
echo "Update the version in Pickmoji/Resources/DATA_SOURCE.md if you changed EMOJIBASE_VERSION."
