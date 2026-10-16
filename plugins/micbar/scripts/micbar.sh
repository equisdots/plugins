#!/usr/bin/env bash
# micbar — value producer for the Microphone bar module.
set -uo pipefail
if command -v wpctl >/dev/null 2>&1; then
  s="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)"
  case "$s" in *MUTED*) printf 'muted';; *) printf 'on';; esac; exit 0
fi
if command -v pactl >/dev/null 2>&1; then
  pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print ($2=="yes")?"muted":"on"}'; exit 0
fi
printf 'n/a'
