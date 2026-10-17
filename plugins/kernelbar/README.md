# Kernel

Running kernel release.

- Kind: **bar module** (`provides.bar.modules.kernelbar`)
- Value producer: `scripts/kernelbar.sh`
- Settings: Plugins → Kernel (`settings/KernelbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
