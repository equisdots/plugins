#!/usr/bin/env bash
# batteryplus — value producer for the Battery Plus bar module.
set -uo pipefail
for b in /sys/class/power_supply/BAT*; do
  [ -e "$b" ] || continue
  c="$(cat "$b/capacity" 2>/dev/null)"; s="$(cat "$b/status" 2>/dev/null)"
  printf '%s%% %s' "$c" "$s"; exit 0
done
printf 'AC'
