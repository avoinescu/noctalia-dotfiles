#!/usr/bin/env bash
# Static "Xal'atath, Voice of the Void" theme (World of Warcraft -- main
# villain of The War Within) -- void purple and eerie teal void-whisper
# energy, with an ancient gold dagger-hilt accent and a blood-red edge, on
# obsidian near-black. One-shot apply/revert, not a poller. Shared
# apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# Quotes are verbatim, sourced from Xal'atath's quote list on Warcraft Wiki
# (warcraft.wiki.gg/wiki/Xal'atath) -- a Mythic+ affix line for the on-quote,
# an on-click farewell line for the off-quote.
#
# The on-notification also plays sounds/xalatath.mp3 -- "The walls between
# realms are thin here, so easy to tear open," a real in-game voice-over
# line. myinstants.com has nothing for her (too recent/niche), so this was
# trimmed from a full YouTube voice-over compilation; the exact wording and
# timing came from that video's auto-generated captions (read as text, not
# guessed by ear) before cutting the clip, then verified non-silent with
# ffmpeg volumedetect.
#
# The fastfetch logo (xalatath-face.png) is an original generated glyph
# (a stylized void eye, drawn with ImageMagick in this theme's own colors),
# not a sourced image -- pngegg has nothing for her either (too recent) and
# every adjacent search (void elf, old god eye, N'Zoth) returned mismatched
# results (Warhammer/StarCraft/generic clipart).
#
# Usage: xalatath-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="xalatath"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/xalatath"
COLORS_JSON="$HOME/.config/ml4w/colors/xalatath.json"
COLORS_CONF="$HOME/.config/hypr/colors/xalatath.conf"
LOGO="$HOME/.config/fastfetch/assets/xalatath-face.png"
SOUND="$HOME/.config/hypr/sounds/xalatath.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Xal'atath" "Inevitably... the Void consumes everything." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Xal'atath" "We will survive." 2>/dev/null || true
fi
