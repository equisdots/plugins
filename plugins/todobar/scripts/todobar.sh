#!/usr/bin/env bash
# todobar — value producer for the Todo bar module.
set -uo pipefail
f="$HOME/.local/share/equisdots/todo.txt"
[ -f "$f" ] || { printf '0'; exit 0; }
n="$(grep -cvE '^\s*(#|$|x )' "$f" 2>/dev/null)"
printf '%s' "$n"
