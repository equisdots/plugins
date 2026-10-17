# Load Average

1-minute load average.

- Kind: **bar module** (`provides.bar.modules.loadavg`)
- Value producer: `scripts/loadavg.sh`
- Settings: Plugins → Load Average (`settings/LoadavgPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
