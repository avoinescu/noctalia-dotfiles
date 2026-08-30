#!/usr/bin/env bash
# Static "Protoss" theme (StarCraft) -- psionic gold, shield-blue, and
# khala-purple on a near-black void background. One-shot apply/revert, not
# a poller. Shared apply/deactivate logic (including cross-theme
# preemption) lives in custom-theme-lib.sh, used by every static custom
# theme.
#
# Quotes are real in-game unit lines, verified by web search: "My life for
# Aiur!" is the Zealot's StarCraft II training/select line; "En Taro Adun"
# ("In the name/honor of Adun") is a real Khalani ritual phrase used
# throughout the series as a battle-cry/salute.
#
# The on-notification also plays a random clip from sounds/protoss/ -- a
# pool of real in-game lines the user picked out themselves (Zealot,
# Probe, Carrier, Adun Toridas, unit-ready/upgrade-complete cues), sourced
# from myinstants.com.
#
# Usage: protoss-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="protoss"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/protoss"
COLORS_JSON="$HOME/.config/ml4w/colors/protoss.json"
COLORS_CONF="$HOME/.config/hypr/colors/protoss.conf"
LOGO="$HOME/.config/fastfetch/assets/protoss-face.png"
SOUND="$HOME/.config/hypr/sounds/protoss"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Protoss" "My life for Aiur!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Protoss" "En Taro Adun." 2>/dev/null || true
fi
