#!/usr/bin/env bash
# dockerbar — value producer for the Docker bar module.
set -uo pipefail
command -v docker >/dev/null 2>&1 || { printf 'n/a'; exit 0; }
n="$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')"
printf '%s' "$n"
