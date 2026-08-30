#!/usr/bin/env bash
# Static "Terran" theme (StarCraft) -- Dominion thruster-blue and gunmetal
# steel, warning-siren amber, on near-black gunmetal navy. Distinct from
# War Thunder's olive-drab/gunmetal/tracer-orange -- Terran leans sci-fi/
# industrial blue-cyan rather than WWII-modern olive. One-shot apply/revert,
# not a poller. Shared apply/deactivate logic (including cross-theme
# preemption) lives in custom-theme-lib.sh, used by every static custom
# theme.
#
# "Rock and Roll!" is a real Terran Marine combat bark from the games,
# confirmed via a matching soundboard clip. The on-notification also plays
# a random clip from sounds/terran/ -- that same "Rock and Roll!" line plus
# two "Good to go" barks (Marine, SCV).
#
# Usage: terran-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="terran"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/terran"
COLORS_JSON="$HOME/.config/ml4w/colors/terran.json"
COLORS_CONF="$HOME/.config/hypr/colors/terran.conf"
LOGO="$HOME/.config/fastfetch/assets/terran-face.png"
SOUND="$HOME/.config/hypr/sounds/terran"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Terran Dominion" "Rock and Roll!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Terran Dominion" "Good to go." 2>/dev/null || true
fi
