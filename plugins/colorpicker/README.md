# Color Picker

Colour picker (hyprpicker) with the last 12 picks as copyable swatches.

- Kind: **panel** (`provides.panels.colors`, label "Color Picker")
- Panel file: `ui/ColorPicker.qml` (560x480 base units)
- Value producer: `scripts/colorpicker.sh` (`list`, `pick`)
- Settings page: `settings/ColorPickerPage.qml` (Plugins -> Color Picker)

## Files

```
colorpicker/
  plugin.json                 manifest (type: shell; provides.panels.colors)
  defaults.json               colorpicker.history seed (3 colours)
  scripts/
    colorpicker.sh            history store + hyprpicker runner
  ui/
    ColorPicker.qml           the panel: swatch, Pick, history grid
  settings/
    ColorPickerPage.qml       history count + storage info
  README.md
```

## How it is consumed

- The shell panel host loads `ui/ColorPicker.qml` through
  `provides.panels.colors`; the popup name is **colors**, toggled with
  `qs_manager.sh toggle colors`.
- **Pick** runs `scripts/colorpicker.sh pick`, which calls `hyprpicker -a`
  (auto-copy), prepends the resulting `#rrggbb` to the history, trims it to 12
  and prints the colour. The script writes the settings file atomically
  (`jq` into a `mktemp` file, then `mv`).
- At startup the panel runs `scripts/colorpicker.sh list` to load the history;
  clicking a history swatch copies the hex with `wl-copy`.

## Settings

`~/.config/hypr/plugins/colorpicker/settings.json`, scope `colorpicker`:

- `history` — array of `#rrggbb`, newest first, capped at 12. Seeded from
  `defaults.json`; updated by the panel.

## Dependencies

`hyprpicker`, `jq`, `wl-copy` (wl-clipboard).
