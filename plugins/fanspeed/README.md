# Fan

Fan speed from lm_sensors.

- Kind: **bar module** (`provides.bar.modules.fanspeed`)
- Value producer: `scripts/fanspeed.sh`
- Settings: Plugins → Fan (`settings/FanspeedPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
