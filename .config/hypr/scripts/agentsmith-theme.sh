#!/usr/bin/env bash
# Static "Agent Smith" (The Matrix) theme -- classic digital-rain green,
# black suit, near-black on/off, one-shot apply/revert like every other
# static custom theme (see custom-theme-lib.sh).
#
# The on-quote is Agent Smith's real, verbatim monologue from the film
# ("Human beings are a disease..."), cross-verified against IMDb/quotes.net.
# The on-notification also plays sounds/agentsmith/ -- three real clips
# (the disease monologue, "Mr. Anderson...", and "I'm going to enjoy
# watching you die, Mr. Anderson"), sourced from myinstants.com.
#
# Usage: agentsmith-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="agentsmith"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/agentsmith"
COLORS_JSON="$HOME/.config/ml4w/colors/agentsmith.json"
COLORS_CONF="$HOME/.config/hypr/colors/agentsmith.conf"
LOGO="$HOME/.config/fastfetch/assets/agentsmith-face.png"
SOUND="$HOME/.config/hypr/sounds/agentsmith"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Agent Smith" "Human beings are a disease, a cancer of this planet." "You're a plague, and we are the cure." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Agent Smith" "Never send a human to do a machine's job." 2>/dev/null || true
fi
