# Do Not Disturb

Notification do-not-disturb state.

- Kind: **bar module** (`provides.bar.modules.dndbar`)
- Value producer: `scripts/dndbar.sh`
- Settings: Plugins → Do Not Disturb (`settings/DndbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
