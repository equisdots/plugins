#!/usr/bin/env bash
# cheatsheet — every active keybind: "<keys>|<label>|<dispatcher>".
set -uo pipefail
command -v hyprctl >/dev/null 2>&1 || exit 0
hyprctl binds -j 2>/dev/null | jq -r '.[] | [ (.modmask|tostring), .key, (.description // ""), (.dispatcher // "") ] | @tsv' 2>/dev/null \
| while IFS=$'\t' read -r mm key desc disp; do
    mods=""
    (( mm & 64 )) && mods="${mods}SUPER + "
    (( mm & 1 )) && mods="${mods}SHIFT + "
    (( mm & 4 )) && mods="${mods}CTRL + "
    (( mm & 8 )) && mods="${mods}ALT + "
    [ -n "$key" ] || continue
    printf '%s%s|%s|%s\n' "$mods" "$key" "${desc:-$disp}" "$disp"
  done | sort -u
