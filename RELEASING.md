# Releasing Pickmoji

## 1. Bump the version

Edit `project.yml`:

```yaml
MARKETING_VERSION: 1.1.0      # user-facing version
CURRENT_PROJECT_VERSION: 2    # build number, increment every release
```

Commit: `git commit -am "Bump version to 1.1.0"`.

## 2. Package

```sh
./scripts/package.sh
```

This builds a universal Release binary, creates
`dist/Pickmoji-1.1.0.dmg` (drag-to-Applications layout) and
`dist/Pickmoji-1.1.0.dmg.sha256`.

### Unsigned (current default)

With no signing environment set, the app is ad-hoc signed and the script
prints a warning. Ship it, and keep the "Unsigned build" section in the
README.

### Signed and notarized

Once there is a paid Apple Developer account:

```sh
# one-time: store notarization credentials in the keychain
xcrun notarytool store-credentials "pickmoji-notary" \
  --apple-id you@example.com --team-id TEAMID --password app-specific-password

export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="pickmoji-notary"
./scripts/package.sh
```

The script then signs the app with the hardened runtime, notarizes and
staples it, builds the DMG, signs, notarizes and staples the DMG, and runs
`stapler validate` and `spctl -a -vv` on both. Nothing else changes.

After the first notarized release, delete the "Unsigned build" section from
the README.

## 3. Tag and publish

```sh
git tag -a v1.1.0 -m "Pickmoji 1.1.0"
git push origin main --tags
gh release create v1.1.0 dist/Pickmoji-1.1.0.dmg dist/Pickmoji-1.1.0.dmg.sha256 \
  --title "Pickmoji 1.1.0" --notes "What changed..."
```

## 4. Update the website

`dickonkent.com/pickmoji` states the version, DMG size, and a direct download
link. In the site repo, edit `src/pages/pickmoji/index.astro` (the "Download
for Mac" href and the "Version x.y.z" line). If the emoji data changed, also run
`node scripts/sync-pickmoji-data.mjs` there.

## Homebrew

Do not add a Homebrew cask until builds are notarized; Homebrew is
deprecating unsigned casks.

## Updating emoji data

```sh
EMOJIBASE_VERSION=<new version> ./scripts/update-emoji-data.sh
```

Then update the version in `Pickmoji/Resources/DATA_SOURCE.md`, the About
section in `Pickmoji/Views/SettingsView.swift`, and the README.
