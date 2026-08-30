#!/usr/bin/env bash
# Static "Zerg" theme (StarCraft) -- creep purple, sickly acid green, and
# bioluminescent orange-red glow on organic near-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is the Overmind's real line from the original StarCraft
# campaign: "The Swarm is eternal. The Swarm is the future." The off-line
# is flavor text (clearly not a real quote) -- no verifiable canonical line
# fit the moment of the swarm receding.
#
# The on-notification also plays sounds/zerg.mp3 -- a real zergling sound
# effect, sourced from myinstants.com. The Zerg have no shared spoken
# language, so a creature sound fits better than a forced dialogue quote.
#
# Usage: zerg-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="zerg"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/zerg"
COLORS_JSON="$HOME/.config/ml4w/colors/zerg.json"
COLORS_CONF="$HOME/.config/hypr/colors/zerg.conf"
LOGO="$HOME/.config/fastfetch/assets/zerg-face.png"
SOUND="$HOME/.config/hypr/sounds/zerg.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "The Overmind" "The Swarm is eternal. The Swarm is the future." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "The Swarm" "The swarm recedes... for now." 2>/dev/null || true
fi
