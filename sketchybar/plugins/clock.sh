#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

stamp="$(date '+%a %d %b|%H:%M')"

sketchybar \
  --set clock.date "label=${stamp%|*}" \
  --set clock.time "label=${stamp#*|}"
