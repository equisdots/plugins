# VPN

Active VPN/WireGuard interface.

- Kind: **bar module** (`provides.bar.modules.vpnbar`)
- Value producer: `scripts/vpnbar.sh`
- Settings: Plugins → VPN (`settings/VpnbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
