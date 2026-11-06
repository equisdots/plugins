#!/usr/bin/env bash
# samurai-bar — top processes by CPU. One TSV line per process:
#   <name>\t<cpu%>\t<mem%>
set -uo pipefail
ps -eo comm=,%cpu=,%mem= --sort=-%cpu --no-headers 2>/dev/null | head -5 | awk '
  NF >= 3 {
    mem = $NF
    cpu = $(NF - 1)
    name = ""
    for (i = 1; i < NF - 1; i++) name = name (i > 1 ? " " : "") $i
    if (name == "ps" || name == "awk") next
    print name "\t" cpu "\t" mem
  }
'
