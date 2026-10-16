# Uptime

System uptime (human).

- Kind: **bar module** (`provides.bar.modules.uptimebar`)
- Value producer: `scripts/uptimebar.sh`
- Settings: Plugins → Uptime (`settings/UptimebarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
