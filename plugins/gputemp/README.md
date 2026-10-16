# GPU

GPU utilisation/temperature (nvidia-smi or sensors).

- Kind: **bar module** (`provides.bar.modules.gputemp`)
- Value producer: `scripts/gputemp.sh`
- Settings: Plugins → GPU (`settings/GputempPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
