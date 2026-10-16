#!/usr/bin/env bash
# gitbar — value producer for the Git Bar bar module.
set -uo pipefail
d="${GIT_DIR:-}"
if [ -z "$d" ]; then
  for p in "$PWD" "$HOME"; do
    if git -C "$p" rev-parse --is-inside-work-tree >/dev/null 2>&1; then d="$p"; break; fi
  done
fi
if [ -z "$d" ] || ! git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'no-repo'; exit 0
fi
b="$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null)"
n="$(git -C "$d" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
if [ "$n" = "0" ]; then printf '%s' "$b"; else printf '%s ●%s' "$b" "$n"; fi
