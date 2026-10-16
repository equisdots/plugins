#!/usr/bin/env bash
# kill.sh — terminate a process by PID (Process Manager panel kill button).
#
# Usage: kill.sh <pid>
# Sends SIGTERM first, then SIGKILL if the process survives a short grace.

set -uo pipefail

pid="${1:-}"

case "$pid" in
    '' | *[!0-9]*)
        printf 'kill: invalid pid %s\n' "$pid" >&2
        exit 2
        ;;
esac

# Never signal init or a non-root-owned critical task by accident.
if [ "$pid" -le 1 ]; then
    printf 'kill: refusing to signal pid %s\n' "$pid" >&2
    exit 3
fi

if kill "$pid" 2>/dev/null; then
    exit 0
fi

# Race the reaper: force it after a brief pause.
sleep 1
kill -9 "$pid" 2>/dev/null
