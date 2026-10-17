#!/usr/bin/env bash
# gitbar — value producer for the Git Bar bar module.
#
# Two modes, in this order:
#   1. PINNED repo   — settings.json `gitbar.repo` (a path). If set and it is a
#                      git repo, that repo is always shown. This is the mode
#                      that is useful for ANY user (their main repo).
#   2. AUTO          — best-effort "what am I working on": the repo of the
#                      FOCUSED window. A terminal focuses the emulator (whose
#                      own cwd is its launch dir), so we descend the process
#                      tree (up to a few levels) to the shell child and use ITS
#                      cwd. GUI editors report their launch dir, so AUTO is
#                      inherently heuristic.
# With nothing resolved the producer prints nothing and the module hides.
#
# Usage:
#   gitbar.sh            one-line value for the bar module
#   gitbar.sh --detail   JSON with repo/branch/dirty/ahead/behind/files/last
set -uo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/plugins/gitbar/settings.json"
STATE="${XDG_RUNTIME_DIR:-/tmp}/gitbar-last-repo"

repo_from_cwd() { [ -n "${1:-}" ] && git -C "$1" rev-parse --show-toplevel 2>/dev/null; }

resolve_repo() {
    local t
    # 1) pinned repo (settings)
    if [ -f "$CFG" ] && command -v jq >/dev/null 2>&1; then
        local r; r="$(jq -r '.gitbar.repo // empty' "$CFG" 2>/dev/null)"
        if [ -n "$r" ]; then
            t="$(repo_from_cwd "$r")"; [ -n "$t" ] && { printf '%s' "$t"; return; }
        fi
    fi
    # 2) auto: focused window cwd, then its SHELL descendants (terminal)
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        local pid; pid="$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null)"
        if [ -n "${pid:-}" ] && [ "$pid" != "0" ]; then
            t="$(repo_from_cwd "$(readlink -f "/proc/$pid/cwd" 2>/dev/null)")"
            [ -n "$t" ] && { printf '%s' "$t"; return; }
            # descend at most 2 levels and only into SHELL processes, so a
            # background job (editor linter, agent, ...) can't hijack the island
            local child g comm
            for child in $(pgrep -P "$pid" 2>/dev/null); do
                comm="$(cat "/proc/$child/comm" 2>/dev/null)"
                case "$comm" in
                    zsh|bash|fish|nu|nushell|dash|sh|ksh|elvish|xonsh|tcsh|csh|tssh|mksh)
                        t="$(repo_from_cwd "$(readlink -f "/proc/$child/cwd" 2>/dev/null)")"
                        [ -n "$t" ] && { printf '%s' "$t"; return; } ;;
                esac
                for g in $(pgrep -P "$child" 2>/dev/null); do
                    comm="$(cat "/proc/$g/comm" 2>/dev/null)"
                    case "$comm" in
                        zsh|bash|fish|nu|nushell|dash|sh|ksh|elvish|xonsh|tcsh|csh|mksh)
                            t="$(repo_from_cwd "$(readlink -f "/proc/$g/cwd" 2>/dev/null)")"
                            [ -n "$t" ] && { printf '%s' "$t"; return; } ;;
                    esac
                done
            done
        fi
    fi
    printf ''
}

top="$(resolve_repo)"

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
