#!/usr/bin/env bash
# bookmarks — read/append the Bookmarks panel's own settings file.
#
# Usage:
#   bookmarks.sh list                 print .bookmarks.links as JSON
#   bookmarks.sh add <label> <url>    append { label, url } to .bookmarks.links
#
# The file is ~/.config/hypr/plugins/bookmarks/settings.json and the links live
# under the "bookmarks" scope, key "links". Writes go through a temp file + mv
# (atomic). If the file does not exist yet it is seeded from the plugin's
# defaults.json (or an empty structure) so jq always has something to read.
set -uo pipefail

f="$HOME/.config/hypr/plugins/bookmarks/settings.json"
dir="$(dirname "$f")"

seed() {
    if [ -f "$f" ]; then return 0; fi
    mkdir -p "$dir"
    local def="$HOME/.config/hypr/plugins/bookmarks/defaults.json"
    if [ -f "$def" ]; then
        cp "$def" "$f"
    else
        printf '{"bookmarks":{"links":[]}}' > "$f"
    fi
}

seed

cmd="${1:-list}"

case "$cmd" in
    list)
        jq -c '.bookmarks.links // []' "$f" 2>/dev/null || printf '[]'
        ;;
    add)
        label="${2:-}"
        url="${3:-}"
        [ -n "$url" ] || exit 1
        tmp="$f.tmp.$$"
        if jq --arg l "$label" --arg u "$url" \
            '.bookmarks = (.bookmarks // {}) | .bookmarks.links = ((.bookmarks.links // []) + [{label: $l, url: $u}])' \
            "$f" > "$tmp" 2>/dev/null; then
            mv "$tmp" "$f"
        else
            rm -f "$tmp"
            exit 1
        fi
        ;;
    *)
        exit 1
        ;;
esac
