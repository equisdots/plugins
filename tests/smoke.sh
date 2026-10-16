#!/usr/bin/env bash
# smoke.sh — static integration smoke test for an equisdots plugin.
#
# Usage:
#   tests/smoke.sh <plugin-dir>          # e.g. plugins/dock  or  a deployed dir
#   tests/smoke.sh                       # every plugins/*/ with a plugin.json
#
# Checks (deterministic, no compositor needed):
#   01 manifest parses + required fields + id == folder name
#   02 every directory import has a qmldir (the "X is not a type" trap)
#   03 plugins_scan.sh resolves enabled/config/compat for a fixture settings
#   04 lints: qmllint (*.qml), luac -p (*.lua), bash -n (*.sh), node --check (*.js)
#
# Exit: 0 pass, 1 failure, 2 environment missing (infra, not product).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_REPO="$(cd "$HERE/.." && pwd)"
fail=0
say()  { printf '%s\n' "$*"; }
bad()  { printf '\033[31mFAIL\033[0m %s\n' "$*"; fail=1; }
good() { printf '\033[32m ok \033[0m %s\n' "$*"; }

for c in jq qmllint; do command -v "$c" >/dev/null 2>&1 || { echo "SKIP: $c missing"; exit 2; }; done

check_manifest() {
    local d="$1" m="$d/plugin.json"
    [ -f "$m" ] || { bad "$d: no plugin.json"; return; }
    jq -e . "$m" >/dev/null 2>&1 || { bad "$d: invalid JSON"; return; }
    for k in id name version author description type; do
        jq -e "has(\"$k\") and (.[\"$k\"]|tostring|length>0)" "$m" >/dev/null || bad "$d: missing field '$k'"
    done
    local id; id="$(jq -r '.id' "$m")"
    [ "$(basename "$d")" = "$id" ] || bad "$d: id '$id' != folder '$(basename "$d")'"
    good "manifest: $id"
}

check_qmldir() {
    local d="$1"
    local miss=0 f fdir rel target
    while IFS= read -r f; do
        fdir="$(dirname "$f")"
        while IFS= read -r rel; do
            case "$rel" in .*) ;; *) continue ;; esac
            target="$(cd "$fdir" && cd "$rel" 2>/dev/null && pwd)" || continue
            [ -d "$target" ] || continue
            if [ ! -f "$target/qmldir" ]; then
                bad "$f: import \"$rel\" -> $target has no qmldir"
                miss=1
            fi
        done < <(grep -oE 'import[[:space:]]+"[^"]+"' "$f" | sed -E 's/import[[:space:]]+"([^"]+)"/\1/')
    done < <(find "$d" -name '*.qml')
    [ "$miss" = 0 ] && good "qmldir: all directory imports declared"
}

check_scan() {
    local d="$1" id; id="$(jq -r '.id' "$d/plugin.json")"
    local scan="$HERE/../.."
    # find the shell scan in a sibling repo (dev layout) or skip
    local sc=""
    for cand in "$PLUGINS_REPO/../shell/core/scripts/plugins_scan.sh"; do
        [ -f "$cand" ] && sc="$cand"
    done
    if [ -z "$sc" ]; then say "skip: scan not found"; return; fi
    local tmp; tmp="$(mktemp -d)"
    mkdir -p "$tmp/managed" "$tmp/user"
    cp -r "$d" "$tmp/managed/$id"
    printf '{}' > "$tmp/settings.json"
    local out
    out="$(PLUGINS_MANAGED="$tmp/managed" PLUGINS_USER="$tmp/user" PLUGINS_SETTINGS="$tmp/settings.json" bash "$sc" 2>/dev/null)"
    rm -rf "$tmp"
    local found; found="$(jq -r --arg id "$id" '.[]|select(.id==$id)|.id' <<<"$out")"
    [ "$found" = "$id" ] && good "scan: $id resolved" || bad "scan: $id not resolved"
}

