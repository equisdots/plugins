#!/usr/bin/env bash
# calculator — evaluate an arithmetic expression for the Calculator panel.
#
# Usage: calculator.sh "<expression>"
# Prints the result to stdout. When qalc is not installed it prints the
# sentinel __NO_QALC__ so the panel falls back to its own JS evaluator
# (which only understands numbers and + - * / ( )).
set -uo pipefail

expr="${1:-}"
[ -n "$expr" ] || exit 0

if command -v qalc >/dev/null 2>&1; then
    qalc -t "$expr" 2>/dev/null
    exit $?
fi

printf '__NO_QALC__'
