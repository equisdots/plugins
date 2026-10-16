#!/usr/bin/env bash
# kbdlayout — value producer for the Keyboard Layout bar module.
set -uo pipefail
if command -v hyprctl >/dev/null 2>&1; then
  l="$(hyprctl devices -j 2>/dev/null | awk '/"layout":/{gsub(/[",]/,"");print $2; exit}')"
  [ -n "$l" ] && { printf '%s' "$l"; exit 0; }
fi
printf 'us'
