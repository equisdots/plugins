# Brightness

Screen brightness percentage.

- Kind: **bar module** (`provides.bar.modules.brightnessbar`)
- Value producer: `scripts/brightnessbar.sh`
- Settings: Plugins → Brightness (`settings/BrightnessbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
