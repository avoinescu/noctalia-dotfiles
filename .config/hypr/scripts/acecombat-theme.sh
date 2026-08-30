#!/usr/bin/env bash
# Static "Ace Combat 7: Skies Unknown" theme -- open-sky blue, cloud white,
# and HUD-orange missile-lock accent on a deep aviation navy-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every static
# custom theme.
#
# Quotes verified via Wikiquote's Ace Combat page, not memory: the on-quote
# is Mihaly Shilage's line before his final battle; the off-quote is Avril
# Mead's closing line from the ending.
#
# The on-notification also plays sounds/acecombat.mp3 -- the real in-game
# AWACS radio alert tone from the series (Ace Combat 6), sourced from
# myinstants.com. No character voice-line clips turned up searchable, so
# this uses a real sound effect instead, same approach as War Thunder.
#
# Usage: acecombat-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="acecombat"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/acecombat"
COLORS_JSON="$HOME/.config/ml4w/colors/acecombat.json"
COLORS_CONF="$HOME/.config/hypr/colors/acecombat.conf"
LOGO="$HOME/.config/fastfetch/assets/acecombat-face.png"
SOUND="$HOME/.config/hypr/sounds/acecombat.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Mihaly A. Shilage" "This aircraft is my body... I must put my soul into it." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Avril Mead" "To Skies Unknown... The path to mankind's vast future remains standing, Granddad." 2>/dev/null || true
fi
