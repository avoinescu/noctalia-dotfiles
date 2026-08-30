#!/usr/bin/env bash
# Static "Arthas / The Lich King" theme (World of Warcraft) -- Frostmourne
# ice-blue, plague-scourge green, and blood crimson on near-black navy.
# One-shot apply/revert, not a poller. Shared apply/deactivate logic
# (including cross-theme preemption) lives in custom-theme-lib.sh, used by
# every static custom theme.
#
# The off-quote is Terenas Menethil II's line to his son as Arthas dies atop
# Icecrown Citadel at the end of Wrath of the Lich King: "At long last...
# no king rules forever, my son." -- fitting for the moment this theme
# itself "dies" back to whatever was running before it.
#
# The on-notification also plays a random clip from sounds/arthas/ -- the
# real in-game Lich King "Frostmourne hungers" voice line (WoW file path
# Sound/Creature/Lichking/Ic_lich King_fmattack01.wav) plus a second real
# Lich King greeting line, both sourced from myinstants.com.
#
# Usage: arthas-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="arthas"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/arthas"
COLORS_JSON="$HOME/.config/ml4w/colors/arthas.json"
COLORS_CONF="$HOME/.config/hypr/colors/arthas.conf"
LOGO="$HOME/.config/fastfetch/assets/arthas-face.png"
SOUND="$HOME/.config/hypr/sounds/arthas"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "The Lich King" "Frostmourne hungers." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Terenas Menethil" "At long last... no king rules forever, my son." 2>/dev/null || true
fi
