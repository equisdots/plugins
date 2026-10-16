# Memory

RAM usage percentage (shared SysData poller).

- Kind: **bar module** (`provides.bar.modules.membar`)
- Value source: core singleton
- Settings: Plugins → Memory (`settings/MembarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
