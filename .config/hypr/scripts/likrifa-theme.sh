#!/usr/bin/env bash
# Static "Lik-Rifa" theme (The Bloodsworn Saga, by John Gwynne) -- the
# dragon-god of legend, daughter of Snaka the snake-god, caged for
# centuries in Vergelmir among the roots of the world-tree Oskutreð before
# breaking free in book two, The Hunger of the Gods, to plot a new age of
# blood and conquest. Dragon-fire orange-red, dark dragon-scale red, ember
# gold, on near-black ash. One-shot apply/revert, not a poller. Shared
# apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# No verifiable direct quote from Lik-Rifa herself turned up in any
# quote-aggregator search (Goodreads' 33-quote page for this book has none
# attributed to her) -- both notification lines below are clearly-flagged
# flavor text, not real book dialogue, per this project's own
# don't-fake-quotes rule.
#
# The fastfetch logo (likrifa-face.png) is a sourced red/dark dragon
# transparent PNG (transparentpng.com) -- pngegg.com and hiclipart.com were
# both unreachable (502 / bot-blocked) when this was built.
#
# No sound: this is an unadapted book series with no game/film footage or
# voice work to source a clip from.
#
# Usage: likrifa-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="likrifa"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/likrifa"
COLORS_JSON="$HOME/.config/ml4w/colors/likrifa.json"
COLORS_CONF="$HOME/.config/hypr/colors/likrifa.conf"
LOGO="$HOME/.config/fastfetch/assets/likrifa-face.png"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Lik-Rifa" "Free of the roots at last -- the age of blood begins." 2>/dev/null || true
else
    deactivate_static_theme "$ID"
    notify-send -a "Lik-Rifa" "Back to the dark beneath the tree." 2>/dev/null || true
fi
