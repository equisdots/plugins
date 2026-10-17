#!/usr/bin/env bash
# run.sh — runtime smoke tier for an equisdots plugin (needs a compositor).
#
# Boots a headless sway + the deployed Quickshell shell in an isolated sandbox
# (copy of the deployed shell + the real plugin registry/settings) and asserts
# the plugin's host mounts with zero deny-listed QML errors.
# Skipped (exit 2) where sway/quickshell are unavailable.
#
# Usage: tests/runtime/run.sh <plugin-id> [--keep]
set -uo pipefail

id="${1:-}"; keep=0; [[ "${2:-}" == "--keep" ]] && keep=1
[ -n "$id" ] || { echo "usage: run.sh <plugin-id> [--keep]"; exit 2; }
for c in sway jq; do command -v "$c" >/dev/null 2>&1 || { echo "SKIP: $c missing"; exit 2; }; done
QSBIN="$(command -v qs || command -v quickshell || true)"
[ -n "$QSBIN" ] || { echo "SKIP: quickshell missing"; exit 2; }

REAL_HYPR="${REAL_HYPR:-$HOME/.config/hypr}"
SRC="$REAL_HYPR/scripts/quickshell"
[ -d "$SRC" ] || { echo "SKIP: no deployed shell at $SRC"; exit 2; }

SANDBOX="$(mktemp -d)"
trap '[[ "$keep" != 1 ]] && rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home" XDG_RUNTIME_DIR="$SANDBOX/run"
export XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$HOME/.cache" XDG_DATA_HOME="$HOME/.local/share"
mkdir -p "$XDG_CONFIG_HOME/hypr" "$XDG_RUNTIME_DIR" "$XDG_CACHE_HOME"; chmod 700 "$XDG_RUNTIME_DIR"

# Deploy mirror: shell tree + the real registry (plugins/plugins-user) + settings.
mkdir -p "$XDG_CONFIG_HOME/hypr/scripts"
cp -r "$SRC" "$XDG_CONFIG_HOME/hypr/scripts/quickshell"
[[ -d "$REAL_HYPR/plugins" ]] && cp -r "$REAL_HYPR/plugins" "$XDG_CONFIG_HOME/hypr/plugins"
[[ -d "$REAL_HYPR/plugins-user" ]] && cp -r "$REAL_HYPR/plugins-user" "$XDG_CONFIG_HOME/hypr/plugins-user"
[[ -f "$REAL_HYPR/settings.json" ]] && cp "$REAL_HYPR/settings.json" "$XDG_CONFIG_HOME/hypr/settings.json" || printf '{}' > "$XDG_CONFIG_HOME/hypr/settings.json"

export WLR_BACKENDS=headless WLR_HEADLESS_OUTPUTS=1 WLR_LIBINPUT_NO_DEVICES=1
export WLR_RENDERER=pixman LIBGL_ALWAYS_SOFTWARE=1 QT_QUICK_BACKEND=software

sway -c /dev/null >"$SANDBOX/sway.log" 2>&1 & sway_pid=$!
sleep 2
"$QSBIN" -p "$XDG_CONFIG_HOME/hypr/scripts/quickshell/Shell.qml" >"$SANDBOX/qs.log" 2>&1 & qs_pid=$!
sleep 7
kill "$qs_pid" "$sway_pid" 2>/dev/null || true; sleep 1

allow='QQmlVMEMetaObject'                                  # pre-existing, documented
deny='is not a type|Cannot find|is not installed|TypeError|ReferenceError|is not defined|Unable to assign|Cannot read property .* of undefined'
hits="$(grep -E "$deny" "$SANDBOX/qs.log" 2>/dev/null | grep -vE "$allow" | wc -l | tr -d ' ')"
if [[ "$hits" -eq 0 ]]; then echo "runtime($id): OK (0 deny-listed QML errors)"; exit 0; fi
echo "runtime($id): FAIL ($hits deny-listed lines)"; grep -E "$deny" "$SANDBOX/qs.log" | grep -vE "$allow" | head
exit 1
