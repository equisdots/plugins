#!/usr/bin/env bash
# processmanager.sh — value producer for the Process Manager panel.
#
# Prints the top ~40 processes by CPU, one per line, with a ps header:
#   PID %CPU %MEM COMMAND
# Falls back to a manual sort when ps lacks --sort (busybox).

set -uo pipefail

command -v ps >/dev/null 2>&1 || exit 0

rows="$(ps -eo pid,pcpu,pmem,comm --sort=-pcpu 2>/dev/null | head -n 41)"

if [ -z "$rows" ]; then
    hdr="$(ps -eo pid,pcpu,pmem,comm 2>/dev/null | head -n 1)"
    body="$(ps -eo pid,pcpu,pmem,comm 2>/dev/null | tail -n +2 | sort -k2 -nr | head -n 40)"
    [ -n "$hdr" ] && printf '%s\n' "$hdr"
    [ -n "$body" ] && printf '%s\n' "$body"
    exit 0
fi

printf '%s\n' "$rows"
