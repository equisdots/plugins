#!/usr/bin/env bash
# worldclock — value producer for the World Clock bar module.
set -uo pipefail
TZ="${WORLDCLOCK_TZ:-UTC}" date '+%H:%M'
