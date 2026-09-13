# Pickmoji: web demo page prompt for dickonkent.com/pickmoji

Run this in the **dickonkent.com repo** (Astro). The Pickmoji app repo is at `~/Sites/pickmoji`. Build a page at `/pickmoji` that presents the app and includes a **live, in-browser version of the picker** that visitors can use without installing anything.

## First, learn the site. Report back before writing code
- Look at how pages, layouts, and any existing Labs/project pages are structured, and whether the site already uses a UI framework for islands (Preact/React/Svelte) or plain `<script>` tags. Use what's already there. Don't add a framework just for this page.
- Reuse existing design tokens: Instrument Serif + IBM Plex Sans (Fontsource), the Prussian blue accent, spacing, and the existing header/footer. No new fonts or color systems.
- Tell me where a Labs index lives (if one exists) and how this page should link from it. Then wait for my go-ahead.

## Data (shared with the Mac app)
- Use the same trimmed emojibase JSON the Mac app bundles (`~/Sites/pickmoji/Pickmoji/Resources/…`; find the actual path). Add `scripts/sync-pickmoji-data.mjs` that copies it into this site (e.g. `public/pickmoji/emoji.json`), so both use one source of truth. Don't hotlink GitHub or a CDN.
- Load the data lazily: fetch it when the demo scrolls into view or on first focus, not on page load. Report the gzipped size.
- Emoji render as text in the visitor's system emoji font. No emoji images. (On Windows/Android they'll look like those platforms' emoji. That's expected and fine.)

## The demo (the centerpiece, near the top)
- A stylized, **original** Mac menu bar strip with a Pickmoji status icon (use an SF-Symbol-like smiley drawn in SVG; don't copy Apple UI assets or screenshots), and the popover open beneath it by default.
- The demo should behave like the app:
  - A search field, auto-focused only after the visitor clicks into the demo (never steal focus on page load).
  - Category-grouped grid; prefix matches rank above substring matches.
  - Arrow keys move the selection, Return copies, Esc clears the search.
  - Click copies the emoji with `navigator.clipboard.writeText`, shows "Copied 😀", and falls back gracefully if the clipboard API is unavailable.
  - Recent/frequent row stored in `localStorage` (wrap reads and writes in try/catch).
  - Default skin-tone selector; right-click or long-press an emoji that supports skins for a one-off tone.
- Optional detail: show the hotkey hint (⌃⌥E) and let that combo toggle the demo popover while the page is focused. Skip it if it conflicts with browser shortcuts.
- Port the logic (search ranking, frecency, skin variants) faithfully from the Swift code so the demo matches the real app, and note any intentional differences in a code comment.
- Accessible: grid uses proper roles/labels (each button's accessible name is the emoji's label), visible focus ring, respects `prefers-reduced-motion`, and works at 400px wide. On narrow screens, drop the menu bar framing and show just the popover.

## Page sections (below the demo)
1. One-line pitch plus the Download button (the latest GitHub Release DMG) and a "View source" link.
2. What it does: 3–4 short feature points (search, click to copy, recents, skin tones, hotkey).
3. Install notes: macOS version requirement; the honest unsigned-build note (macOS 15+ → try to open once, then System Settings → Privacy & Security → "Open Anyway"). Keep this section easy to remove once the builds are notarized.
4. Privacy: no network access, no analytics in the app.
5. Credits and licenses: emojibase (MIT), Unicode CLDR (Unicode License v3), KeyboardShortcuts (MIT); the app is MIT.
6. Short "why I built it" slot. **Leave it as a clearly marked placeholder for me to write.**

## Copy guardrail (important)
- Every factual claim on the page (features, requirements, file size, version, license) must come from the Pickmoji repo's README, code, or release. If you can't verify something there, put a `TODO(dickon):` placeholder. Don't invent it. No marketing superlatives, no made-up stats or testimonials.
- No em dashes in the page copy.

## Also
- Page metadata: title, description, Open Graph image placeholder (1200×630) using the site's existing OG pattern.
- Don't add analytics or tracking beyond what the site already has.
- Verify: `astro build` passes, the page works in the dev server, keyboard-only use works, copying works, and it looks right at 400px and desktop widths. Tell me what you tested and what I need to check by hand (e.g. Safari clipboard behavior).
- Commit on a branch, don't push.
