#!/usr/bin/env bash
# Static "Tainted Grail: The Fall of Avalon" theme -- rot-green, aged
# bronze/leather brown, a blood-red accent, on a bleak near-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# Both quotes are real, verified via web search -- a dark reimagining of
# Arthurian legend, where Arthur and his knights have failed and vanished.
#
# The on-notification also plays sounds/taintedgrail.mp3 -- "What secrets
# and mysteries will you find, in the land of everlasting autumn," a real
# narrator line from the official 0.6 launch trailer, trimmed from that
# video's audio using its auto-generated captions for exact wording and
# timing, then verified non-silent with ffmpeg volumedetect. The fastfetch
# logo is a generated chalice glyph -- pngegg had nothing at all under this
# game's name, just an unrelated generic fallback result.
#
# Usage: taintedgrail-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="taintedgrail"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/taintedgrail"
COLORS_JSON="$HOME/.config/ml4w/colors/taintedgrail.json"
COLORS_CONF="$HOME/.config/hypr/colors/taintedgrail.conf"
LOGO="$HOME/.config/fastfetch/assets/taintedgrail-face.png"
SOUND="$HOME/.config/hypr/sounds/taintedgrail.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Tainted Grail" "The King is dead. Long live the rot." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Tainted Grail" "Silence is the only honest thing left in Avalon." 2>/dev/null || true
fi
