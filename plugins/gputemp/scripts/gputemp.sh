#!/usr/bin/env bash
# gputemp — value producer for the GPU bar module.
set -uo pipefail
if command -v nvidia-smi >/dev/null 2>&1; then
  out="$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)"
  [ -n "$out" ] && { IFS=', ' read -r u t _ < <(printf '%s' "$out"); printf '%s%% %s°' "$u" "$t"; exit 0; }
fi
if command -v sensors >/dev/null 2>&1; then
  t="$(sensors 2>/dev/null | awk '/edge|GPU/{for(i=1;i<=NF;i++) if($i ~ /\+?[0-9.]+°C/){gsub(/[+°C]/,"",$i);print $i; exit}}')"
  [ -n "$t" ] && { printf '%s°' "$t"; exit 0; }
fi
printf 'n/a'
