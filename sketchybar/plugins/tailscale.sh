#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
item="${NAME:-tailscale}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/settings.sh"
source "$CONFIG_DIR/colors.sh"

if ! command -v tailscale >/dev/null 2>&1; then
  sketchybar --set "$item" drawing=off
  exit 0
fi

state="$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null)"

if [[ "$state" == "Running" ]]; then
  ip="$(tailscale status 2>/dev/null | head -1 | awk '{print $1}')"

  if [[ -n "$ip" ]]; then
    sketchybar --set "$item" \
      drawing=on \
      icon=":tailscale:" \
      icon.font="$APP_FONT:20.0" \
      icon.y_offset=1 \
      "icon.color=$TEXT" \
      "label=$ip" \
      "label.color=$SUBTEXT"
  else
    sketchybar --set "$item" \
      drawing=on \
      icon=":tailscale:" \
      icon.font="$APP_FONT:20.0" \
      icon.y_offset=1 \
      "icon.color=$TEXT" \
      label.drawing=off
  fi
else
  sketchybar --set "$item" \
    drawing=on \
    icon=":tailscale:" \
    icon.font="$APP_FONT:20.0" \
    icon.y_offset=1 \
    "icon.color=$MUTED" \
    label.drawing=off
fi
