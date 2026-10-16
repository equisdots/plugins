#!/usr/bin/env bash
# diskspace — value producer for the Disk Space bar module.
set -uo pipefail
u="$(df -P / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5);print $5}')"
[ -n "$u" ] && printf '%s' "$u" || printf 'n/a'
