#!/usr/bin/env bash
# Static "Slaanesh" theme (Warhammer 40,000 / Warhammer Fantasy) -- the
# Chaos God of Excess, Pleasure, and Perfection. Hot-pink/magenta and
# decadent purple with a pearl/opulent gold accent, on deep purple-black.
# One-shot apply/revert, not a poller. Shared apply/deactivate logic
# (including cross-theme preemption) lives in custom-theme-lib.sh, used by
# every static custom theme.
#
# The on-notification also plays sounds/slaanesh.mp3 -- "We are the
# feaster of pain, the herald of Slaanesh, and your time has come," a real
# Exalted Keeper of Secrets pre-battle speech from Total War: Warhammer III
# (a Slaanesh greater daemon, explicitly titled/labeled as such in its
# source video). myinstants.com has plenty of generic Total War: Warhammer
# Chaos lines, but none confidently attributable to Slaanesh specifically,
# so this was trimmed from the YouTube video using its auto-generated
# captions to find the exact wording and timing, then verified non-silent
# with ffmpeg volumedetect.
#
# Usage: slaanesh-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="slaanesh"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/slaanesh"
COLORS_JSON="$HOME/.config/ml4w/colors/slaanesh.json"
COLORS_CONF="$HOME/.config/hypr/colors/slaanesh.conf"
LOGO="$HOME/.config/fastfetch/assets/slaanesh-face.png"
SOUND="$HOME/.config/hypr/sounds/slaanesh.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Slaanesh" "Come to me... Brothers and sisters, rejoice! Pleasure beyond imagining awaits you! Desire... Pride... Pain... Excess in all things. Partake of perfection!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Slaanesh" "For I am Slaanesh, most jealous of gods, most demanding of lovers, and My Thirst for you shall never be sated." 2>/dev/null || true
fi
