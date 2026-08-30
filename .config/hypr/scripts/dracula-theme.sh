#!/usr/bin/env bash
# Static "Dracula" theme (Castlevania's take, since this whole setup is
# game-themed) -- gothic blood-red, castle stone-gray, pale moonlight-blue,
# on near-black. One-shot apply/revert, not a poller. Shared apply/
# deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# The on-quote is Dracula's real, exact line from Castlevania: Symphony of
# the Night's opening battle -- one of gaming's most heavily-memed lines,
# verified via web search: "What is a man?! A miserable little pile of
# secrets! But enough talk, HAVE AT YOU!!!"
#
# The on-notification also plays sounds/dracula.mp3 -- the real in-game
# delivery of that line, sourced from myinstants.com.
#
# Usage: dracula-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="dracula"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/dracula"
COLORS_JSON="$HOME/.config/ml4w/colors/dracula.json"
COLORS_CONF="$HOME/.config/hypr/colors/dracula.conf"
LOGO="$HOME/.config/fastfetch/assets/dracula-face.png"
SOUND="$HOME/.config/hypr/sounds/dracula.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Dracula" "What is a man?! A miserable little pile of secrets! But enough talk, HAVE AT YOU!!!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Dracula" "The castle sinks back into the night." 2>/dev/null || true
fi
