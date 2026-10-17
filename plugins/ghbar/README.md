# GitHub

Unread GitHub notifications (gh CLI).

- Kind: **bar module** (`provides.bar.modules.ghbar`)
- Value producer: `scripts/ghbar.sh`
- Settings: Plugins → GitHub (`settings/GhbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
