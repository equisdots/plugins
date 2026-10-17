#!/usr/bin/env bash
# pomodoro — value producer for the Pomodoro bar module.
set -uo pipefail
f="${XDG_RUNTIME_DIR:-/tmp}/equisdots-pomodoro"
[ -f "$f" ] || { printf 'idle'; exit 0; }
end="$(cat "$f" 2>/dev/null)"
now="$(date +%s)"
left=$(( end - now ))
if [ "$left" -le 0 ]; then printf 'done'; else printf '%02d:%02d' $((left/60)) $((left%60)); fi
