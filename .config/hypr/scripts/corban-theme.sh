#!/usr/bin/env bash
# Static "Corban -- The Faithful and the Fallen" theme (John Gwynne's novel
# series) -- tempered steel grey, forge/hearth orange (his blacksmith
# origins), holy white-gold (Elyon's light), on cold iron near-black. One-
# shot apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is a real, verbatim line from Malice (book 1) -- verified via
# web search/Goodreads, not memory. It has no character attribution in the
# text itself (it's not specifically spoken by Corban), but it's a real
# quote from the series, not invented. Off-quote is flavor text.
#
# No sound: this is an unadapted book series with no game/film/audiobook
# clip realistically findable, so none was sourced rather than faking one.
# Wallpapers and the fastfetch logo are generic dark-ages/Norse-fantasy
# fallbacks (Wallhaven has nothing for this specific series) rather than
# book-specific art, since none exists publicly.
#
# Usage: corban-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="corban"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/corban"
COLORS_JSON="$HOME/.config/ml4w/colors/corban.json"
COLORS_CONF="$HOME/.config/hypr/colors/corban.conf"
LOGO="$HOME/.config/fastfetch/assets/corban-face.png"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Corban" "Both the brave man and the coward feel the same. The only difference between them is that the brave man faces his fear, does not run." 2>/dev/null || true
else
    deactivate_static_theme "$ID"
    notify-send -a "Corban" "The forge is cold. The hammer rests." 2>/dev/null || true
fi
