#!/usr/bin/env bash
# Static "Darth Nihilus" theme (Star Wars: KOTOR II) -- void black, sickly
# gold/amber mask-glow, near-black maroon shroud, ash grey. One-shot apply/
# revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# Nihilus barely speaks in-game -- both quotes are real, verbatim
# dialogue, but from other characters describing him rather than from
# Nihilus himself (verified via web search, converging on the same wording
# across multiple independent sources): the on-quote is Visas Marr's line,
# the off-quote a contiguous excerpt of Kreia's.
#
# The on-notification also plays sounds/darthnihilus.mp3, a real growled
# in-game line sourced from myinstants.com, volume-boosted to match this
# collection's baseline loudness (-32dB source, mean -22dB after a +10dB
# boost, verified non-silent/non-clipping with ffmpeg volumedetect).
#
# Usage: darthnihilus-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="darthnihilus"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/darthnihilus"
COLORS_JSON="$HOME/.config/ml4w/colors/darthnihilus.json"
COLORS_CONF="$HOME/.config/hypr/colors/darthnihilus.conf"
LOGO="$HOME/.config/fastfetch/assets/darthnihilus-face.png"
SOUND="$HOME/.config/hypr/sounds/darthnihilus.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Darth Nihilus" "He is a wound in the Force, more presence than flesh, and in his wake life dies... sacrificing itself to his hunger." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Darth Nihilus" "The will behind his power is a primal thing. And it devours him as he devours others." 2>/dev/null || true
fi
