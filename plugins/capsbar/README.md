# Caps Lock

Caps Lock indicator.

- Kind: **bar module** (`provides.bar.modules.capsbar`)
- Value producer: `scripts/capsbar.sh`
- Settings: Plugins → Caps Lock (`settings/CapsbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
