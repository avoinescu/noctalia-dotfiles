#!/usr/bin/env bash
# Static "Meetra Surik -- Jedi Exile" theme (KOTOR II) -- grey Jedi blue,
# weathered robe tan, Force-wound pale grey, on cold near-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# No sound: the Exile is a heavily player-scripted/silent-protagonist
# character with no single fixed voice line, and no exact quote could be
# independently verified across two sources (fan quote compilations only
# had one AI-summarized hit) -- so both notifications below are clearly
# flavor text, not presented as real dialogue, per this repo's own rule.
#
# Usage: meetrasurik-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="meetrasurik"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/meetrasurik"
COLORS_JSON="$HOME/.config/ml4w/colors/meetrasurik.json"
COLORS_CONF="$HOME/.config/hypr/colors/meetrasurik.conf"
LOGO="$HOME/.config/fastfetch/assets/meetrasurik-face.png"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Jedi Exile" "The Force remembers, even when the Jedi forget." 2>/dev/null || true
else
    deactivate_static_theme "$ID"
    notify-send -a "Jedi Exile" "The wound closes. For now." 2>/dev/null || true
fi
