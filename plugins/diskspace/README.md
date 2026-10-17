# Disk Space

Root filesystem usage percentage.

- Kind: **bar module** (`provides.bar.modules.diskspace`)
- Value producer: `scripts/diskspace.sh`
- Settings: Plugins → Disk Space (`settings/DiskspacePage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
