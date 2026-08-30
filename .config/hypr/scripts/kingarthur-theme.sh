#!/usr/bin/env bash
# Static "King Arthur: Legion IX" theme (NeocoreGames, 2024) -- imperial
# Roman red and gold (the Ninth Legion) with a decayed dark-fantasy green
# undertone (undead Avalon), on near-black. One-shot apply/revert, not a
# poller. Shared apply/deactivate logic (including cross-theme preemption)
# lives in custom-theme-lib.sh, used by every static custom theme.
#
# Both quotes are real, spoken lines from the game's official cinematic
# reveal trailer, transcribed from that video's auto-generated captions:
# the on-quote is the Night Legion's own declaration, the off-quote is
# Gaius Julius Mento introducing himself as the undead protagonist.
#
# The on-notification also plays sounds/kingarthur.mp3 -- the on-quote
# line itself, trimmed from that same trailer audio (timing taken from the
# captions, then verified non-silent with ffmpeg volumedetect). Nothing
# findable on myinstants for this quite recent, niche game.
#
# Usage: kingarthur-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="kingarthur"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/kingarthur"
COLORS_JSON="$HOME/.config/ml4w/colors/kingarthur.json"
COLORS_CONF="$HOME/.config/hypr/colors/kingarthur.conf"
LOGO="$HOME/.config/fastfetch/assets/kingarthur-face.png"
SOUND="$HOME/.config/hypr/sounds/kingarthur.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Legion IX" "We are the Night Legion, the ultimate army of Rome. We are more powerful than ever, and we are ready to return." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Gaius Julius Mento" "My name is Gaius Julius Mento. I died centuries ago." 2>/dev/null || true
fi
