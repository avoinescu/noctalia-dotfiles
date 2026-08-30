#!/usr/bin/env bash
# Static "Sauron" theme (The Lord of the Rings) -- fiery Eye-of-Sauron
# orange, Mordor blood-black, molten gold ring-glow, on ash-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is the Ring-verse's real, exact closing couplet, verified
# via web search: "One Ring to rule them all, One Ring to find them, One
# Ring to bring them all and in the darkness bind them."
#
# The on-notification also plays sounds/sauron.mp3, a real recitation of
# the same verse, sourced from myinstants.com.
#
# Usage: sauron-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="sauron"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/sauron"
COLORS_JSON="$HOME/.config/ml4w/colors/sauron.json"
COLORS_CONF="$HOME/.config/hypr/colors/sauron.conf"
LOGO="$HOME/.config/fastfetch/assets/sauron-face.png"
SOUND="$HOME/.config/hypr/sounds/sauron.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Sauron" "One Ring to rule them all, One Ring to find them, One Ring to bring them all and in the darkness bind them." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Sauron" "The Eye closes. Mordor recedes into shadow." 2>/dev/null || true
fi
