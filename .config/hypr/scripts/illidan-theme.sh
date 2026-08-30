#!/usr/bin/env bash
# Static "Illidan Stormrage" theme (World of Warcraft) -- fel green, demon
# purple, and blindfold-orange on near-black. One-shot apply/revert, not a
# poller. Shared apply/deactivate logic (including cross-theme preemption)
# lives in custom-theme-lib.sh, used by every static custom theme.
#
# The on-notification also plays sounds/illidan.mp3 -- the real in-game
# "You are not prepared!" voice line, sourced from myinstants.com.
#
# Usage: illidan-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="illidan"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/illidan"
COLORS_JSON="$HOME/.config/ml4w/colors/illidan.json"
COLORS_CONF="$HOME/.config/hypr/colors/illidan.conf"
LOGO="$HOME/.config/fastfetch/assets/illidan-face.png"
SOUND="$HOME/.config/hypr/sounds/illidan.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Illidan Stormrage" "You are not prepared!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Illidan Stormrage" "The Betrayer stands down." 2>/dev/null || true
fi
