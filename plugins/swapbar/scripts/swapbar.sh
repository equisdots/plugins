#!/usr/bin/env bash
# swapbar — value producer for the Swap bar module.
set -uo pipefail
free 2>/dev/null | awk '/Swap:/{if($2>0) printf "%d", ($3/$2)*100; else printf "0"}'
