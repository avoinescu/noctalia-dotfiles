#!/usr/bin/env bash
# Static "Silent Hill" theme, focused on Pyramid Head -- rust/blood-red,
# fog-gray, tarnished gold accent, on a dim near-black. One-shot apply/
# revert, not a poller. Shared apply/deactivate logic (including cross-theme
# preemption) lives in custom-theme-lib.sh, used by every static custom
# theme.
#
# Pyramid Head has no dialogue -- he's silent and faceless by design (his
# helmet exists so the player can't read an expression) -- so unlike most
# themes here, both notifications are clearly-flavor text describing his
# presence rather than a fabricated line, and the sound is a real siren
# effect (the town's own warning siren, heard whenever the world shifts
# into its "Otherworld" state) rather than a spoken quote.
#
# The on-notification plays a random clip from sounds/silenthill/ -- two
# real Silent Hill siren sound effects, sourced from myinstants.com.
#
# Usage: silenthill-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="silenthill"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/silenthill"
COLORS_JSON="$HOME/.config/ml4w/colors/silenthill.json"
COLORS_CONF="$HOME/.config/hypr/colors/silenthill.conf"
LOGO="$HOME/.config/fastfetch/assets/silenthill-face.png"
SOUND="$HOME/.config/hypr/sounds/silenthill"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Silent Hill" "The world rusts. Pyramid Head drags his Great Knife across the floor, unhurried." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Silent Hill" "The fog lifts. For now." 2>/dev/null || true
fi
