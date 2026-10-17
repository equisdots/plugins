#!/usr/bin/env bash
# xfetch-themes — list xfetch themes / show or set the active one.
#   list           -> one slug per line (from ~/.config/xfetch/themes/*.jsonc)
#   current        -> the active theme slug (config.jsonc "theme")
#   set <slug>     -> set the active theme in config.jsonc (textual, keeps comments)
set -uo pipefail
D="${XFETCH_DIR:-$HOME/.config/xfetch}"
C="$D/config.jsonc"
T="$D/themes"
case "${1:-list}" in
  list)
    ls "$T"/*.jsonc 2>/dev/null | xargs -r -n1 basename 2>/dev/null | sed 's/\.jsonc$//' | sort
    ;;
  current)
    [ -f "$C" ] || { printf 'default'; exit 0; }
    grep -oE '"theme"[[:space:]]*:[[:space:]]*"[^"]*"' "$C" 2>/dev/null | head -n1 | sed -E 's/.*"([^"]*)"$/\1/'
    ;;
  set)
    s="${2:-}"
    [ -f "$T/$s.jsonc" ] || { printf 'no such theme: %s' "$s"; exit 1; }
    if [ -f "$C" ]; then
      tmp="$(mktemp)"
      if sed -E 's/("theme"[[:space:]]*:[[:space:]]*)"[^"]*"/\1"'"$s"'"/' "$C" > "$tmp" 2>/dev/null; then
        if grep -q '"theme"' "$tmp"; then mv "$tmp" "$C"; else
          # no existing "theme" key: inject one after the first brace
          rm -f "$tmp"; tmp="$(mktemp)"
          sed -E '0,/\{/s//{\n    "theme": "'"$s"'",/' "$C" > "$tmp" && mv "$tmp" "$C"
        fi
      fi
    else
      printf '{\n    "theme": "%s"\n}\n' "$s" > "$C"
    fi
    printf 'active theme -> %s' "$s"
    ;;
  *) printf 'usage: list|current|set <slug>' ;;
esac
