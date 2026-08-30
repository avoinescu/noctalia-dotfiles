#!/usr/bin/env bash
# Static "Yennefer of Vengerberg" theme (The Witcher) -- obsidian-and-pearl
# sorceress: deep violet magic, lilac/pearl accents, on near-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is real, verified via web search: Yennefer's own
# identity-affirming line, widely cited across game/show quote archives.
#
# The on-notification also plays sounds/yennefer.mp3 -- "Well, chop chop,
# and don't get killed, witcher," her in-game line to Geralt from The
# Witcher 3. Nothing findable on myinstants.com under her name turned out
# to actually be her, so this was trimmed from a full "all voice lines"
# compilation video using its auto-generated captions to find the exact
# wording and timing, then verified non-silent with ffmpeg volumedetect.
# The fastfetch logo is a generated obsidian-teardrop-and-pearl glyph
# (pngegg had nothing usable under her name -- every result was mislabeled
# Geralt/Triss art or unrelated).
#
# Usage: yennefer-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="yennefer"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/yennefer"
COLORS_JSON="$HOME/.config/ml4w/colors/yennefer.json"
COLORS_CONF="$HOME/.config/hypr/colors/yennefer.conf"
LOGO="$HOME/.config/fastfetch/assets/yennefer-face.png"
SOUND="$HOME/.config/hypr/sounds/yennefer.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Yennefer of Vengerberg" "I am not a tool. I am Yennefer of Vengerberg." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Yennefer of Vengerberg" "The portal closes behind her." 2>/dev/null || true
fi
