#!/usr/bin/env bash
# Static "Sylvanas Windrunner" theme (World of Warcraft) -- former
# Ranger-General turned Banshee Queen and Warchief. Spectral banshee
# blue-green, Forsaken purple, and blood crimson on near-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The off-quote is Sylvanas's real closing line from her Shadowlands 9.2
# "Judgment" epilogue, accepting her penance in the Maw: "It shall be
# done. However long it takes." The on-quote, "ON YOUR KNEES! The Banshee
# Queen has plans for you!", is a real documented Sylvanas combat line.
# Both verified via web search, not trusted from memory.
#
# The on-notification also plays a random clip from sounds/sylvanas/ --
# real lines/laugh sourced from myinstants.com ("For the Horde!", her
# Hearthstone banshee-queen intro line, a "let none survive" combat line,
# and her signature evil laugh).
#
# Usage: sylvanas-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="sylvanas"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/sylvanas"
COLORS_JSON="$HOME/.config/ml4w/colors/sylvanas.json"
COLORS_CONF="$HOME/.config/hypr/colors/sylvanas.conf"
LOGO="$HOME/.config/fastfetch/assets/sylvanas-face.png"
SOUND="$HOME/.config/hypr/sounds/sylvanas"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Sylvanas Windrunner" "ON YOUR KNEES! The Banshee Queen has plans for you!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Sylvanas Windrunner" "It shall be done. However long it takes." 2>/dev/null || true
fi
