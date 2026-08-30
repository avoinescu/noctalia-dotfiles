#!/usr/bin/env bash
# Static "Revan" theme (Star Wars: KOTOR/SWTOR) -- steel-mask silver, deep
# Sith crimson, electric Jedi blue, on cold near-black. One-shot apply/
# revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is Revan's real dark-side ending line to Malak at the
# Star Forge, verified via web search against a game-dialogue transcript
# (quotes.net): "This is the way of the Dark Side, Malak -- all things
# end in death." KOTOR's ending is player-choice-driven, so this is one of
# several possible lines, not the only one -- picked for fitting the
# theme's Sith-leaning half of Revan's ambiguous light/dark story.
#
# No clean spoken clip found (myinstants.com has nothing for Revan/KOTOR),
# so no sound rather than guessing a cutscene timestamp by ear. The
# off-quote is flavor text, not a real line.
#
# Usage: revan-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="revan"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/revan"
COLORS_JSON="$HOME/.config/ml4w/colors/revan.json"
COLORS_CONF="$HOME/.config/hypr/colors/revan.conf"
LOGO="$HOME/.config/fastfetch/assets/revan-face.png"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Revan" "This is the way of the Dark Side, Malak -- all things end in death." 2>/dev/null || true
else
    deactivate_static_theme "$ID"
    notify-send -a "Revan" "The mask returns to silence." 2>/dev/null || true
fi
