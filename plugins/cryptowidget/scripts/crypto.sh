#!/usr/bin/env bash
# cryptowidget — value producer for the Crypto widget face.
# One CoinGecko call: BTC + ETH price in USD with 24h change (raw JSON out;
# the face parses and formats). Prints nothing on network failure.
set -uo pipefail
curl -fsS --max-time 8 \
  'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd&include_24hr_change=true' \
  2>/dev/null || true
