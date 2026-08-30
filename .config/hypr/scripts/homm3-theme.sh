#!/usr/bin/env bash
# Static "Heroes of Might and Magic III" theme -- parchment gold, deep
# heraldic blue, bronze accent, on near-black. One-shot apply/revert, not a
# poller. Shared apply/deactivate logic (including cross-theme preemption)
# lives in custom-theme-lib.sh, used by every static custom theme.
#
# HoMM3 is almost entirely unvoiced (a turn-based strategy game), so there's
# no real spoken quote to source -- both notifications are clearly-flavor
# text rather than a fabricated line.
#
# The on-notification plays sounds/homm3.mp3 -- a snippet of the real
# main-menu theme (Paul Romero / Rob King / Steve Baca), the game's most
# iconic and recognizable piece.
#
# Usage: homm3-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="homm3"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/homm3"
COLORS_JSON="$HOME/.config/ml4w/colors/homm3.json"
COLORS_CONF="$HOME/.config/hypr/colors/homm3.conf"
LOGO="$HOME/.config/fastfetch/assets/homm3-face.png"
SOUND="$HOME/.config/hypr/sounds/homm3.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Heroes of Might and Magic III" "A new hero answers the call to adventure." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Heroes of Might and Magic III" "The map fades, until next turn." 2>/dev/null || true
fi
