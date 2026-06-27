#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
item="${NAME:-focus}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/colors.sh"

assertions_file="$HOME/Library/DoNotDisturb/DB/Assertions.json"

if [[ -r "$assertions_file" ]]; then
  active_modes="$(
    jq -r '
      [.data[].storeAssertionRecords[]? |
        .assertionDetails.assertionDetailsModeIdentifier
      ] | unique | join(",")
    ' "$assertions_file" 2>/dev/null
  )"
else
  active_modes=""
fi

if [[ -n "$active_modes" ]]; then
  case "$active_modes" in
    *reduce-interruptions*)   icon="󰢝"  ;;
    *donotdisturb.mode.default*) icon="󰒲"  ;;
    *sleep.sleep-mode*)       icon="󰒲"  ;;
    *work*)                   icon=""  ;;
    *personal*)               icon="󰀴"  ;;
    *)                        icon="󰒲"  ;;
  esac
  sketchybar --set "$item" \
    drawing=on \
    "icon=$icon" \
    "icon.color=$FOCUS" \
    "icon.drawing=on"
else
  sketchybar --set "$item" \
    drawing=on \
    icon="󰒲" \
    "icon.color=$MUTED" \
    "icon.drawing=off"
fi
