#!/usr/bin/env bash
# samurai-bar — battery producer: "<capacity> <status>" or "AC".
set -uo pipefail
for b in /sys/class/power_supply/BAT*; do
  [ -e "$b" ] || continue
  printf '%s %s' "$(cat "$b/capacity" 2>/dev/null)" "$(cat "$b/status" 2>/dev/null)"
  exit 0
done
printf 'AC'
