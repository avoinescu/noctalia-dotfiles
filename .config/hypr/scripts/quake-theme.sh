#!/usr/bin/env bash
# Static "Quake" theme (id Software) -- gladiatorial gold, arena blood-red,
# gunmetal accent, on near-black. One-shot apply/revert, not a poller.
# Shared apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# The on-notification also plays sounds/quake.mp3 -- the real "Quad
# Damage!" announcer line from Quake III Arena, one of gaming's most
# recognizable pickup callouts, sourced from myinstants.com.
#
# Usage: quake-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="quake"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/quake"
COLORS_JSON="$HOME/.config/ml4w/colors/quake.json"
COLORS_CONF="$HOME/.config/hypr/colors/quake.conf"
LOGO="$HOME/.config/fastfetch/assets/quake-face.png"
SOUND="$HOME/.config/hypr/sounds/quake.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Quake" "Quad Damage!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Quake" "The arena falls silent." 2>/dev/null || true
fi
