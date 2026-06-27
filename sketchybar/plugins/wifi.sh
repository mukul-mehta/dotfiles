#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
item="${NAME:-wifi}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/colors.sh"

# Single networksetup call — parse both device and service from it.
_hardware="$(networksetup -listallhardwareports 2>/dev/null)"
wifi_device="$(printf '%s' "$_hardware" | awk '/Hardware Port: (Wi-Fi|AirPort)/ { getline; sub(/^Device: /, ""); print; exit }')"
wifi_service="$(printf '%s' "$_hardware" | awk '/Hardware Port: (Wi-Fi|AirPort)/ { sub(/^Hardware Port: /, ""); print; exit }')"

wifi_ssid() {
  local device="$1"
  local ssid=""

  ssid="$(ipconfig getsummary "$device" 2>/dev/null | sed -n 's/^ *SSID : //p' | head -n 1)"

  if [[ -z "$ssid" || "$ssid" == "<redacted>" ]]; then
    ssid="$(networksetup -getairportnetwork "$device" 2>/dev/null | sed -n 's/^Current Wi-Fi Network: //p' | head -n 1)"
  fi

  local lower
  lower="$(tr '[:upper:]' '[:lower:]' <<<"$ssid")"

  case "$lower" in
    ""|"<redacted>"|"redacted"|"(null)"|"unknown"*|*"not associated"*|*"not connected"*)
      printf ''
      ;;
    *)
      printf '%s' "$ssid"
      ;;
  esac
}

update_status() {
  if [[ -z "$wifi_device" ]]; then
    sketchybar --set "$item" icon.color="$RED" label.drawing=off
    return
  fi

  local ip
  ip="$(ipconfig getifaddr "$wifi_device" 2>/dev/null || true)"

  if [[ -n "$ip" ]]; then
    sketchybar --set "$item" icon.color="$WIFI" label.drawing=off
  else
    sketchybar --set "$item" icon.color="$MUTED" label.drawing=off popup.drawing=off
  fi
}

update_popup() {
  if [[ -z "$wifi_device" ]]; then
    sketchybar \
      --set wifi.popup.network label="Unavailable" \
      --set wifi.popup.interface label="--" \
      --set wifi.popup.ipv4 label="--" \
      --set wifi.popup.router label="--" \
      --set wifi.popup.dns label="--" \
      --set wifi.popup.mac label="--"
    return
  fi

  local ssid ip router dns mac

  ssid="$(wifi_ssid "$wifi_device")"
  ip="$(ipconfig getifaddr "$wifi_device" 2>/dev/null || printf 'Not connected')"
  router="$(route -n get default 2>/dev/null | awk '/gateway:/ { print $2; exit }')"
  [[ -n "$router" ]] || router="--"

  dns="$(networksetup -getdnsservers "$wifi_service" 2>/dev/null | awk '/There aren.t any DNS Servers/ { exit } NF { values = values (values ? ", " : "") $0 } END { print values }')"

  if [[ -z "$dns" ]]; then
    dns="$(scutil --dns 2>/dev/null | awk '/nameserver\[[0-9]+\] :/ { if (!seen[$3]++) { values = values (values ? ", " : "") $3; count++ } if (count == 2) exit } END { print values }')"
  fi
  [[ -n "$dns" ]] || dns="--"

  mac="$(ifconfig "$wifi_device" 2>/dev/null | awk '/ether / { print $2; exit }')"
  [[ -n "$mac" ]] || mac="--"
  [[ -n "$ssid" ]] || ssid="Connected network"

  sketchybar \
    --set wifi.popup.network "label=$ssid" \
    --set wifi.popup.interface "label=$wifi_device" \
    --set wifi.popup.ipv4 "label=$ip" \
    --set wifi.popup.router "label=$router" \
    --set wifi.popup.dns "label=$dns" \
    --set wifi.popup.mac "label=$mac"
}

case "${SENDER:-routine}" in
  mouse.clicked)
    if [[ "${BUTTON:-left}" == "right" ]]; then
      open 'x-apple.systempreferences:com.apple.WiFi-Settings.extension'
    else
      update_popup
      sketchybar \
        --set weather popup.drawing=off \
        --set "$item" popup.drawing=toggle
    fi
    ;;
  mouse.exited.global)
    sketchybar --set "$item" popup.drawing=off
    ;;
  *)
    update_status
    ;;
esac
