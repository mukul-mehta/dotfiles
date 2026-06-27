#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/settings.sh"

CACHE_DIR="${TMPDIR:-/tmp}/mukul-sketchybar-media"

mkdir -p "$CACHE_DIR"

hide_media() {
  sketchybar \
    --set media.previous drawing=off \
    --set media.artwork drawing=off \
    --set media.text drawing=off \
    --set media.play drawing=off \
    --set media.next drawing=off
}

show_media() {
  sketchybar \
    --set media.previous drawing=on \
    --set media.artwork drawing=on \
    --set media.text drawing=on \
    --set media.play drawing=on \
    --set media.next drawing=on
}

decode_artwork() {
  local data="$1"
  local target="$2"
  local temporary="${target}.tmp"

  rm -f "$temporary"

  if printf '%s' "$data" | base64 --decode >"$temporary" 2>/dev/null; then
    :
  elif printf '%s' "$data" | base64 -D >"$temporary" 2>/dev/null; then
    :
  else
    rm -f "$temporary"
    return 1
  fi

  if [[ -s "$temporary" ]]; then
    # Album art arrives at full resolution (600–1400px). Resample it down to a
    # small fixed square so the background.image.scale in sketchybarrc is a
    # stable constant; without this the raw image renders hundreds of points
    # wide and spills out of the bar.
    local size="${MEDIA_ART_SIZE:-56}"
    if sips -s format png -Z "$size" "$temporary" --out "${temporary}.png" \
         >/dev/null 2>&1 && [[ -s "${temporary}.png" ]]; then
      mv "${temporary}.png" "$target"
      rm -f "$temporary"
    else
      mv "$temporary" "$target"
    fi
    return 0
  fi

  rm -f "$temporary"
  return 1
}

if ! command -v nowplaying-cli >/dev/null 2>&1; then
  hide_media
  exit 0
fi

json="$(
  nowplaying-cli get \
    uniqueIdentifier title album artist playbackRate \
    --json 2>/dev/null ||
    printf '{}'
)"

title="$(jq -r '.title // empty' <<<"$json" 2>/dev/null)"
album="$(jq -r '.album // empty' <<<"$json" 2>/dev/null)"
artist="$(jq -r '.artist // empty' <<<"$json" 2>/dev/null)"
identifier="$(jq -r '.uniqueIdentifier // empty' <<<"$json" 2>/dev/null)"
playback_rate="$(jq -r '.playbackRate // 0' <<<"$json" 2>/dev/null)"

if [[ -z "$title" ]]; then
  hide_media
  exit 0
fi

show_media

if [[ -n "$artist" ]]; then
  text="$title — $artist"
else
  text="$title"
fi

if awk -v rate="$playback_rate" 'BEGIN { exit !(rate > 0) }'; then
  play_icon="󰏤"
  play_colour="$TEXT"
else
  play_icon="󰐊"
  play_colour="$SUBTEXT"
fi

# Some players do not expose a unique identifier, so construct a stable key.
if [[ -z "$identifier" ]]; then
  identifier="$title|$album|$artist"
fi

# sketchybar caches a decoded background image by its file path, so rewriting a
# single "artwork" file per track makes it keep serving the stale (or blank)
# image. Give every track its own hashed filename and prune the others.
art_hash="$(printf '%s' "$identifier" | md5 2>/dev/null | tr -dc 'a-f0-9')"
[[ -n "$art_hash" ]] || art_hash="current"
ART_FILE="$CACHE_DIR/art-${art_hash}.png"

if [[ ! -s "$ART_FILE" ]]; then
  artwork_data="$(
    nowplaying-cli get artworkData --json 2>/dev/null |
      jq -r '.artworkData // empty' 2>/dev/null
  )"

  if [[ -n "$artwork_data" ]]; then
    decode_artwork "$artwork_data" "$ART_FILE" || rm -f "$ART_FILE"
  fi

  # Keep only the current track's artwork around.
  find "$CACHE_DIR" -name 'art-*.png' ! -name "art-${art_hash}.png" -delete \
    2>/dev/null || true
fi

if [[ -s "$ART_FILE" ]]; then
  artwork_args=(
    --set media.artwork
      icon.drawing=off
      background.image.drawing=on
      "background.image=$ART_FILE"
  )
else
  artwork_args=(
    --set media.artwork
      icon.drawing=on
      background.image.drawing=off
      "background.color=$MEDIA_FALLBACK"
  )
fi

sketchybar \
  --set media.text "label=$text" \
  --set media.play "icon=$play_icon" "icon.color=$play_colour" \
  "${artwork_args[@]}"
