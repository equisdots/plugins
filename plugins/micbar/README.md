# Microphone

Microphone mute state.

- Kind: **bar module** (`provides.bar.modules.micbar`)
- Value producer: `scripts/micbar.sh`
- Settings: Plugins → Microphone (`settings/MicbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
