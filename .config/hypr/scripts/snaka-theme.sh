#!/usr/bin/env bash
# Static "Snaka" theme -- the Serpent God, Father of All in John Gwynne's
# Bloodsworn Saga (Snaka is the creator of the other animal-gods, including
# Ulfrir the Wolf and Lik-Rifa the Dragon; killed in the Guðfalla, his skull
# became the port-city of Snakavik). Venomous serpent green/black.
#
# No verbatim Snaka quote turned up in a web search of quote-aggregator
# sites for this book series -- the on/off lines below are flavor text,
# not real dialogue.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="snaka"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/snaka"
COLORS_JSON="$HOME/.config/ml4w/colors/snaka.json"
COLORS_CONF="$HOME/.config/hypr/colors/snaka.conf"
LOGO="$HOME/.config/fastfetch/assets/snaka-face.png"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Snaka" "Father of all. Every god that ever crawled or flew or walked was born of my coils." 2>/dev/null || true
else
    deactivate_static_theme "$ID"
    notify-send -a "Snaka" "The Guðfalla comes for every god in the end." 2>/dev/null || true
fi
