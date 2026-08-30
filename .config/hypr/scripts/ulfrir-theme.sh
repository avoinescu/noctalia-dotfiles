#!/usr/bin/env bash
# Static "Ulfrir" (The Bloodsworn Saga, by John Gwynne) theme -- the wolf-god,
# bound and killed at the Guðfalla, later revived by Elvar to oppose Lik-Rifa.
# Icy wolf grey-blue, wintery, fierce. Deliberately NOT scheduled/evolving.
# Shared apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# On-quote is real, verbatim, from The Shadow of the Gods (ch. where Elvar
# uncovers Ulfrir's skeletal remains). Off-quote is flavor text (no clean
# second verbatim line was worth chasing for a niche unadapted series) --
# marked as such. No sound: no game/film adaptation exists to source a clip
# from, per the "don't fake it" rule.
#
# Usage: ulfrir-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="ulfrir"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/ulfrir"
COLORS_JSON="$HOME/.config/ml4w/colors/ulfrir.json"
COLORS_CONF="$HOME/.config/hypr/colors/ulfrir.conf"
LOGO="$HOME/.config/fastfetch/assets/ulfrir-face.png"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Ulfrir" "\"It is Ulfrir,\" Elvar breathed, stumbling away, looking again at the mound." 2>/dev/null || true
else
    deactivate_static_theme "$ID"
    notify-send -a "Ulfrir" "The wolf-god sleeps again." 2>/dev/null || true
fi
