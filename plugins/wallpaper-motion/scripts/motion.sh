#!/usr/bin/env bash
# wallpaper-motion — reads/changes the frame rate of the RUNNING xwww scene
# (the animated wallpaper) without touching davincix.
#
# davincix launches scenes as:
#   xwww scene run <dir>/scene.js --palette equisdots --fps 15 ...
# This script exchanges the `--fps` value in the live process argv and
# relaunches the exact same command, so palette/transition/outputs are kept.
#
# Usage:
#   motion.sh get              current fps of the running scene (empty if none)
#   motion.sh status           "<pid> <fps>" of the running scene (empty if none)
#   motion.sh set <fps>        relaunch the scene at <fps>
#   motion.sh apply-if-diff <fps>   set only when the running fps differs
set -uo pipefail

STATE="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-motion-fps"

scene_pid() { pgrep -f 'xwww scene run' 2>/dev/null | head -n1; }
scene_fps() { pgrep -af 'xwww scene run' 2>/dev/null | grep -oE -- '--fps [0-9]+' | head -n1 | awk '{print $2}'; }

set_fps() {
    local n="$1" pid
    case "$n" in ''|*[!0-9]*) return 1 ;; esac
    [ "$n" -ge 1 ] && [ "$n" -le 240 ] || return 1

    pid="$(scene_pid)"
    if [ -z "$pid" ]; then
        printf '%s' "$n" > "$STATE" 2>/dev/null
        return 0
    fi

    local -a args=() out=()
    mapfile -d '' -t args < "/proc/$pid/cmdline" 2>/dev/null || return 1
    local i=0 replaced=0
    while [ "$i" -lt "${#args[@]}" ]; do
        [ -z "${args[$i]}" ] && { i=$((i + 1)); continue; }
        if [ "${args[$i]}" = "--fps" ]; then
            out+=("--fps" "$n"); i=$((i + 2)); replaced=1; continue
        fi
        out+=("${args[$i]}"); i=$((i + 1))
    done
    [ "$replaced" -eq 0 ] && out+=(--fps "$n")

    # Kill EVERY scene runner (duplicates can exist after several applies), then
    # start exactly one with the new argv.
    pkill -f '[x]www scene run' 2>/dev/null
    sleep 0.25
    setsid nohup "${out[@]}" >/dev/null 2>&1 < /dev/null &
    printf '%s' "$n" > "$STATE" 2>/dev/null
}

case "${1:-get}" in
    get)           scene_fps ;;
    status)        p="$(scene_pid)"; [ -n "$p" ] && printf '%s %s' "$p" "$(scene_fps)" ;;
    apply-if-diff) want="${2:-30}"; cur="$(scene_fps)"; [ "$cur" = "$want" ] || set_fps "$want" ;;
    set)           set_fps "${2:-}" ;;
    *)             exit 1 ;;
esac
