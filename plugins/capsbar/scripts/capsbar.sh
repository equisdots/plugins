#!/usr/bin/env bash
# capsbar — value producer for the Caps Lock bar module.
set -uo pipefail
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl devices -j 2>/dev/null | grep -qi '"capsLock": true' && printf 'CAPS' || printf ''
else printf ''
fi
