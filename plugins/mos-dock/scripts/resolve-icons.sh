#!/usr/bin/env bash
# Resolve icon names to absolute theme files for the mos dock.
# Prints one "<name>\t<path>" line per resolved icon; unresolved names are
# omitted so the QML can fall back to Quickshell.iconPath or the glyph.
set -u

theme="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")"
bases=()
[ -n "$theme" ] && bases+=("$HOME/.local/share/icons/$theme" "$HOME/.icons/$theme" "/usr/share/icons/$theme")
bases+=("$HOME/.local/share/icons" "$HOME/.icons" "/usr/share/icons/hicolor"
        "/usr/share/icons/Adwaita" "/usr/share/icons/Papirus-Dark" "/usr/share/icons/Papirus")

for name in "$@"; do
    [ -n "$name" ] || continue
    case "$name" in
        /*)
            [ -f "$name" ] && printf '%s\t%s\n' "$name" "$name"
            continue
            ;;
    esac
    found=""
    for base in "${bases[@]}"; do
        [ -d "$base" ] || continue
        found="$(find "$base" \( -path "*/apps/$name.svg" -o -path "*/apps/$name.png" \) \
            -print -quit 2>/dev/null)"
        [ -n "$found" ] && break
    done
    [ -n "$found" ] && printf '%s\t%s\n' "$name" "$found"
done
