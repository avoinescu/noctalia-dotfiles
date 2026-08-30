#!/usr/bin/env bash
# Static "Doom" theme (id Software) -- hellish red/orange, UAC tech-cyan
# accent, on near-black. One-shot apply/revert, not a poller. Shared
# apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# The on-quote is "Rip and tear, until it is done." -- real Doom Eternal
# codex/narration line, verified via web search.
#
# The on-notification also plays a random clip from sounds/doom/ -- two
# real lines ("Rip and tear", "The only thing they fear is you"), sourced
# from myinstants.com.
#
# Usage: doom-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="doom"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/doom"
COLORS_JSON="$HOME/.config/ml4w/colors/doom.json"
COLORS_CONF="$HOME/.config/hypr/colors/doom.conf"
LOGO="$HOME/.config/fastfetch/assets/doom-face.png"
SOUND="$HOME/.config/hypr/sounds/doom"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Doom Slayer" "Rip and tear, until it is done." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Doom Slayer" "The demons retreat, for now." 2>/dev/null || true
fi
