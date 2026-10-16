#!/usr/bin/env bash
# procsbar — value producer for the Processes bar module.
set -uo pipefail
n="$(ps -e --no-headers 2>/dev/null | wc -l | tr -d ' ')"
printf '%s' "$n"
