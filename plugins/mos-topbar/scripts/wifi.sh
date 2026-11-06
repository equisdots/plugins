#!/usr/bin/env bash
set -uo pipefail
if nmcli radio wifi 2>/dev/null | grep -q enabled; then printf 'on\n'; else printf 'off\n'; fi
