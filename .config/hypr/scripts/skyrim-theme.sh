#!/usr/bin/env bash
# Static "Skyrim" theme (The Elder Scrolls V) -- cold Nordic ice-blue,
# stone-gray, dragonfire-orange accent, on near-black. One-shot apply/
# revert, not a poller. Shared apply/deactivate logic (including cross-theme
# preemption) lives in custom-theme-lib.sh, used by every static custom
# theme.
#
# The on-notification plays sounds/skyrim.mp3 -- a snippet of the real
# "Dragonborn" theme song (Jeremy Soule), trimmed to the vocal chant
# section, since that's what was actually asked for here (the music, not a
# spoken quote). Real Dragon-tongue lyrics open with "Dovahkiin, Dovahkiin,
# naal ok zin los vahriin..." (verified via web search), used as the
# on-notification text.
#
# Usage: skyrim-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="skyrim"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/skyrim"
COLORS_JSON="$HOME/.config/ml4w/colors/skyrim.json"
COLORS_CONF="$HOME/.config/hypr/colors/skyrim.conf"
LOGO="$HOME/.config/fastfetch/assets/skyrim-face.png"
SOUND="$HOME/.config/hypr/sounds/skyrim.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Skyrim" "Dovahkiin, Dovahkiin, naal ok zin los vahriin..." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Skyrim" "The wind settles over the Throat of the World." 2>/dev/null || true
fi
