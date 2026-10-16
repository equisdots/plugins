# Keyboard Layout

Active keyboard layout.

- Kind: **bar module** (`provides.bar.modules.kbdlayout`)
- Value producer: `scripts/kbdlayout.sh`
- Settings: Plugins → Keyboard Layout (`settings/KbdlayoutPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
