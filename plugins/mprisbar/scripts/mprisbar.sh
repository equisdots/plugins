#!/usr/bin/env bash
# mprisbar — value producer for the Media bar module.
set -uo pipefail
command -v playerctl >/dev/null 2>&1 || { printf 'stopped'; exit 0; }
a="$(playerctl metadata artist 2>/dev/null)"; t="$(playerctl metadata title 2>/dev/null)"
if [ -n "$t" ]; then [ -n "$a" ] && printf '%s - %s' "$a" "$t" || printf '%s' "$t"; else printf 'stopped'; fi
