# Snippets

Saved text snippets with clipboard copy and an inline add form.

- Kind: **panel** (`provides.panels.snippets`, label "Snippets")
- Panel file: `ui/SnippetBox.qml` (580x540 base units)
- Value producer: `scripts/snippetbox.sh` (`list`, `add`, `remove`)
- Settings page: `settings/SnippetBoxPage.qml` (Plugins -> Snippets)

## Files

```
snippetbox/
  plugin.json                 manifest (type: shell; provides.panels.snippets)
  defaults.json               snippetbox.items seed (3 snippets)
  scripts/
    snippetbox.sh             list / add / remove + atomic writer
  ui/
    SnippetBox.qml            the panel: list, copy, add form, delete
  settings/
    SnippetBoxPage.qml        item count + storage info
  README.md
```

## How it is consumed

- The shell panel host loads `ui/SnippetBox.qml` through
  `provides.panels.snippets`; the popup name is **snippets**, toggled with
  `qs_manager.sh toggle snippets`.
- At startup the panel runs `scripts/snippetbox.sh list` and renders each
  `{ label, text }` as a row. Clicking a row copies its text with `wl-copy`
  (via a `Process` stdin).
- **Add** opens an inline form (label + multiline text); saving pipes the
  JSON object to `scripts/snippetbox.sh add`. The trash icon calls
  `scripts/snippetbox.sh remove <index>`.
- Both writers go through `jq` into a `mktemp` file, then `mv`, so the settings
  file is never observed half-written.

## Settings

`~/.config/hypr/plugins/snippetbox/settings.json`, scope `snippetbox`:

- `items` — array of `{ label, text }`. Seeded from `defaults.json`; updated by
  the panel.

## Dependencies

`jq`, `wl-copy` (wl-clipboard).
