#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
item="${NAME:-battery}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/colors.sh"

pmset_output="$(pmset -g batt 2>/dev/null || true)"

if [[ "$pmset_output" =~ ([0-9]+)% ]]; then
  percent="${BASH_REMATCH[1]}"
else
  percent=""
fi

if [[ -z "$percent" ]]; then
  sketchybar --set "$item" drawing=off
  exit 0
fi

if (( percent >= 88 )); then
  icon=""
elif (( percent >= 63 )); then
  icon=""
elif (( percent >= 38 )); then
  icon=""
elif (( percent >= 15 )); then
  icon=""
else
  icon=""
fi

if [[ "$pmset_output" =~ [Aa][Cc][[:space:]][Pp]ower|[Cc]harging|[Cc]harged ]]; then
  icon="󰂄"
  colour="$GREEN"
elif (( percent <= 15 )); then
  colour="$RED"
elif (( percent <= 30 )); then
  colour="$YELLOW"
else
  colour="$SUBTEXT"
fi

sketchybar --set "$item" \
  drawing=on \
  "icon=$icon" \
  "icon.color=$colour" \
  "label=${percent}%"
