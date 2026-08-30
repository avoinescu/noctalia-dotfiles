#!/usr/bin/env bash
# Static "Joker" (Batman villain) theme -- purple/toxic-green/blood-red on
# near-black, deliberately NOT scheduled/evolving like the Hellsing theme
# (doesn't make sense for this one). One-shot apply/revert, not a poller.
# Shared apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# The on-notification also plays sounds/joker.mp3 -- the real Heath Ledger
# "Why so serious?" line, sourced from myinstants.com.
#
# Usage: joker-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="joker"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/joker"
COLORS_JSON="$HOME/.config/ml4w/colors/joker.json"
COLORS_CONF="$HOME/.config/hypr/colors/joker.conf"
LOGO="$HOME/.config/fastfetch/assets/joker-face.png"
SOUND="$HOME/.config/hypr/sounds/joker.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Joker" "Why So Serious?" "Introduce a little anarchy." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Joker" "You wouldn't want to miss the ending." 2>/dev/null || true
fi
