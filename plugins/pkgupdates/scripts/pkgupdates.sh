#!/usr/bin/env bash
# pkgupdates — value producer for the Updates bar module.
set -uo pipefail
if command -v checkupdates >/dev/null 2>&1; then
  n="$(checkupdates 2>/dev/null | wc -l | tr -d ' ')"; printf '%s' "$n"; exit 0
fi
printf '?'
