#!/usr/bin/env bash
# uptimebar — value producer for the Uptime bar module.
set -uo pipefail
u="$(uptime -p 2>/dev/null | sed 's/^up //')"
[ -n "$u" ] && printf '%s' "$u" || awk '{d=int($1/86400);h=int(($1%86400)/3600);printf "%dd %dh", d, h}' /proc/uptime
