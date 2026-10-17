#!/usr/bin/env bash
# dndbar — value producer for the Do Not Disturb bar module.
set -uo pipefail
f="${XDG_RUNTIME_DIR:-/tmp}/quickshell/dnd"
[ -f "$f" ] && grep -q '^1$' "$f" 2>/dev/null && printf 'DND' || printf 'on'
