#!/usr/bin/env bash
# Static "Blood Elves" theme (World of Warcraft faction) -- gold and crimson
# with an arcane/fel green undertone (their magic addiction), on deep
# maroon-black. One-shot apply/revert, not a poller. Shared apply/deactivate
# logic (including cross-theme preemption) lives in custom-theme-lib.sh,
# used by every static custom theme.
#
# Quotes are real Thalassian (Blood Elf) phrases used by NPCs in-game:
# "Anu belore dela'na" ("The sun guides us") and "Anar'alah" ("By the
# Light").
#
# The on-notification also plays a random clip from sounds/bloodelves/ --
# short snippets of the real Eversong Woods and Silvermoon City soundtracks
# (Burning Crusade), since there's no equivalent short spoken quote to use
# instead.
#
# Usage: bloodelves-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="bloodelves"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/bloodelves"
COLORS_JSON="$HOME/.config/ml4w/colors/bloodelves.json"
COLORS_CONF="$HOME/.config/hypr/colors/bloodelves.conf"
LOGO="$HOME/.config/fastfetch/assets/bloodelves-face.png"
SOUND="$HOME/.config/hypr/sounds/bloodelves"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Blood Elves" "Anu belore dela'na! (The sun guides us.)" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Blood Elves" "Anar'alah! (By the Light!)" 2>/dev/null || true
fi
