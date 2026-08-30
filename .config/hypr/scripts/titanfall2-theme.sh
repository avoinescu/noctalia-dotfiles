#!/usr/bin/env bash
# Static "Titanfall 2" theme -- Vanguard-class thruster blue, Titan-armor
# gold, plasma-orange accent, on gunmetal near-black. One-shot apply/
# revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is BT-7274's real, verified-via-web-search line -- one of
# the most quoted moments in the game: "Protocol 3: Protect the Pilot."
#
# The on-notification also plays a random clip from sounds/titanfall2/ --
# three real in-game lines ("Not so fast", "I'd tell you", "Destroyed"),
# sourced from myinstants.com.
#
# Usage: titanfall2-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="titanfall2"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/titanfall2"
COLORS_JSON="$HOME/.config/ml4w/colors/titanfall2.json"
COLORS_CONF="$HOME/.config/hypr/colors/titanfall2.conf"
LOGO="$HOME/.config/fastfetch/assets/titanfall2-face.png"
SOUND="$HOME/.config/hypr/sounds/titanfall2"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "BT-7274" "Protocol 3: Protect the Pilot." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "BT-7274" "Link to Pilot severed." 2>/dev/null || true
fi
