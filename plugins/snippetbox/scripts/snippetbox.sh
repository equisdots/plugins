#!/usr/bin/env bash
# snippetbox — snippet store producer for the Snippets panel.
#
# Commands:
#   list          print the stored items as a compact JSON array
#   add           read { "label": ..., "text": ... } from stdin, append it and
#                 print the new JSON array
#   remove INDEX  delete the item at INDEX and print the new JSON array
#
# Items live in the plugin's own settings file
# (~/.config/hypr/plugins/snippetbox/settings.json), scope "snippetbox",
# key "items". Writes go through jq + a mktemp/mv swap so readers never see a
# half-written file.
set -uo pipefail

scope="snippetbox"
key="items"
dir="${HOME}/.config/hypr/plugins/snippetbox"
file="${dir}/settings.json"

command -v jq >/dev/null 2>&1 || { printf '[]\n'; exit 0; }

mkdir -p "$dir"
if [ ! -s "$file" ]; then
  printf '{"%s":{"%s":[]}}\n' "$scope" "$key" > "$file"
fi

read_items() {
  jq -c --arg s "$scope" --arg k "$key" '(.[$s][$k] // [])' "$file" 2>/dev/null || printf '[]'
}

# Write a JSON array (from stdin) into .<scope>.<key> atomically.
write_items() {
  local arr tmp
  arr="$(cat)"
  tmp="$(mktemp "${file}.tmp.XXXXXX")" || exit 1
  if jq --argjson a "$arr" --arg s "$scope" --arg k "$key" '.[$s][$k] = $a' "$file" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    exit 1
  fi
}

case "${1:-list}" in
  list)
    read_items
    printf '\n'
    ;;
  add)
    obj="$(cat)"
    printf '%s' "$obj" | jq -e \
      'type == "object" and (.label | type == "string") and (.text | type == "string")' \
      >/dev/null 2>&1 || exit 1
    cur="$(read_items)"
    new="$(jq -cn --argjson a "$cur" --argjson o "$obj" '$a + [$o]')" || exit 1
    printf '%s' "$new" | write_items
    printf '%s\n' "$new"
    ;;
  remove)
    idx="${2:-}"
    case "$idx" in
      ''|*[!0-9]*) exit 1 ;;
    esac
    cur="$(read_items)"
    new="$(jq -cn --argjson a "$cur" --argjson i "$idx" \
            '$a | to_entries | map(select(.key != $i)) | map(.value)')" || exit 1
    printf '%s' "$new" | write_items
    printf '%s\n' "$new"
    ;;
esac
