#!/usr/bin/env bash
# torrentbar — value producer for the Torrents bar module.
set -uo pipefail
if command -v transmission-remote >/dev/null 2>&1; then
  n="$(transmission-remote -l 2>/dev/null | awk 'NR>1 && $1 ~ /^[0-9]+/ {c++} END{print c+0}')"
  printf '%s' "$n"; exit 0
fi
printf 'n/a'
