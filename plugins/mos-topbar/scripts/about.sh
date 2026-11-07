#!/usr/bin/env bash
set -uo pipefail
host="$(uname -n)"
os="$(. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-Linux}")"
kernel="$(uname -r)"
cpu="$(lscpu 2>/dev/null | awk -F: '/Model name/ { gsub(/^ +| +$/, "", $2); print $2; exit }')"
mem="$(free -h 2>/dev/null | awk '/^Mem:/ { print $2; exit }')"
gpu="$(lspci 2>/dev/null | awk -F': ' '/VGA compatible|3D controller/ { print $2; exit }')"
printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$host" "$os" "$kernel" "${cpu:-Unknown CPU}" "${mem:-?}" "${gpu:-Unknown GPU}"
