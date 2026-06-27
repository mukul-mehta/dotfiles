#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
item="${NAME:-performance}"

source "$CONFIG_DIR/colors.sh"

# CPU: sum of per-process %cpu / logical cores. This is effectively instant,
# unlike `top -l 1` which blocks ~0.2s on every refresh. ps reports a short
# decaying average, which also keeps the reading from flickering frame to frame.
cores="$(sysctl -n hw.logicalcpu 2>/dev/null || printf 1)"
cpu="$(
  ps -A -o %cpu= 2>/dev/null |
    awk -v cores="${cores:-1}" '
      { total += $1 }
      END {
        if (cores < 1) cores = 1
        printf "%.0f", total / cores
      }
    '
)"

# memory_pressure reports the amount immediately available to the system.
free_memory="$(
  memory_pressure -Q 2>/dev/null |
    awk -F': ' '/System-wide memory free percentage/ {
      gsub(/%/, "", $2)
      print $2
      exit
    }'
)"

if [[ "$free_memory" =~ ^[0-9]+$ ]]; then
  ram=$((100 - free_memory))
else
  page_size="$(
    vm_stat 2>/dev/null |
      sed -nE 's/.*page size of ([0-9]+) bytes.*/\1/p'
  )"
  [[ "$page_size" =~ ^[0-9]+$ ]] || page_size=4096

  used_pages="$(
    vm_stat 2>/dev/null |
      awk -F: '
        /Pages active|Pages inactive|Pages wired down|Pages speculative|Pages occupied by compressor/ {
          gsub(/[^0-9]/, "", $2)
          total += $2
        }
        END { printf "%.0f", total }
      '
  )"

  total_bytes="$(sysctl -n hw.memsize 2>/dev/null || printf 0)"

  if [[ "$used_pages" =~ ^[0-9]+$ ]] &&
     [[ "$total_bytes" =~ ^[0-9]+$ ]] &&
     (( total_bytes > 0 )); then
    ram="$(
      awk -v pages="$used_pages" -v size="$page_size" -v total="$total_bytes" \
        'BEGIN { printf "%.0f", (pages * size / total) * 100 }'
    )"
  else
    ram=0
  fi
fi

[[ "$cpu" =~ ^[0-9]+$ ]] || cpu=0
[[ "$ram" =~ ^[0-9]+$ ]] || ram=0
(( cpu > 100 )) && cpu=100
(( ram > 100 )) && ram=100

metric_colour() {
  local value="$1"
  local normal="$2"

  if (( value >= 94 )); then
    printf '%s' "$RED"
  elif (( value >= 86 )); then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$normal"
  fi
}

cpu_colour="$(metric_colour "$cpu" "$CPU")"
ram_colour="$(metric_colour "$ram" "$RAM")"

sketchybar --set "$item" \
  "icon= ${cpu}%" \
  "icon.color=$cpu_colour" \
  "label=󰍛 ${ram}%" \
  "label.color=$ram_colour"
