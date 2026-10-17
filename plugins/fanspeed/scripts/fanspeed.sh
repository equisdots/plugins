#!/usr/bin/env bash
# fanspeed — value producer for the Fan bar module.
set -uo pipefail
command -v sensors >/dev/null 2>&1 || { printf 'n/a'; exit 0; }
r="$(sensors 2>/dev/null | awk '/fan/{for(i=1;i<=NF;i++) if($i ~ /RPM/){print $i; exit}}')"
[ -n "$r" ] && printf '%s' "$r" || printf 'n/a'
