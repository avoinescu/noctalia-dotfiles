#!/usr/bin/env bash
# Static "Dante" theme (Devil May Cry) -- his signature red coat, Rebellion
# steel-blue, hellfire-orange accent, on a stylish near-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is "Jackpot!" -- Dante and Vergil's childhood catchphrase,
# verified via web search (Devil May Cry Wiki), most famously shouted at
# the end of Dante's final fight with Mundus in DMC3.
#
# The on-notification also plays a random clip from sounds/dante/ -- two
# real "Jackpot!" takes (mainline DMC3 and Marvel vs. Capcom 3), sourced
# from myinstants.com.
#
# Usage: dante-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="dante"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/dante"
COLORS_JSON="$HOME/.config/ml4w/colors/dante.json"
COLORS_CONF="$HOME/.config/hypr/colors/dante.conf"
LOGO="$HOME/.config/fastfetch/assets/dante-face.png"
SOUND="$HOME/.config/hypr/sounds/dante"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Dante" "Jackpot!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Dante" "Time to close up shop." 2>/dev/null || true
fi
