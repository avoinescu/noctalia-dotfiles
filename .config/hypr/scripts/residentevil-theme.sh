#!/usr/bin/env bash
# Static "Resident Evil" theme -- S.T.A.R.S. blood-red, Spencer Mansion
# moss-green, tarnished gold accent, on near-black. One-shot apply/revert,
# not a poller. Shared apply/deactivate logic (including cross-theme
# preemption) lives in custom-theme-lib.sh, used by every static custom
# theme.
#
# The on-quote is Barry Burton's real line from the original 1996 Resident
# Evil, verified via web search -- one of gaming's most famous (and
# famously goofy) localizations: "That was too close. You were almost a
# Jill sandwich!"
#
# The on-notification also plays sounds/residentevil.mp3 -- the real
# in-game delivery of that line, sourced from myinstants.com.
#
# Usage: residentevil-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="residentevil"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/residentevil"
COLORS_JSON="$HOME/.config/ml4w/colors/residentevil.json"
COLORS_CONF="$HOME/.config/hypr/colors/residentevil.conf"
LOGO="$HOME/.config/fastfetch/assets/residentevil-face.png"
SOUND="$HOME/.config/hypr/sounds/residentevil.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "S.T.A.R.S." "That was too close. You were almost a Jill sandwich!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "S.T.A.R.S." "The mansion falls quiet again." 2>/dev/null || true
fi
