#!/usr/bin/env bash
# jsonview-copy.sh — copy the JSON editor text to the Wayland clipboard.
#
# Usage: jsonview-copy.sh <text>
# Prefers wl-copy, then xclip / xsel. Exits non-zero when nothing is available.

set -uo pipefail

text="${1:-}"

if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$text" | wl-copy
    exit $?
fi

if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$text" | xclip -selection clipboard
    exit $?
fi

if command -v xsel >/dev/null 2>&1; then
    printf '%s' "$text" | xsel --clipboard --input
    exit $?
fi

printf 'jsonview: no clipboard tool (wl-copy/xclip/xsel)\n' >&2
exit 1
