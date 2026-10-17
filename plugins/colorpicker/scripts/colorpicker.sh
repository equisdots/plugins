#!/usr/bin/env bash
# colorpicker — colour producer + history store for the Color Picker panel.
#
# Commands:
#   list   print the saved history, one "#rrggbb" per line (newest first)
#   pick   run `hyprpicker -a` (auto-copy), prepend the picked colour,
#          trim to the last 12, store it atomically and print the colour
#
# The history lives in the plugin's own settings file
# (~/.config/hypr/plugins/colorpicker/settings.json), scope "colorpicker",
# key "history". Writes go through jq + a mktemp/mv swap so readers never see a
# half-written file.
set -uo pipefail

scope="colorpicker"
key="history"
dir="${HOME}/.config/hypr/plugins/colorpicker"
file="${dir}/settings.json"
max=12

command -v jq >/dev/null 2>&1 || { printf '#000000\n'; exit 0; }

mkdir -p "$dir"
if [ ! -s "$file" ]; then
  printf '{"%s":{"%s":[]}}\n' "$scope" "$key" > "$file"
fi

read_history() {
  jq -c --arg s "$scope" --arg k "$key" '(.[$s][$k] // [])' "$file" 2>/dev/null || printf '[]'
}

# Write a JSON array (from stdin) into .<scope>.<key> atomically.
write_history() {
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
    read_history | jq -r '.[]' 2>/dev/null
    ;;
  pick)
    command -v hyprpicker >/dev/null 2>&1 || exit 1
    hex="$(hyprpicker -a 2>/dev/null | tr -d '[:space:]' | tr 'A-F' 'a-f')"
    [ -n "$hex" ] || exit 1
    case "$hex" in
      \#*) ;;
      *) hex="#${hex}" ;;
    esac
    cur="$(read_history)"
    new="$(jq -cn --argjson a "$cur" --arg h "$hex" --argjson m "$max" \
            '$h as $x | ([$x] + ($a | map(select(. != $x))))[0:$m]')" || exit 1
    printf '%s' "$new" | write_history
    printf '%s\n' "$hex"
    ;;
esac
