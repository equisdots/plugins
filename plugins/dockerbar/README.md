# Docker

Running Docker containers count.

- Kind: **bar module** (`provides.bar.modules.dockerbar`)
- Value producer: `scripts/dockerbar.sh`
- Settings: Plugins → Docker (`settings/DockerbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
