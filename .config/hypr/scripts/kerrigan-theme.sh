#!/usr/bin/env bash
# Static "Sarah Kerrigan / Queen of Blades" theme (StarCraft) -- infested
# chitin magenta, psionic gold-orange, blade-crimson, on near-black void.
# One-shot apply/revert, not a poller. Shared apply/deactivate logic
# (including cross-theme preemption) lives in custom-theme-lib.sh, used by
# every static custom theme. Kept visually distinct from the separate
# "zerg" faction theme (creep purple/acid green/bioluminescent orange) --
# this one leans magenta/violet/psionic-gold for Kerrigan specifically.
#
# The off-quote is her real Legacy of the Void ending line, accepting an
# uncertain redemption -- fitting for the moment this theme steps back.
#
# The on-notification also plays sounds/kerrigan.mp3 -- her real "Kerrigan
# reporting" select line (Heroes of the Storm), sourced from myinstants.com.
# Only one clip was findable, so it's a single file rather than a random
# pool like some other themes.
#
# Usage: kerrigan-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="kerrigan"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/kerrigan"
COLORS_JSON="$HOME/.config/ml4w/colors/kerrigan.json"
COLORS_CONF="$HOME/.config/hypr/colors/kerrigan.conf"
LOGO="$HOME/.config/fastfetch/assets/kerrigan-face.png"
SOUND="$HOME/.config/hypr/sounds/kerrigan.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Queen of Blades" "I am the Swarm... Now, at last, on this world, vengeance shall be mine. For I am the Queen of Blades." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Sarah Kerrigan" "I don't know if I deserve redemption for what I've done... but our universe does." 2>/dev/null || true
fi
