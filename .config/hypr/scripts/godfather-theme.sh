#!/usr/bin/env bash
# Static "The Godfather" theme -- classic mafia noir: black, gold, and deep
# blood-red, on near-black. One-shot apply/revert, not a poller. Shared
# apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# Both quotes are Don Vito Corleone's real lines, verified via web search --
# the exact film wording is "I'm gonna make him an offer he can't refuse."
# and "...a man who doesn't spend time with his family can never be a real
# man."
#
# The on-notification also plays sounds/godfather.mp3 -- the real line from
# the 1972 film, sourced from myinstants.com.
#
# Usage: godfather-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="godfather"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/godfather"
COLORS_JSON="$HOME/.config/ml4w/colors/godfather.json"
COLORS_CONF="$HOME/.config/hypr/colors/godfather.conf"
LOGO="$HOME/.config/fastfetch/assets/godfather-face.png"
SOUND="$HOME/.config/hypr/sounds/godfather.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Don Corleone" "I'm gonna make him an offer he can't refuse." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Don Corleone" "A man who doesn't spend time with his family can never be a real man." 2>/dev/null || true
fi
