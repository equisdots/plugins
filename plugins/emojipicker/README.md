# Glyphs

Searchable Unicode glyph picker with clipboard copy.

- Kind: **panel** (`provides.panels.emoji`, label "Glyphs")
- Panel file: `ui/GlyphsPicker.qml` (680x540 base units)
- Data: `ui/Glyphs.js` — a pure QML/JS array of `{ g, tags }` (~120 common
  symbols and emoji). No network, no scripts.
- Settings page: `settings/GlyphsPage.qml` (Plugins -> Glyphs)

## Files

```
emojipicker/
  plugin.json                 manifest (type: shell; provides.panels.emoji)
  defaults.json               emojipicker.columns seed
  ui/
    GlyphsPicker.qml          the panel: search field + glyph grid
    Glyphs.js                 the glyph catalogue ({ g, tags })
  settings/
    GlyphsPage.qml            informational settings page
  README.md
```

## How it is consumed

- The shell panel host loads `ui/GlyphsPicker.qml` through
  `provides.panels.emoji`; the popup name is **emoji**, so it is toggled with
  `qs_manager.sh toggle emoji`.
- A TextField filters the catalogue by the `tags` keyword attached to each
  glyph (or an exact glyph match). Matching glyphs render in a `GridView`.
- Clicking a cell pipes the glyph into `wl-copy` (via a `Process` stdin, so no
  shell quoting is needed) and flashes a "copied" status.

## Settings

`~/.config/hypr/plugins/emojipicker/settings.json`, scope `emojipicker`:

- `columns` (6-14, default 10) — grid columns, seeded from `defaults.json`.
