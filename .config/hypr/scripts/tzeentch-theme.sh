#!/usr/bin/env bash
# Static "Tzeentch" theme (Warhammer 40,000 / Warhammer Fantasy) -- Pink
# Horror magenta, Blue Horror cyan, and gold sorcery-accent on deep
# void-blue-black. One-shot apply/revert, not a poller. Shared
# apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# The on-quote is a real, verified line from The Book of Tzeentch (Warhammer
# 40k in-universe text), confirmed via web search across Lexicanum and
# Fandom wikis: "I am Tzeentch and you are the puppet that dances to my
# tune." "Everything according to plan" and "the flame that burns twice as
# bright" are widely repeated online but turned out to be fan-meme
# constructions, not canonical lines -- deliberately not used here. The
# off-line is flavor text (clearly not a real quote); no verifiable
# canonical line fit the moment.
#
# The on-notification also plays sounds/tzeentch.mp3 -- "I have seen your
# fate, perhaps we can change it for the better," a real Tzeentch-faction
# sorcerer diplomacy line from Total War: Warhammer III (a video explicitly
# titled/labeled as Tzeentch sorcerer voicelines, so confidently
# attributable). myinstants.com had nothing confidently attributable to
# Tzeentch specifically, so this was trimmed from the YouTube video using
# its auto-generated captions to find the exact wording and timing, then
# verified non-silent with ffmpeg volumedetect. Logo note: no dedicated
# Tzeentch rune/symbol PNG was findable on pngegg either -- used a
# purple/blue cosmic rendition of the generic Chaos Undivided star instead
# (close enough thematically, not claimed as his specific heraldry).
#
# Usage: tzeentch-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="tzeentch"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/tzeentch"
COLORS_JSON="$HOME/.config/ml4w/colors/tzeentch.json"
COLORS_CONF="$HOME/.config/hypr/colors/tzeentch.conf"
LOGO="$HOME/.config/fastfetch/assets/tzeentch-face.png"
SOUND="$HOME/.config/hypr/sounds/tzeentch.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Tzeentch" "I am Tzeentch, and you are the puppet that dances to my tune." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Tzeentch" "The scheme continues elsewhere." 2>/dev/null || true
fi
