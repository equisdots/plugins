# World Clock

Time in a second timezone (UTC by default).

- Kind: **bar module** (`provides.bar.modules.worldclock`)
- Value producer: `scripts/worldclock.sh`
- Settings: Plugins → World Clock (`settings/WorldclockPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
