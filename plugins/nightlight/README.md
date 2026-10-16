# Night Light

Hyprsunset temperature or off.

- Kind: **bar module** (`provides.bar.modules.nightlight`)
- Value producer: `scripts/nightlight.sh`
- Settings: Plugins → Night Light (`settings/NightlightPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
