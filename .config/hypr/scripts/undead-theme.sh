#!/usr/bin/env bash
# Static "Undead" theme (World of Warcraft) -- Sylvanas Windrunner's
# Forsaken breaking from the Lich King's Scourge: royal purple, sickly
# plague-green, bone/ivory, and necrotic dried-blood red on near-black
# crypt-purple. One-shot apply/revert, not a poller. Shared apply/deactivate
# logic (including cross-theme preemption) lives in custom-theme-lib.sh,
# used by every static custom theme.
#
# The on-quote is Sylvanas Windrunner declaring the Forsaken's independence
# from the Scourge (Warcraft III); the off-quote is her Heroes of the Storm
# line responding to Arthas -- verified via web search, not memory.
#
# The on-notification also plays sounds/undead.mp3 -- Sylvanas's real
# in-game Banshee Wail sound effect, sourced from myinstants.com.
#
# Usage: undead-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="undead"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/undead"
COLORS_JSON="$HOME/.config/ml4w/colors/undead.json"
COLORS_CONF="$HOME/.config/hypr/colors/undead.conf"
LOGO="$HOME/.config/fastfetch/assets/undead-face.png"
SOUND="$HOME/.config/hypr/sounds/undead.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Sylvanas Windrunner" "Did you think we had forgotten? Did you think we had forgiven? Behold, now, the terrible vengeance of the Forsaken! Death to the Scourge!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Sylvanas Windrunner" "Give my regards to the endless dark." 2>/dev/null || true
fi
