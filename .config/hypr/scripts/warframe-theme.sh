#!/usr/bin/env bash
# Static "Warframe" theme -- Tenno energy cyan, Orokin gold, and void purple
# on deep space black. One-shot apply/revert, not a poller. Shared
# apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# Quotes are the Lotus's lines from the game's intro/tutorial sequence --
# "Tenno... wake up." is the very first line new players hear. That exact
# line has no findable soundboard clip, so the on-notification instead
# plays a random real in-game/community line from sounds/warframe/
# ("Tenno, on your six", "This is what you are", "We all lift together",
# a Necramech sound cue).
#
# Usage: warframe-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="warframe"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/warframe"
COLORS_JSON="$HOME/.config/ml4w/colors/warframe.json"
COLORS_CONF="$HOME/.config/hypr/colors/warframe.conf"
LOGO="$HOME/.config/fastfetch/assets/warframe-face.png"
SOUND="$HOME/.config/hypr/sounds/warframe"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "The Lotus" "Tenno... wake up." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "The Lotus" "The Old War is over. But another war, a war for our survival, is just beginning." 2>/dev/null || true
fi
