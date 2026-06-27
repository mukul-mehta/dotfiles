#!/usr/bin/env bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/settings.sh"

# A notched built-in display reports a non-zero top safe-area inset (~32pt); an
# external monitor reports 0. The media island is centred, and on the built-in
# the centre is exactly where the notch sits — so we push the island aside with
# an invisible centre spacer ONLY when a notch is present. On external monitors
# the spacer collapses to 0 and the island stays screen-centred.
inset="$(
  osascript -l JavaScript -e \
    'ObjC.import("AppKit"); ($.NSScreen.mainScreen.safeAreaInsets.top) + ""' \
    2>/dev/null
)"
inset="${inset%%.*}"
[[ "$inset" =~ ^[0-9]+$ ]] || inset=0

if (( inset > 0 )); then
  # Notched: shove the island left of the notch. The island moves left by
  # roughly half this width; tune MEDIA_NOTCH_SHIFT in settings.sh.
  sketchybar --set media.notch.pad width="${MEDIA_NOTCH_SHIFT:-560}"
else
  sketchybar --set media.notch.pad width=0
fi
