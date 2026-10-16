# Crypto (Widget)

Desktop widget: BTC and ETH price in USD with the 24 h change, as two rows.

- Kind: **widget face** (`provides.widgets.faces.crypto`, variant `card`)
- Face: `widgets/CryptoCard.qml`
- Value producer: `scripts/crypto.sh` (one CoinGecko call, raw JSON out)
- Default size: 320 x 220, refresh every 60 s

Self-contained: the script is the source of truth (a single request to
`api.coingecko.com` for `bitcoin,ethereum` in USD with `include_24hr_change`);
the face parses the JSON, formats the prices and colours the change green/red.
The face follows the active palette through `Theme` tokens.
