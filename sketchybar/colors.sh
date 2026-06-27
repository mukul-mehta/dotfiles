#!/usr/bin/env bash

# Dark graphite surfaces with controlled colour.
# ARGB format: 0xAARRGGBB

export TRANSPARENT=0x00000000

export DIVIDER=0x454b5567

# Subtle hairline edge on each island.
export ISLAND_BORDER=0xb68ba3ff

# Per-island background tints.
export ISLAND_BG_SPACES=0xf21a2448   # indigo     (workspaces)
export ISLAND_BG_MEDIA=0xf210433c    # teal       (now playing)
export ISLAND_BG_CONN=0xf214315c     # cobalt     (wifi / volume / battery)
export ISLAND_BG_CLOCK=0xf232254f    # violet     (clock)
export ISLAND_BG_WEATHER=0xf23f3118  # bronze     (weather)
export ISLAND_BG_STATUS=0xf1262f24   # dark slate (focus / tailscale / maccy)

export TEXT=0xfff0f2f7
export SUBTEXT=0xffa1aabc
export MUTED=0xff667084

# Four workspace accents, repeated once.
export BLUE=0xff8eb8ff
export LAVENDER=0xffc6a9ff
export TEAL=0xff72d8c8
export PEACH=0xffffb184

export BLUE_BG=0xf2314165
export LAVENDER_BG=0xf2473864
export TEAL_BG=0xf0205550
export PEACH_BG=0xf0583b27

# Status colours.
export CPU=0xff8eb8ff
export RAM=0xffc6a9ff
export WIFI=0xff72d8c8
export BATTERY=0xffa7d88c
export CLOCK=0xffcad3e8
export WEATHER=0xffffc76f
export VOLUME=0xff8eb8ff
export FOCUS=0xffc6a9ff
export TAILSCALE=0xff72d8c8
export MACCY=0xff8eb8ff

export PERFORMANCE_BG=0xf24a2037
export MEDIA_FALLBACK=0xff24525f

export GREEN=0xff91bd85
export YELLOW=0xffd3aa68
export RED=0xffdb7884
