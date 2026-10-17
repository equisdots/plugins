# Bookmarks

Quick links panel backed by the plugin's own settings file; open with
`xdg-open`.

- Kind: **panel** (`provides.panels.bookmarks`, opened with
  `qs_manager.sh toggle bookmarks`)
- Value producer / writer: `scripts/bookmarks.sh` (jq + atomic `mv`)
- Settings: Plugins -> Bookmarks (`settings/BookmarksPage.qml`)

## Files

```
bookmarks/
  plugin.json                     manifest (type: shell; provides.panels.bookmarks)
  defaults.json                   seed: bookmarks.links[]
  ui/Bookmarks.qml                the panel: list + Add row
  scripts/bookmarks.sh            list / add
  settings/BookmarksPage.qml      settings page
  README.md
```

## Storage

- File: `~/.config/hypr/plugins/bookmarks/settings.json`
- Scope `bookmarks`, key `links` = array of `{ label, url }`.
- Seeded from `defaults.json` by the plugin installer. If the file is missing,
  `scripts/bookmarks.sh` self-seeds from the deployed `defaults.json` (or an
  empty `{"bookmarks":{"links":[]}}`) so `jq` always has a valid document.
- Adding rewrites the file atomically (temp file + `mv`); the panel re-reads it
  after every successful append.

## Behaviour

- Click a row to `xdg-open` its URL.
- The Add row takes a label and a URL (Enter in the URL field appends); the
  label defaults to the URL when left empty.

## Commands

```
bookmarks.sh list                 # JSON array of { label, url }
bookmarks.sh add <label> <url>
```
