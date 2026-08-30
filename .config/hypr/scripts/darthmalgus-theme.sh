#!/usr/bin/env bash
# Static "Darth Malgus" theme (Star Wars: The Old Republic) -- Sith Empire
# crimson, ash-black, void-purple accent, on near-black. One-shot apply/
# revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is trimmed from Malgus's real monologue in SWTOR's
# "Deceived" cinematic (the Sith invasion of the Jedi Temple), verified via
# web search: "Our time has come... we have returned." Full line: "Our
# time has come. For 300 years, we prepared. We grew stronger... but now...
# finally... we have returned."
#
# The on-notification also plays sounds/darthmalgus.mp3 -- "Our time has
# come," Malgus's real line from the same Deceived cinematic, trimmed from
# the official trailer audio using its own manually-authored closed
# captions (labeled "Darth Malgus:") for exact timing, then verified
# non-silent with ffmpeg volumedetect. SWTOR is too niche for
# myinstants.com, which had nothing findable. The fastfetch logo is a
# generated Sith-emblem glyph for the same reason (pngegg had nothing for
# "Darth Malgus" beyond unrelated generic clipart).
#
# Usage: darthmalgus-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="darthmalgus"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/darthmalgus"
COLORS_JSON="$HOME/.config/ml4w/colors/darthmalgus.json"
COLORS_CONF="$HOME/.config/hypr/colors/darthmalgus.conf"
LOGO="$HOME/.config/fastfetch/assets/darthmalgus-face.png"
SOUND="$HOME/.config/hypr/sounds/darthmalgus.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Darth Malgus" "Our time has come... we have returned. You were deceived. And now, your Republic... shall fall." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Darth Malgus" "The Temple burns behind him." 2>/dev/null || true
fi
