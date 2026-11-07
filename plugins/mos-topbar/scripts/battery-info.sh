#!/usr/bin/env bash
set -uo pipefail
for d in /sys/class/power_supply/BAT*; do
  [ -d "$d" ] || continue
  state="$(cat "$d/status" 2>/dev/null || echo Unknown)"
  pct="$(cat "$d/capacity" 2>/dev/null || echo -1)"
  power="$(cat "$d/power_now" 2>/dev/null || echo 0)"
  full="$(cat "$d/energy_full" 2>/dev/null || echo 0)"
  design="$(cat "$d/energy_full_design" 2>/dev/null || echo 0)"
  cycles="$(cat "$d/cycle_count" 2>/dev/null || echo -1)"
  health="-"
  [ "$design" -gt 0 ] 2>/dev/null && health="$((full * 100 / design))"
  watts="$(awk -v p="$power" 'BEGIN { printf "%.1f", p / 1000000 }')"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$state" "$pct" "$watts" "$health" "$cycles" "$full"
  exit 0
done
printf 'AC\t100\t0\t-\t-\t-\n'
