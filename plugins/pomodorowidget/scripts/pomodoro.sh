#!/usr/bin/env bash
# pomodorowidget — value producer for the Pomodoro widget face.
# Prints "<remaining-seconds> <state>"; state is "focus" while a session is
# running (epoch end in the state file is in the future) and "idle" otherwise.
set -uo pipefail
f="${XDG_RUNTIME_DIR:-/tmp}/equisdots-pomodoro"
if [ ! -f "$f" ]; then
    printf '0 idle\n'
    exit 0
fi
end="$(cat "$f" 2>/dev/null)"
now="$(date +%s)"
left=$(( end - now ))
if [ "$left" -le 0 ]; then
    printf '0 idle\n'
else
    printf '%s focus\n' "$left"
fi
