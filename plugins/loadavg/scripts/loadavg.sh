#!/usr/bin/env bash
# loadavg — value producer for the Load Average bar module.
set -uo pipefail
awk '{printf "%s", $1}' /proc/loadavg 2>/dev/null || printf 'n/a'
