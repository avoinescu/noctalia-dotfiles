#!/usr/bin/env bash
# Static "Darth Vader" theme (Star Wars) -- Imperial black, lightsaber
# blood-red, life-support gray, on near-black. One-shot apply/revert, not
# a poller. Shared apply/deactivate logic (including cross-theme
# preemption) lives in custom-theme-lib.sh, used by every static custom
# theme.
#
# The on-quote is Vader's real, exact line from The Empire Strikes Back,
# verified via web search -- NOT the commonly-misremembered "Luke, I am
# your father" (a famous Mandela-effect misquote), but the actual line:
# "No. I am your father."
#
# The on-notification also plays sounds/darthvader.mp3 -- the real in-game/
# film delivery of that line, sourced from myinstants.com (chosen over an
# alternate clip literally filenamed with the misquote, to avoid the same
# trap).
#
# Usage: darthvader-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="darthvader"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/darthvader"
COLORS_JSON="$HOME/.config/ml4w/colors/darthvader.json"
COLORS_CONF="$HOME/.config/hypr/colors/darthvader.conf"
LOGO="$HOME/.config/fastfetch/assets/darthvader-face.png"
SOUND="$HOME/.config/hypr/sounds/darthvader.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Darth Vader" "No. I am your father." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Darth Vader" "The respirator falls silent." 2>/dev/null || true
fi
