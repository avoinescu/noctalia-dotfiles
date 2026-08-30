#!/usr/bin/env bash
# Static "War Thunder" theme -- olive drab, gunmetal gray, and tracer
# orange on an asphalt near-black. One-shot apply/revert, not a poller.
# Shared apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# War Thunder has no characters/narrative to quote, so the on-notification
# uses a real in-game loading-screen hint line instead of a character quote.
# That hint is UI text, not spoken dialogue, so the on-notification instead
# plays a random real in-game voice-comms clip from sounds/warthunder/ --
# "Attack the D point" (EN), "Cible detruite" / target destroyed (FR), or
# the "Angry Russian Tank Instructor" soundboard clip.
#
# Usage: warthunder-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="warthunder"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/warthunder"
COLORS_JSON="$HOME/.config/ml4w/colors/warthunder.json"
COLORS_CONF="$HOME/.config/hypr/colors/warthunder.conf"
LOGO="$HOME/.config/fastfetch/assets/warthunder-face.png"
SOUND="$HOME/.config/hypr/sounds/warthunder"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "War Thunder" "A good pilot can fly anything that flies -- and, with some difficulty, even things never meant to fly." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "War Thunder" "Prepare for the next sortie." 2>/dev/null || true
fi
