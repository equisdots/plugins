#!/usr/bin/env bash
# samurai-bar — extended system telemetry.
# One JSON line consumed by the Samurai resource panel:
#   disk, diskFree (GiB), load1/5/15, uptime (s), procs, swap (%).
set -uo pipefail

read -r disk_size disk_used disk_avail disk_pct < <(
  df -P -B1 / 2>/dev/null | awk 'NR==2 { gsub("%", "", $5); print $2, $3, $4, $5 }'
)
disk_pct="${disk_pct:-0}"
disk_avail="${disk_avail:-0}"

read -r load1 load5 load15 < <(awk '{ print $1, $2, $3 }' /proc/loadavg)
load1="${load1:-0}"; load5="${load5:-0}"; load15="${load15:-0}"

uptime="$(awk '{ printf "%.0f", $1 }' /proc/uptime 2>/dev/null || printf '0')"
procs="$(ps -e --no-headers 2>/dev/null | wc -l)"
procs="${procs//[^0-9]/}"; procs="${procs:-0}"

swap_total="$(awk '/^SwapTotal:/ { print $2 }' /proc/meminfo 2>/dev/null)"
swap_free="$(awk '/^SwapFree:/ { print $2 }' /proc/meminfo 2>/dev/null)"
swap_total="${swap_total:-0}"; swap_free="${swap_free:-0}"
if [ "$swap_total" -gt 0 ] 2>/dev/null; then
  swap_pct=$(( 100 * (swap_total - swap_free) / swap_total ))
else
  swap_pct=0
fi

disk_free="$(awk -v b="$disk_avail" 'BEGIN { printf "%.1f", b / 1073741824 }')"

printf '{"disk":%d,"diskFree":%s,"load1":%s,"load5":%s,"load15":%s,"uptime":%d,"procs":%d,"swap":%d}\n' \
  "$disk_pct" "$disk_free" "$load1" "$load5" "$load15" "$uptime" "$procs" "$swap_pct"
