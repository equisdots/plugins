#!/usr/bin/env bash
# nightlight — value producer for the Night Light bar module.
set -uo pipefail
if pgrep -x hyprsunset >/dev/null 2>&1; then printf 'on'; else printf 'off'; fi
