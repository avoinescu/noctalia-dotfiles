#!/usr/bin/env bash
# Static "Fellowship of the Ring" theme (The Lord of the Rings) -- an
# ensemble theme for the whole company rather than one member: Shire/
# Lothlorien forest green, warm Rivendell/Ring gold, elvish silver-blue, on
# a deep forest night. One-shot apply/revert, not a poller. Shared
# apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# On-quote is the Council of Elrond's founding-of-the-Fellowship exchange
# ("You have my sword... And you have my bow... And my axe") -- Aragorn,
# Legolas, and Gimli pledging themselves to Frodo's quest, verified
# verbatim via web search rather than trusted from memory. Off-quote is
# Frodo's own line moments earlier at the same council, also verbatim.
#
# The on-notification also plays sounds/fellowship.mp3 -- "And my axe!",
# Gimli's half of that exchange, a real clip from myinstants.com (its
# "You Have My Sword" clip existed too but ran suspiciously short at 1.3s,
# so it was left out rather than risk using a mismatched sound).
#
# The fastfetch logo (fellowship-face.png) is the White Tree of Gondor --
# Middle-earth's own heraldic emblem, not specific to the Fellowship itself
# but the most recognizable Tolkien symbol available, sourced from
# hiclipart.com (pngegg.com was down/500 at build time).
#
# Usage: fellowship-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="fellowship"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/fellowship"
COLORS_JSON="$HOME/.config/ml4w/colors/fellowship.json"
COLORS_CONF="$HOME/.config/hypr/colors/fellowship.conf"
LOGO="$HOME/.config/fastfetch/assets/fellowship-face.png"
SOUND="$HOME/.config/hypr/sounds/fellowship.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Fellowship of the Ring" "You have my sword. And you have my bow. And my axe." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Fellowship of the Ring" "I will take the Ring, though I do not know the way." 2>/dev/null || true
fi
