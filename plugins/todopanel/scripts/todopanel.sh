#!/usr/bin/env bash
# todopanel — read/write the equisdots todo file for the Todo panel.
#
# Usage:
#   todopanel.sh list             list tasks (one per line: <n>\t<0|1>\t<text>)
#   todopanel.sh add <text...>    append a task
#   todopanel.sh toggle <n>       toggle done on file line <n>
#   todopanel.sh delete <n>       delete file line <n>
#
# One task per line; a task starting with "x " is done. <n> is the 1-based
# physical line number, so list output and mutations always agree. The file is
# rewritten through a temp file + mv (atomic) on every mutation.
set -uo pipefail

f="${TODO_FILE:-$HOME/.local/share/equisdots/todo.txt}"
dir="$(dirname "$f")"
mkdir -p "$dir"
[ -f "$f" ] || : > "$f"

cmd="${1:-list}"

case "$cmd" in
    list)
        n=0
        while IFS= read -r line || [ -n "$line" ]; do
            n=$((n + 1))
            [ -z "$line" ] && continue
            case "$line" in
                "x "*)
                    # Skip blank tasks after the done marker too.
                    rest="${line#x }"
                    [ -z "$rest" ] && continue
                    printf '%s\t1\t%s\n' "$n" "$rest"
                    ;;
                *)
                    printf '%s\t0\t%s\n' "$n" "$line"
                    ;;
            esac
        done < "$f"
        ;;
    add)
        shift || true
        text="$*"
        [ -n "$text" ] || exit 0
        printf '%s\n' "$text" >> "$f"
        ;;
    toggle)
        n="${2:-}"
        case "$n" in ''|*[!0-9]*) exit 1 ;; esac
        tmp="$f.tmp.$$"
        if awk -v n="$n" '
            NR == n {
                if ($0 ~ /^x /) { sub(/^x /, "") } else { $0 = "x " $0 }
            }
            { print }
        ' "$f" > "$tmp"; then
            mv "$tmp" "$f"
        else
            rm -f "$tmp"
            exit 1
        fi
        ;;
    delete)
        n="${2:-}"
        case "$n" in ''|*[!0-9]*) exit 1 ;; esac
        tmp="$f.tmp.$$"
        if awk -v n="$n" 'NR != n { print }' "$f" > "$tmp"; then
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
