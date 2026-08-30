#!/usr/bin/env bash
# Static "Baldur's Gate" theme (focused on Baldur's Gate 3, by far the most
# iconic/quotable entry in the series) -- D&D parchment gold, arcane purple,
# torch-fire orange, on a rich dark-fantasy near-black. One-shot apply/
# revert, not a poller. Shared apply/deactivate logic (including cross-theme
# preemption) lives in custom-theme-lib.sh, used by every static custom
# theme.
#
# The on-quote is Astarion's real line about the sun, verified via web
# search -- one of BG3's most heavily-memed moments.
#
# The on-notification also plays a random clip from sounds/baldursgate/ --
# real Astarion lines: "A little treat", his "darling" line (both from
# myinstants.com), and "I was right there!" (trimmed from a YouTube clip
# of that exact scene, using its auto-generated captions to confirm wording
# and timing, boosted a bit in volume since the source recording ran quiet).
#
# Usage: baldursgate-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="baldursgate"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/baldursgate"
COLORS_JSON="$HOME/.config/ml4w/colors/baldursgate.json"
COLORS_CONF="$HOME/.config/hypr/colors/baldursgate.conf"
LOGO="$HOME/.config/fastfetch/assets/baldursgate-face.png"
SOUND="$HOME/.config/hypr/sounds/baldursgate"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Baldur's Gate 3" "Well, apparently there's a limit. Somewhere between a nice summer's day and the FULL CONCENTRATED POWER OF THE SUN!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Baldur's Gate 3" "The camp fire dims for the night." 2>/dev/null || true
fi
