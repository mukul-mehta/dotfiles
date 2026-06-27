#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cache_file="${TMPDIR:-/tmp}/mukul-sketchybar-display.cache"

# Debounce: display_change can fire multiple times in quick succession.
sleep 1

# Only reload if the display count actually changed. This prevents reload
# loops where the reload itself triggers another display_change event.
new_count="$(
  osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.screens.count + ""' \
    2>/dev/null
)"
new_count="${new_count%%.*}"
[[ "$new_count" =~ ^[0-9]+$ ]] || new_count=1

old_count=""
[[ -r "$cache_file" ]] && old_count="$(<"$cache_file")"

if [[ "$new_count" != "$old_count" ]]; then
  printf '%s' "$new_count" >"$cache_file" 2>/dev/null
  sketchybar --reload
fi
