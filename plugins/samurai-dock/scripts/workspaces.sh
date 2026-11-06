#!/usr/bin/env bash
# samurai-bar — workspaces producer.
# Prints ONE line of JSON: {"ws":[1,2,3],"active":2,"occupied":[1,2]}.
set -uo pipefail
if ! command -v hyprctl >/dev/null 2>&1; then printf '{"ws":[],"active":-1,"occupied":[]}'; exit 0; fi
monitor="${1:-}"
if [ -n "$monitor" ]; then
  active="$(hyprctl monitors -j 2>/dev/null | jq -r --arg m "$monitor" '
    .[] | select(.name == $m) | .activeWorkspace.id // -1
  ' 2>/dev/null | head -n1)"
else
  active="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // -1' 2>/dev/null)"
fi
hyprctl workspaces -j 2>/dev/null | jq -c --argjson active "${active:--1}" '
  { ws: (map(.id) | sort),
    active: $active,
    occupied: (map(.id) | sort) }
' 2>/dev/null || printf '{"ws":[],"active":-1,"occupied":[]}'
