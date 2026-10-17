#!/usr/bin/env bash
# gitsummary.sh — value producer for the Git panel plugin.
#
# Lists git repositories under $HOME (bounded) and prints one line per repo:
#   <path>|<branch>|<dirty>
# where `dirty` is the number of changed/untracked entries (0 = clean).
#
# Boundaries: find is capped at MAX repos and MAXDEPTH levels; missing tools or
# roots degrade to an empty list rather than an error.

set -uo pipefail

MAX="${GITSUMMARY_MAX:-60}"
MAXDEPTH="${GITSUMMARY_DEPTH:-4}"

git_bin="$(command -v git 2>/dev/null || true)"
[ -n "$git_bin" ] || exit 0

home="${HOME:-$PWD}"

# Preferred roots (the spec's ${HOME}/Documents + ${HOME}/.config, plus a few
# common project homes). Fall back to $HOME itself when none exist.
roots=()
for d in "$home/Documents" "$home/.config" "$home/Projects" "$home/repos" "$home/dev" "$home/src"; do
    [ -d "$d" ] && roots+=("$d")
done
[ "${#roots[@]}" -gt 0 ] || roots=("$home")

# find over the roots, capped. `command find` guards against a broken alias.
git_dirs="$(
    command find "${roots[@]}" -maxdepth "$MAXDEPTH" -type d -name .git 2>/dev/null \
        | head -n "$MAX"
)"

[ -n "$git_dirs" ] || exit 0

while IFS= read -r gitdir; do
    [ -n "$gitdir" ] || continue
    repo="${gitdir%/.git}"
    branch="$("$git_bin" -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    [ -n "$branch" ] || branch="?"
    dirty="$("$git_bin" -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    [ -n "$dirty" ] || dirty=0
    printf '%s|%s|%s\n' "$repo" "$branch" "$dirty"
done <<< "$git_dirs"
