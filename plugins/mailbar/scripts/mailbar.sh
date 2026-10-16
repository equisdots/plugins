#!/usr/bin/env bash
# mailbar — value producer for the Mail bar module.
set -uo pipefail
d="${MAILDIR:-$HOME/Mail}"
if [ -d "$d" ]; then
  n="$(find "$d" -type f -path '*/new/*' 2>/dev/null | wc -l | tr -d ' ')"
  printf '%s' "$n"; exit 0
fi
if command -v notmuch >/dev/null 2>&1; then printf '%s' "$(notmuch count tag:unread 2>/dev/null)"; exit 0; fi
printf '0'
