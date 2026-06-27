#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
item="${NAME:-weather}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/settings.sh"

location="${WEATHER_LOCATION:-Bengaluru}"
units="${WEATHER_UNITS:-m}"
ttl="${WEATHER_CACHE_TTL:-600}"
location_key="${location//[^[:alnum:]]/_}"
cache_file="${TMPDIR:-/tmp}/mukul-sketchybar-weather-${location_key}-${units}.json"
lock_dir="${TMPDIR:-/tmp}/mukul-sketchybar-weather.lock"

if [[ "$units" == "u" ]]; then
  url="https://wttr.in/${location}?format=j1&u"
  temp_field="temp_F"
  feels_field="FeelsLikeF"
  min_field="mintempF"
  max_field="maxtempF"
  temp_unit="°F"
else
  url="https://wttr.in/${location}?format=j1&m"
  temp_field="temp_C"
  feels_field="FeelsLikeC"
  min_field="mintempC"
  max_field="maxtempC"
  temp_unit="°C"
fi

weather_emoji() {
  case "$1" in
    *Sunny*|*Clear*)   printf '☀️' ;;
    *Partly*)          printf '🌤️' ;;
    *Cloud*|*Overcast*) printf '☁️' ;;
    *Mist*|*Fog*|*Haze*) printf '🌫️' ;;
    *Rain*|*Drizzle*|*Shower*) printf '🌧️' ;;
    *Thunder*)         printf '⛈️' ;;
    *Snow*|*Blizzard*|*Sleet*) printf '🌨️' ;;
    *)                 printf '🌦️' ;;
  esac
}

is_cache_fresh() {
  local modified now
  [[ -r "$cache_file" ]] || return 1
  modified="$(stat -f %m "$cache_file" 2>/dev/null || printf 0)"
  now="$(date +%s)"
  [[ "$modified" =~ ^[0-9]+$ ]] || return 1
  (( now - modified < ttl ))
}

parse_json() {
  local parsed
  parsed="$(
    jq -r --arg tf "$temp_field" --arg ff "$feels_field" \
          --arg mnf "$min_field" --arg mxf "$max_field" '
      .current_condition[0] as $c | .weather[0] as $w |
      [ ($c[$tf] // ""), ($c[$ff] // ""), ($c.humidity // ""),
        ($c.precipMM // ""),
        ($c.weatherDesc[0].value // ""),
        ($w[$mnf] // ""), ($w[$mxf] // "") ] | @tsv
    ' <<<"$1" 2>/dev/null
  )"

  IFS=$'\t' read -r temp feels humidity precip desc min_temp max_temp <<<"$parsed"

  icon="$(weather_emoji "$desc")"
  [[ -n "$temp" ]]      || temp="--"
  [[ -n "$feels" ]]     || feels="--"
  [[ -n "$humidity" ]]  || humidity="--"
  [[ -n "$precip" ]]    || precip="--"
  [[ -n "$desc" ]]      || desc="—"
  [[ -n "$min_temp" ]]  || min_temp="--"
  [[ -n "$max_temp" ]]  || max_temp="--"
}

update_item() {
  if [[ -n "$icon" && "$temp" != "--" ]]; then
    sketchybar --set "$item" \
      drawing=on \
      "icon=$icon" \
      "icon.color=$WEATHER" \
      "label=${temp}${temp_unit}" \
      "label.color=$TEXT"
  else
    sketchybar --set "$item" \
      drawing=on \
      icon="󰖐" \
      "icon.color=$MUTED" \
      label="--" \
      "label.color=$MUTED"
  fi
}

update_popup() {
  sketchybar \
    --set weather.popup.location  "label=$location" \
    --set weather.popup.condition "label=$desc" \
    --set weather.popup.feels    "label=${feels}${temp_unit}" \
    --set weather.popup.lohi     "label=${min_temp}${temp_unit} / ${max_temp}${temp_unit}" \
    --set weather.popup.humidity "label=${humidity}%" \
    --set weather.popup.rain     "label=${precip}mm"
}

fetch_weather() {
  local fetched

  mkdir "$lock_dir" 2>/dev/null || return 0
  trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT

  fetched="$(curl -fsS --connect-timeout 1 --max-time 3 "$url" 2>/dev/null || true)"

  if jq -e '.current_condition[0]' >/dev/null 2>&1 <<<"$fetched"; then
    printf '%s' "$fetched" >"$cache_file" 2>/dev/null || true
    parse_json "$fetched"
    update_item
    update_popup
  fi
}

refresh_async() {
  ( fetch_weather >/dev/null 2>&1 ) &
}

show_placeholder() {
  sketchybar \
    --set weather.popup.location  "label=$location" \
    --set weather.popup.condition label="Updating..." \
    --set weather.popup.feels    label="—" \
    --set weather.popup.lohi     label="—" \
    --set weather.popup.humidity label="—" \
    --set weather.popup.rain     label="—"
}

case "${SENDER:-routine}" in
  mouse.clicked)
    if [[ "${BUTTON:-left}" == "right" ]]; then
      open "https://wttr.in/$location"
      exit 0
    fi

    if [[ -r "$cache_file" ]] && parse_json "$(<"$cache_file")"; then
      update_popup
      update_item
    else
      show_placeholder
    fi

    sketchybar \
      --set wifi popup.drawing=off \
      --set "$item" popup.drawing=toggle

    is_cache_fresh || refresh_async
    ;;
  mouse.exited.global)
    sketchybar --set "$item" popup.drawing=off
    ;;
  *)
    if [[ -r "$cache_file" ]] && parse_json "$(<"$cache_file")"; then
      update_item
    else
      sketchybar --set "$item" icon="󰖐" "icon.color=$MUTED" label="--" "label.color=$MUTED"
    fi

    is_cache_fresh || refresh_async
    ;;
esac
