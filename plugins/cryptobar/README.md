# Crypto

Bitcoin price in USD (CoinGecko).

- Kind: **bar module** (`provides.bar.modules.cryptobar`)
- Value producer: `scripts/cryptobar.sh`
- Settings: Plugins → Crypto (`settings/CryptobarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
