#!/usr/bin/env bash
# Static "Star Wars: Knights of the Old Republic" theme -- Jedi-console
# blue, credit-chip gold, Sith-purple accent, on near-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is HK-47's real signature line, verified via web search
# (Wookieepedia): "Statement: HK-47 is ready to serve, master." -- the
# assassin droid's most iconic bit of dialogue and the game's most quoted
# character. The off-line is flavor text written in his verified speech
# pattern ("Statement:"/"Observation:"/"Query:" prefixes, "meatbag" for
# organics), not a literal quote.
#
# The on-notification also plays sounds/kotor.mp3 -- a real HK-47 voice
# line, sourced from myinstants.com.
#
# Usage: kotor-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="kotor"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/kotor"
COLORS_JSON="$HOME/.config/ml4w/colors/kotor.json"
COLORS_CONF="$HOME/.config/hypr/colors/kotor.conf"
LOGO="$HOME/.config/fastfetch/assets/kotor-face.png"
SOUND="$HOME/.config/hypr/sounds/kotor.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "HK-47" "Statement: HK-47 is ready to serve, master." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "HK-47" "Observation: The meatbags have grown quiet." 2>/dev/null || true
fi
