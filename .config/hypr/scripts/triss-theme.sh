#!/usr/bin/env bash
# Static "Triss Merigold" theme (The Witcher) -- fiery red hair, warm
# amber/copper fire-magic, cool sapphire sorceress-robe accent, on near-black.
# One-shot apply/revert, not a poller. Shared apply/deactivate logic
# (including cross-theme preemption) lives in custom-theme-lib.sh, used by
# every static custom theme.
#
# The off-quote is real, verified via web search: Triss's line when Geralt
# tries to persuade her to stay ("We had our chance, but... let it go."),
# fitting for the moment this theme itself lets go.
#
# The on-notification also plays sounds/triss.mp3 -- "Don't worry about
# me, Geralt. And please be careful," her real in-game line from The
# Witcher 3. Nothing findable on myinstants.com under her name, so this was
# trimmed from a full "all voice lines" compilation video using its
# auto-generated captions to find the exact wording and timing, then
# verified non-silent with ffmpeg volumedetect. The fastfetch logo is a
# real Witcher 3 Triss render sourced via pngegg (her name wasn't in the
# file's own metadata -- found by checking several mislabeled candidates by
# eye until one actually matched her model).
#
# Usage: triss-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="triss"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/triss"
COLORS_JSON="$HOME/.config/ml4w/colors/triss.json"
COLORS_CONF="$HOME/.config/hypr/colors/triss.conf"
LOGO="$HOME/.config/fastfetch/assets/triss-face.png"
SOUND="$HOME/.config/hypr/sounds/triss.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Triss Merigold" "Fire dances at her fingertips, ready to burn." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Triss Merigold" "We had our chance, but... let it go." 2>/dev/null || true
fi
