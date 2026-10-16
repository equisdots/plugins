#!/usr/bin/env bash
# gitbar — value producer for the Git Bar bar module.
#
# The interesting info is WHICH repo you are editing right now, so the producer
# resolves the repo of the FOCUSED window (Hyprland active window pid →
# /proc/<pid>/cwd → git toplevel), not the shell's own cwd (which never
# changes). Falls back to $PWD then $HOME. Prints nothing when there is no
# repo, and the bar module hides itself.
#
# Usage:
#   gitbar.sh            one-line value for the bar module
#   gitbar.sh --detail   JSON with repo/branch/dirty/ahead/behind/files/last
set -uo pipefail

repo_from_cwd() { git -C "$1" rev-parse --show-toplevel 2>/dev/null; }

resolve_repo() {
    local top="" pid cwd
    if command -v hyprctl >/dev/null 2>&1; then
        pid="$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null)"
        if [ -n "${pid:-}" ] && [ "$pid" != "0" ]; then
            cwd="$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)"
            [ -n "$cwd" ] && top="$(repo_from_cwd "$cwd")"
        fi
    fi
    if [ -z "$top" ]; then
        local p
        for p in "$PWD" "$HOME"; do
            top="$(repo_from_cwd "$p")"; [ -n "$top" ] && break
        done
    fi
    printf '%s' "$top"
}

top="$(resolve_repo)"
STATE="${XDG_RUNTIME_DIR:-/tmp}/gitbar-last-repo"

# ── detail mode (popup) ──────────────────────────────────────────────────────
if [ "${1:-}" = "--detail" ]; then
    # The popup itself takes focus, so `activewindow` no longer points at your
    # editor: fall back to the last repo the island saw.
    [ -z "$top" ] && [ -f "$STATE" ] && top="$(cat "$STATE" 2>/dev/null)"
    if [ -z "$top" ]; then
        printf '{"repo":""}'
        exit 0
    fi
    branch="$(git -C "$top" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    [ "$branch" = "HEAD" ] && branch="$(git -C "$top" rev-parse --short HEAD 2>/dev/null)"
    dirty="$(git -C "$top" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    ahead=0; behind=0
    if git -C "$top" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
        counts="$(git -C "$top" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)"
        behind="${counts%%[[:space:]]*}"; ahead="${counts##*[[:space:]]}"
        [ -n "$behind" ] || behind=0; [ -n "$ahead" ] || ahead=0
    fi
    files="$(git -C "$top" status --porcelain 2>/dev/null | head -n 8)"
    last="$(git -C "$top" log -1 --pretty='%h %s' 2>/dev/null)"
    jq -n --arg repo "$top" --arg branch "$branch" --argjson dirty "${dirty:-0}" \
          --argjson ahead "${ahead:-0}" --argjson behind "${behind:-0}" \
          --arg files "$files" --arg last "$last" \
          '{repo:$repo, branch:$branch, dirty:$dirty, ahead:$ahead, behind:$behind,
            files:($files|split("\n")|map(select(length>0))), last:$last}'
    exit 0
fi

# ── bar value ────────────────────────────────────────────────────────────────
[ -z "$top" ] && exit 0
printf '%s' "$top" > "$STATE" 2>/dev/null

b="$(git -C "$top" rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ "$b" = "HEAD" ] && b="$(git -C "$top" rev-parse --short HEAD 2>/dev/null)"
n="$(git -C "$top" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
ab=""
if git -C "$top" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
    counts="$(git -C "$top" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)"
    behind="${counts%%[[:space:]]*}"; ahead="${counts##*[[:space:]]}"
    [ "${ahead:-0}" != "0" ]  && ab="${ab} ↑${ahead}"
    [ "${behind:-0}" != "0" ] && ab="${ab} ↓${behind}"
fi

out="$b"
[ "$n" != "0" ] && out="$out ●$n"
out="$out$ab"
printf '%s' "$out"
