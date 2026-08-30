#!/usr/bin/env bash
# Static "Nurgle" theme (Warhammer 40,000 / Warhammer Fantasy) -- the Chaos
# God of Decay, Disease, and twisted "life" -- putrid rotten green, rust
# brown, bile-yellow, on a swampy near-black. One-shot apply/revert, not a
# poller. Shared apply/deactivate logic (including cross-theme preemption)
# lives in custom-theme-lib.sh, used by every static custom theme.
#
# Both quotes are verbatim from the Tome of Decay (Warhammer 40,000
# supplement), verified via web search, not memory:
#   on:  "...decay brings an end to all things, but that through such decay
#         life begins anew."
#   off: "Decay is the victor in all battles, the opposition to which there
#         is no resistance."
#
# The on-notification also plays a random clip from sounds/nurgle/ -- three
# real Nurgle-tagged lines/barks from Total War: Warhammer, sourced from
# myinstants.com and confirmed Nurgle-tagged on their own pages.
#
# Usage: nurgle-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="nurgle"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/nurgle"
COLORS_JSON="$HOME/.config/ml4w/colors/nurgle.json"
COLORS_CONF="$HOME/.config/hypr/colors/nurgle.conf"
LOGO="$HOME/.config/fastfetch/assets/nurgle-face.png"
SOUND="$HOME/.config/hypr/sounds/nurgle"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Nurgle" "...through such decay, life begins anew." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Nurgle" "Decay is the victor in all battles, the opposition to which there is no resistance." 2>/dev/null || true
fi
