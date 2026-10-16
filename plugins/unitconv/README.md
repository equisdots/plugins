# Units

Offline unit converter for length, mass, temperature, data and time.

- Kind: **panel** (`provides.panels.units`, label "Units")
- Panel file: `ui/UnitConv.qml` (540x500 base units)
- Helper: `ui/UnitCombo.qml` — the rounded unit dropdown
- Settings page: `settings/UnitConvPage.qml` (Plugins -> Units)

## Files

```
unitconv/
  plugin.json                 manifest (type: shell; provides.panels.units)
  defaults.json               unitconv.category seed
  ui/
    UnitConv.qml              the panel: category chips + converter
    UnitCombo.qml             rounded unit dropdown
  settings/
    UnitConvPage.qml          informational settings page
  README.md
```

## How it is consumed

- The shell panel host loads `ui/UnitConv.qml` through `provides.panels.units`;
  the popup name is **units**, toggled with `qs_manager.sh toggle units`.
- Pick a category (Length, Mass, Temperature, Data, Time), type a number, and
  choose the from/to units. Conversion is pure JavaScript — no network, no
  scripts. Swap moves the result into the input.

## Units

- Length: m, km, cm, in, ft, mi
- Mass: g, kg, lb, oz
- Temperature: C, F, K
- Data: B, KB, MB, GB, TB (1024-based)
- Time: s, min, h, day

## Settings

`~/.config/hypr/plugins/unitconv/settings.json`, scope `unitconv`:

- `category` (default `"Length"`) — the category selected on open. Seeded from
  `defaults.json`.
