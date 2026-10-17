#!/usr/bin/env bash
# cryptobar — value producer for the Crypto bar module.
set -uo pipefail
p="$(curl -fsS --max-time 6 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd' 2>/dev/null | awk -F'[:,]' '/usd/{gsub(/[^0-9.]/,"",$3);print $3}')"
[ -n "$p" ] && printf '$%s' "$p" || printf 'n/a'
