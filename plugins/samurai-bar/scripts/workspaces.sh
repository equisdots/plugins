#!/usr/bin/env bash
# samurai-bar — workspaces producer.
# Prints ONE line of JSON: {"ws":[1,2,3],"active":2,"occupied":[1,2]}.
set -uo pipefail
if ! command -v hyprctl >/dev/null 2>&1; then printf '{"ws":[],"active":-1,"occupied":[]}'; exit 0; fi
hyprctl workspaces -j 2>/dev/null | jq -c '
  { ws: (map(.id) | sort),
    active: ([.[] | select(.id > 0)] | (max_by(.lastwindow) // {}) | .id // -1),
    occupied: (map(.id) | sort) }
' 2>/dev/null || printf '{"ws":[],"active":-1,"occupied":[]}'
