#!/usr/bin/env bash
# cpufreq — value producer for the CPU Frequency bar module.
set -uo pipefail
f="$(awk -F: '/cpu MHz/{s+=$2;n++} END{if(n>0)printf "%d", s/n}' /proc/cpuinfo 2>/dev/null)"
[ -n "$f" ] && printf '%s MHz' "$f" || printf 'n/a'
