#!/usr/bin/env bash
# Static "Geralt of Rivia" theme (The Witcher) -- medallion silver, toxic
# potion green, sign-magic amber, on dark leather-brown near-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is Geralt's real "lesser evil" monologue (from Sapkowski's
# The Last Wish, echoed verbatim in Witcher 3) -- verified via web search,
# not memory.
#
# The on-notification also plays sounds/geralt.mp3 -- the real in-game
# delivery of that same line, sourced from myinstants.com.
#
# Usage: geralt-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="geralt"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/geralt"
COLORS_JSON="$HOME/.config/ml4w/colors/geralt.json"
COLORS_CONF="$HOME/.config/hypr/colors/geralt.conf"
LOGO="$HOME/.config/fastfetch/assets/geralt-face.png"
SOUND="$HOME/.config/hypr/sounds/geralt.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Geralt of Rivia" "Evil is evil... If I have to choose between one evil and another, then I prefer not to choose at all." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Geralt of Rivia" "Another day, another monster." 2>/dev/null || true
fi
