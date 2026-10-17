# JSON

Paste, pretty-print, minify and copy JSON (pure QML/JS).

```
jsonview/
  plugin.json             manifest (type: shell; provides.panels.json)
  defaults.json           settings seed ("jsonview")
  ui/
    JsonView.qml          the panel: editor + Format/Minify/Copy
  scripts/
    jsonview-copy.sh      clipboard writer (wl-copy, xclip/xsel fallback)
  settings/
    JsonViewPage.qml      plugin settings page
  README.md
```

- Kind: **panel** (`provides.panels.json`), opened with `qs_manager.sh toggle json`.
- Size: 660 x 580 (1920x1080 base units).
- Editing is pure QML/JS: **Format** runs
  `JSON.stringify(JSON.parse(text), null, indent)`, **Minify** runs it with an
  indent of `0`, and the status line reports `[OK: N keys]` or `[ERROR: ...]`.
- **Copy** sends the text to `scripts/jsonview-copy.sh` (wl-copy; xclip/xsel
  fallback). No network access at any point.

## Settings

`settings.json` -> `"jsonview"`: `indent` (spaces used by Format). Seeded from
`defaults.json`; the panel re-reads it live.

## Dependencies

`wl-copy` for Copy (optional, with xclip/xsel fallbacks). Everything else is
in-process.
