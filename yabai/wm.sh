#!/bin/sh

set -eu

PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

YABAI="${YABAI:-$(command -v yabai)}"
JQ="${JQ:-$(command -v jq)}"

SKETCHYBAR="${SKETCHYBAR:-$(command -v sketchybar 2>/dev/null || true)}"
BAR_HEIGHT="${BAR_HEIGHT:-40}"

# -----------------------------------------------------------------------------
# Spaces
# -----------------------------------------------------------------------------

# Resolve a display-local slot to its global Mission Control space index.
#
# Slot 1 means the first space on whichever display is currently focused.
local_space() {
  slot="$1"

  case "$slot" in
    ''|*[!0-9]*|0)
      return 2
      ;;
  esac

  offset=$((slot - 1))

  "$YABAI" -m query --displays --display |
    "$JQ" -er ".spaces[$offset] // empty"
}

focus_local_space() {
  space="$(local_space "$1")" || exit 0
  [ -n "$space" ] || exit 0

  "$YABAI" -m space --focus "$space"
}

move_to_space() {
  space="$1"

  window_id="$(
    "$YABAI" -m query --windows --window |
      "$JQ" -er '.id'
  )"

  "$YABAI" -m window "$window_id" --space "$space"
  "$YABAI" -m space --focus "$space"

  # Restore focus to the window after the space transition.
  "$YABAI" -m window --focus "$window_id" 2>/dev/null || true
}

move_to_local_space() {
  space="$(local_space "$1")" || exit 0
  [ -n "$space" ] || exit 0

  move_to_space "$space"
}

focus_relative_space() {
  selector="$1"
  "$YABAI" -m space --focus "$selector"
}

move_to_relative_space() {
  selector="$1"

  target_space="$(
    "$YABAI" -m query --spaces --space "$selector" |
      "$JQ" -er '.index'
  )"

  move_to_space "$target_space"
}

# -----------------------------------------------------------------------------
# Focus and movement
# -----------------------------------------------------------------------------

focus_direction() {
  direction="$1"

  # Focus a neighbouring window first; cross a display edge otherwise.
  "$YABAI" -m window --focus "$direction" 2>/dev/null ||
    "$YABAI" -m display --focus "$direction" 2>/dev/null ||
    true
}

move_direction() {
  direction="$1"

  # Reinsert within the current BSP tree.
  if "$YABAI" -m window --warp "$direction" 2>/dev/null; then
    exit 0
  fi

  # At the edge of a display, send the window to the adjacent display.
  target_display="$(
    "$YABAI" -m query --displays --display "$direction" 2>/dev/null |
      "$JQ" -er '.index' 2>/dev/null ||
      true
  )"

  if [ -n "$target_display" ]; then
    window_id="$(
      "$YABAI" -m query --windows --window |
        "$JQ" -er '.id'
    )"

    if "$YABAI" -m window "$window_id" --display "$target_display" 2>/dev/null; then
      "$YABAI" -m display --focus "$target_display" 2>/dev/null || true
      "$YABAI" -m window --focus "$window_id" 2>/dev/null || true
      exit 0
    fi
  fi

  # Final fallback: nudge a floating window.
  case "$direction" in
    west)
      "$YABAI" -m window --move rel:-20:0
      ;;
    east)
      "$YABAI" -m window --move rel:20:0
      ;;
    north)
      "$YABAI" -m window --move rel:0:-20
      ;;
    south)
      "$YABAI" -m window --move rel:0:20
      ;;
    *)
      exit 2
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Stacks
# -----------------------------------------------------------------------------

stack_direction() {
  direction="$1"

  focused_id="$(
    "$YABAI" -m query --windows --window |
      "$JQ" -er '.id'
  )"

  target_id="$(
    "$YABAI" -m query --windows --window "$direction" 2>/dev/null |
      "$JQ" -er '.id' 2>/dev/null ||
      true
  )"

  [ -n "$target_id" ] || exit 0

  # Stack the focused window on the directional neighbour.
  "$YABAI" -m window "$target_id" --stack "$focused_id"
  "$YABAI" -m window --focus "$focused_id" 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# SketchyBar
# -----------------------------------------------------------------------------

toggle_bar() {
  [ -n "$SKETCHYBAR" ] || {
    printf '%s\n' "wm.sh: sketchybar is not installed" >&2
    exit 1
  }

  hidden="$(
    "$SKETCHYBAR" --query bar 2>/dev/null |
      "$JQ" -r '.hidden // "off"' 2>/dev/null ||
      printf '%s' off
  )"

  case "$hidden" in
    on|true)
      # Restore yabai padding before showing the bar.
      "$YABAI" -m config external_bar "all:${BAR_HEIGHT}:0"
      "$SKETCHYBAR" --bar hidden=off
      ;;
    *)
      "$SKETCHYBAR" --bar hidden=on
      "$YABAI" -m config external_bar off
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Dispatch
# -----------------------------------------------------------------------------

case "${1:-}" in
  focus-space)
    focus_local_space "$2"
    ;;

  move-space)
    move_to_local_space "$2"
    ;;

  focus-relative-space)
    focus_relative_space "$2"
    ;;

  move-relative-space)
    move_to_relative_space "$2"
    ;;

  focus)
    focus_direction "$2"
    ;;

  move)
    move_direction "$2"
    ;;

  stack)
    stack_direction "$2"
    ;;

  toggle-bar)
    toggle_bar
    ;;

  *)
    printf '%s\n' \
      "usage: $0 {focus-space|move-space|focus-relative-space|move-relative-space|focus|move|stack|toggle-bar} [argument]" >&2
    exit 2
    ;;
esac