check_lints() {
    local d="$1" ok=1
    while IFS= read -r f; do
        qmllint "$f" >/dev/null 2>&1 || { bad "qmllint: $f"; ok=0; }
    done < <(find "$d" -name '*.qml')
    if command -v luac >/dev/null 2>&1; then
        while IFS= read -r f; do luac -p "$f" >/dev/null 2>&1 || { bad "luac: $f"; ok=0; }; done < <(find "$d" -name '*.lua')
    fi
    while IFS= read -r f; do bash -n "$f" >/dev/null 2>&1 || { bad "bash -n: $f"; ok=0; }; done < <(find "$d" -name '*.sh')
    if command -v node >/dev/null 2>&1; then
        while IFS= read -r f; do
            # QML JS modules may open with pragmas (".pragma library") that are
            # not valid JS: strip leading pragma lines before node's check.
            local tmpf; tmpf="$(mktemp --suffix=.js)"
            sed '/^\.pragma /d' "$f" > "$tmpf"
            node --check "$tmpf" >/dev/null 2>&1 || { bad "node --check: $f"; ok=0; }
            rm -f "$tmpf"
        done < <(find "$d" -name '*.js')
    fi
    [ "$ok" = 1 ] && good "lints clean"
}

# Hub-level identity integrity (local, no CI): unique manifest ids across the
# concentration folder, a valid registry with unique ids, hub-local registry
# entries resolving to the real folders, and every hub plugin registered.
check_hub_integrity() {
    say "── hub integrity"
    local reg="$PLUGINS_REPO/registry.json"

    # 1) duplicate manifest ids across plugins/*
    local dups
    dups="$(for f in "$PLUGINS_REPO"/plugins/*/plugin.json; do
                [ -f "$f" ] || continue
                jq -r '.id // empty' "$f" 2>/dev/null
            done | sort | uniq -d)"
    if [ -n "$dups" ]; then
        while IFS= read -r id; do bad "duplicate plugin id in hub: $id"; done <<<"$dups"
    else
        good "hub ids unique"
    fi

    # 2) registry: valid JSON + unique ids
    if ! jq -e . "$reg" >/dev/null 2>&1; then
        bad "registry.json: invalid JSON"
        return
    fi
    dups="$(jq -r '(.plugins // []) | group_by(.id) | map(select(length > 1) | .[0].id) | join(", ")' "$reg")"
    [ -z "$dups" ] && good "registry ids unique" || bad "registry duplicate ids: $dups"

    # 3) hub-local entries resolve to a folder with the matching manifest id
    local rid rpath mid entryerr=0
    while IFS=$'\t' read -r rid rpath; do
        if [ -z "$rpath" ]; then
            bad "registry entry '$rid': missing path for a hub-local plugin"; entryerr=1; continue
        fi
        if [ ! -f "$PLUGINS_REPO/$rpath/plugin.json" ]; then
            bad "registry entry '$rid': $rpath/plugin.json not found"; entryerr=1; continue
        fi
        mid="$(jq -r '.id // empty' "$PLUGINS_REPO/$rpath/plugin.json" 2>/dev/null)"
        [ "$mid" = "$rid" ] || { bad "registry entry '$rid': folder declares id '$mid'"; entryerr=1; }
    done < <(jq -r '(.plugins // [])[] | select(.source == "equisdots/plugins") | [.id, (.path // "")] | @tsv' "$reg")
    [ "$entryerr" = 0 ] && good "registry hub-local entries resolved"

    # 4) every hub plugin folder (except the _template scaffold) is registered
    local d id unreg=0
    for d in "$PLUGINS_REPO"/plugins/*/; do
        id="$(basename "${d%/}")"
        case "$id" in _*) continue ;; esac
        if ! jq -e --arg id "$id" 'any((.plugins // [])[]; .id == $id)' "$reg" >/dev/null; then
            bad "hub plugin '$id' is not in registry.json"; unreg=1
        fi
    done
    [ "$unreg" = 0 ] && good "every hub plugin is registered"
}

run_one() {
    local d="$1"
    say "── $d"
    check_manifest "$d"
    check_qmldir "$d"
    check_scan "$d"
    check_lints "$d"
}

if [ "$#" -ge 1 ]; then
    run_one "$1"
else
    check_hub_integrity
    for d in "$PLUGINS_REPO"/plugins/*/; do
        case "$(basename "$d")" in _*) continue ;; esac
        [ -f "$d/plugin.json" ] && run_one "${d%/}"
    done
fi

[ "$fail" = 0 ] && say "SMOKE: OK" || say "SMOKE: FAILURES"
exit "$fail"
