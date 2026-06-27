#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/settings.sh"
source "$CONFIG_DIR/colors.sh"

spaces_json="$(yabai -m query --spaces 2>/dev/null || printf '[]')"
windows_json="$(yabai -m query --windows 2>/dev/null || printf '[]')"

if [[ -r "$CONFIG_DIR/icon_map.sh" ]]; then
  # shellcheck disable=SC1091
  source "$CONFIG_DIR/icon_map.sh"
fi

# The active space wears a coloured pill; the colour rotates per space so the
# focused workspace has a subtle identity without painting all eight at once.
space_background() {
  case "$1" in
    1|5) printf '%s' "$BLUE_BG" ;;
    2|6) printf '%s' "$LAVENDER_BG" ;;
    3|7) printf '%s' "$TEAL_BG" ;;
    4|8) printf '%s' "$PEACH_BG" ;;
  esac
}

# Each space carries an accent colour so the row reads as colourful identifiers
# rather than eight grey numbers. The palette repeats after four.
space_accent() {
  case "$1" in
    1|5) printf '%s' "$BLUE" ;;
    2|6) printf '%s' "$LAVENDER" ;;
    3|7) printf '%s' "$TEAL" ;;
    4|8) printf '%s' "$PEACH" ;;
  esac
}

map_icon() {
  local app="$1"

  if type __icon_map >/dev/null 2>&1; then
    icon_result=""
    __icon_map "$app"

    case "${icon_result:-}" in
      ""|":default:") return 0 ;;
      *) printf '%s' "$icon_result" ;;
    esac
  fi
}

# ---------------------------------------------------------------------------
# Pull everything from yabai in just two jq passes instead of ~4 per space.
# ---------------------------------------------------------------------------
declare -A space_exists space_focus space_apps

while IFS=$'\t' read -r idx foc; do
  [[ -n "$idx" ]] || continue
  space_exists[$idx]=1
  space_focus[$idx]="$foc"
done < <(
  jq -r '.[] | "\(.index)\t\(.["has-focus"])"' <<<"$spaces_json" 2>/dev/null
)

# Accumulate apps per space, de-duplicated but keeping first-seen order. App
# names can contain spaces, so membership is tested against a newline-delimited
# list with exact line matching.
while IFS=$'\t' read -r sid app; do
  [[ -n "$sid" && -n "$app" ]] || continue
  current="${space_apps[$sid]-}"
  case $'\n'"$current"$'\n' in
    *$'\n'"$app"$'\n'*) ;;
    *) space_apps[$sid]="${current:+$current$'\n'}$app" ;;
  esac
done < <(
  jq -r '.[] | select((.app // "") != "") | "\(.space)\t\(.app)"' \
    <<<"$windows_json" 2>/dev/null
)

args=()

for sid in $(seq 1 "$SPACE_COUNT"); do
  if [[ -z "${space_exists[$sid]:-}" ]]; then
    args+=(--set "space.$sid" drawing=off)
    (( sid < SPACE_COUNT )) && args+=(--set "space.gap.$sid" drawing=off)
    continue
  fi

  accent="$(space_accent "$sid")"
  accent_dim="0x80${accent#0xff}"

  icons=""
  if [[ -n "${space_apps[$sid]:-}" ]]; then
    while IFS= read -r app; do
      [[ -n "$app" ]] || continue
      glyph="$(map_icon "$app")"
      [[ -n "$glyph" ]] || continue
      icons="${icons:+$icons }$glyph"
    done <<<"${space_apps[$sid]}"
  fi

  if [[ -n "$icons" ]]; then
    label_draw=on
  else
    label_draw=off
  fi

  if [[ "${space_focus[$sid]:-}" == "true" ]]; then
    # Focused: white number on the accent-tinted pill.
    args+=(
      --set "space.$sid"
        drawing=on
        "icon=$sid"
        "icon.color=$TEXT"
        "label=$icons"
        "label.color=$TEXT"
        "label.drawing=$label_draw"
        background.drawing=on
        "background.color=$(space_background "$sid")"
    )
  elif [[ -n "$icons" ]]; then
    # Occupied: accent number, accent app glyphs.
    args+=(
      --set "space.$sid"
        drawing=on
        "icon=$sid"
        "icon.color=$accent"
        "label=$icons"
        "label.color=$accent"
        label.drawing=on
        background.drawing=off
    )
  else
    # Empty: dimmed accent number, no glyphs.
    args+=(
      --set "space.$sid"
        drawing=on
        "icon=$sid"
        "icon.color=$accent_dim"
        label.drawing=off
        background.drawing=off
    )
  fi

  (( sid < SPACE_COUNT )) && args+=(--set "space.gap.$sid" drawing=on)
done

((${#args[@]})) && sketchybar --animate tanh 8 "${args[@]}"
