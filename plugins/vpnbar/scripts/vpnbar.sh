#!/usr/bin/env bash
# vpnbar — value producer for the VPN bar module.
set -uo pipefail
if command -v wg >/dev/null 2>&1; then
  i="$(wg show interfaces 2>/dev/null | awk '{print $1}')"
  [ -n "$i" ] && { printf '%s' "$i"; exit 0; }
fi
i="$(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(tun|wg|tailscale|proton|nordlynx)' | head -n1)"
[ -n "$i" ] && printf '%s' "$i" || printf 'off'
