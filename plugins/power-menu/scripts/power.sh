#!/usr/bin/env bash
# power-menu — session actions. Usage: power.sh <lock|logout|suspend|reboot|shutdown>
set -uo pipefail
case "${1:-}" in
  lock)
    if command -v hyprlock >/dev/null 2>&1; then hyprlock
    else loginctl lock-session 2>/dev/null || true; fi ;;
  logout)
    if command -v hyprctl >/dev/null 2>&1; then hyprctl dispatch exit 2>/dev/null || true
    else loginctl terminate-session "${XDG_SESSION_ID:-}" 2>/dev/null || true; fi ;;
  suspend) systemctl suspend ;;
  reboot) systemctl reboot ;;
  shutdown) systemctl poweroff ;;
  *) printf 'usage: lock|logout|suspend|reboot|shutdown' ;;
esac
