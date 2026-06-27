#!/usr/bin/env bash

export SPACE_COUNT=8

# Detect display count at source time so the bar can shrink on laptop-only.
# Uses a 10s file cache so that multiple plugins sourcing this in the same
# reload burst don't each fire a separate osascript call.
_display_cache="${TMPDIR:-/tmp}/mukul-sketchybar-display.cache"

if [[ -r "$_display_cache" ]]; then
  _cache_age=$(( $(date +%s) - $(stat -f %m "$_display_cache" 2>/dev/null || printf 0) ))
  if (( _cache_age < 10 )); then
    _display_count="$(<"$_display_cache")"
  fi
fi

if [[ -z "${_display_count:-}" ]]; then
  _display_count="$(
    osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.screens.count + ""' \
      2>/dev/null
  )"
  _display_count="${_display_count%%.*}"
  [[ "$_display_count" =~ ^[0-9]+$ ]] || _display_count=1
  printf '%s' "$_display_count" >"$_display_cache" 2>/dev/null
fi

if (( _display_count <= 1 )); then
  export BAR_HEIGHT=38
  export ISLAND_HEIGHT=30
  export ACTIVE_SPACE_HEIGHT=26
  export BAR_MARGIN=8
  export BAR_Y_OFFSET=5
else
  export BAR_HEIGHT=50
  export ISLAND_HEIGHT=40
  export ACTIVE_SPACE_HEIGHT=36
  export BAR_MARGIN=12
  export BAR_Y_OFFSET=7
fi

export TEXT_FONT="SF Pro Text"
export METRIC_FONT="JetBrainsMono Nerd Font Mono"
export ICON_FONT="JetBrainsMono Nerd Font"
export APP_FONT="sketchybar-app-font"

export MEDIA_ART_SIZE=56
export MEDIA_NOTCH_SHIFT=560

export WEATHER_LOCATION="Bengaluru"
export WEATHER_UNITS="m"
export WEATHER_CACHE_TTL=600
