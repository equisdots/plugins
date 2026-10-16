#!/usr/bin/env bash
# pomodoropanel — control/read the equisdots pomodoro state file.
#
# Usage:
#   pomodoropanel.sh start <seconds>   write end = now + seconds
#   pomodoropanel.sh pause             clear the state file
#   pomodoropanel.sh reset             clear the state file
#   pomodoropanel.sh status            idle | done | <seconds left>
#
# The state file is $XDG_RUNTIME_DIR/equisdots-pomodoro and holds the epoch
# seconds of the end time; the `pomodoro` bar module reads the same file.
set -uo pipefail

f="${XDG_RUNTIME_DIR:-/tmp}/equisdots-pomodoro"
cmd="${1:-status}"

case "$cmd" in
    start)
        secs="${2:-1500}"
        case "$secs" in ''|*[!0-9]*) secs=1500 ;; esac
        printf '%s' "$(( $(date +%s) + secs ))" > "$f"
        ;;
    pause|reset|stop)
        rm -f "$f"
        ;;
    status)
        [ -f "$f" ] || { printf 'idle'; exit 0; }
        end="$(cat "$f" 2>/dev/null || printf 0)"
        case "$end" in ''|*[!0-9]*) printf 'idle'; exit 0 ;; esac
        now="$(date +%s)"
        left=$(( end - now ))
        if [ "$left" -le 0 ]; then printf 'done'; else printf '%s' "$left"; fi
        ;;
    *)
        exit 1
        ;;
esac
