# Processes

Running process count.

- Kind: **bar module** (`provides.bar.modules.procsbar`)
- Value producer: `scripts/procsbar.sh`
- Settings: Plugins → Processes (`settings/ProcsbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
