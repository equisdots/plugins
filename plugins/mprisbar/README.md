# Media

Now-playing artist - title (playerctl).

- Kind: **bar module** (`provides.bar.modules.mprisbar`)
- Value producer: `scripts/mprisbar.sh`
- Settings: Plugins → Media (`settings/MprisbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
