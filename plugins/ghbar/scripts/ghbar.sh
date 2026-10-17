#!/usr/bin/env bash
# ghbar — value producer for the GitHub bar module.
set -uo pipefail
command -v gh >/dev/null 2>&1 || { printf 'n/a'; exit 0; }
n="$(gh api notifications --paginate -q 'length' 2>/dev/null | awk '{s+=$1} END{print s+0}')"
printf '%s' "$n"
