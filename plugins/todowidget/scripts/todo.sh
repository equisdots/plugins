#!/usr/bin/env bash
# todowidget — value producer for the Todo widget face.
# Prints the open items in the todo file (one per line): every non-empty line
# that does not start with "x " (done) or "#" (comment).
set -uo pipefail
f="$HOME/.local/share/equisdots/todo.txt"
[ -f "$f" ] || exit 0
grep -vE '^\s*(#|$|x )' "$f" 2>/dev/null
