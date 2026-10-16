#!/usr/bin/env bash
# worldclock-widget — value producer for the World Clock widget face.
# Prints the time (line 1) then the date (line 2) in the requested timezone.
# The timezone is arg 1 (defaults to UTC); the face passes settings.worldclock.tz.
set -uo pipefail
tz="${1:-UTC}"
TZ="$tz" date '+%H:%M'
TZ="$tz" date '+%a %d %b'
