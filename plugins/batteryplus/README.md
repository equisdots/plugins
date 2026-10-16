# Battery Plus

Battery charge and status.

- Kind: **bar module** (`provides.bar.modules.batteryplus`)
- Value producer: `scripts/batteryplus.sh`
- Settings: Plugins → Battery Plus (`settings/BatteryplusPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
