#!/usr/bin/env bash
# mos-topbar — Control Center values: volume and display brightness (0-100).
set -uo pipefail
vol="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{ printf "%d", $2 * 100 }')"
[ -n "$vol" ] || vol=0
bright="$(brightnessctl -m 2>/dev/null | awk -F, 'NR==1 { gsub("%", "", $4); printf "%d", $4 }')"
[ -n "$bright" ] || bright=0
printf '{"volume":%d,"brightness":%d}\n' "$vol" "$bright"
