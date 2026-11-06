#!/usr/bin/env bash
set -uo pipefail
if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then printf 'on\n'; else printf 'off\n'; fi
