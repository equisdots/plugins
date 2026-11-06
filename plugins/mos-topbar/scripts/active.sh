#!/usr/bin/env bash
# mos-topbar — active app name for the app menu.
set -uo pipefail
if ! command -v hyprctl >/dev/null 2>&1; then printf 'Finder\n'; exit 0; fi
hyprctl activewindow -j 2>/dev/null | jq -r '
  if .class == null or .class == "" then "Finder"
  else (.class | split(".") | last | ascii_upcase | .[0:1] + (.[1:] | ascii_downcase))
  end
' 2>/dev/null || printf 'Finder\n'
