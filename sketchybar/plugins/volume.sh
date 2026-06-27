#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
item="${NAME:-volume}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/colors.sh"

case "${SENDER:-routine}" in
  mouse.clicked)
    osascript -e 'set volume output muted (not (output muted of (get volume settings)))' \
      >/dev/null 2>&1
    ;;&
  mouse.scrolled)
    current="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
    [[ "$current" =~ ^[0-9]+$ ]] || current=50

    if (( SCROLL_DELTA > 0 )); then
      new=$(( current + 5 ))
    else
      new=$(( current - 5 ))
    fi
    (( new > 100 )) && new=100
    (( new < 0 )) && new=0

    osascript -e "set volume output volume $new" >/dev/null 2>&1
    ;;&
  *)
    vol="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
    muted="$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)"

    [[ "$vol" =~ ^[0-9]+$ ]] || vol=0

    if [[ "$muted" == "true" ]]; then
      icon="󰖁"
      colour="$MUTED"
    elif (( vol >= 66 )); then
      icon="󰕾"
      colour="$VOLUME"
    elif (( vol >= 33 )); then
      icon="󰖀"
      colour="$VOLUME"
    elif (( vol > 0 )); then
      icon="󰕿"
      colour="$SUBTEXT"
    else
      icon="󰖁"
      colour="$MUTED"
    fi

    sketchybar --set "$item" \
      "icon=$icon" \
      "icon.color=$colour" \
      "label=${vol}%"
    ;;
esac
