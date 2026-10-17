#!/usr/bin/env bash
# brightnessbar — value producer for the Brightness bar module.
set -uo pipefail
if command -v brightnessctl >/dev/null 2>&1; then
  printf '%s' "$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,"",$4);print $4}')"; exit 0
fi
printf 'n/a'
