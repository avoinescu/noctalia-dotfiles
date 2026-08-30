#!/usr/bin/env bash
# Static "Vergil" theme (Devil May Cry) -- his signature blue coat, Yamato
# steel-silver, cold Devil-Trigger ice-blue energy, on near-black. One-shot
# apply/revert, not a poller. Shared apply/deactivate logic (including
# cross-theme preemption) lives in custom-theme-lib.sh, used by every
# static custom theme.
#
# The on-quote is real, verified via web search (Devil May Cry Wiki's
# Vergil/Quotes page): his line from Devil May Cry 3 about strength and
# protection -- trimmed slightly, full line is "Foolishness! Might controls
# everything. And without strength, you cannot protect anything. Let alone
# yourself."
#
# The on-notification also plays sounds/vergil.mp3 -- a real Vergil voice
# line, sourced from myinstants.com.
#
# Usage: vergil-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="vergil"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/vergil"
COLORS_JSON="$HOME/.config/ml4w/colors/vergil.json"
COLORS_CONF="$HOME/.config/hypr/colors/vergil.conf"
LOGO="$HOME/.config/fastfetch/assets/vergil-face.png"
SOUND="$HOME/.config/hypr/sounds/vergil.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Vergil" "Might controls everything. Without strength, you cannot protect anything." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Vergil" "Power recedes into silence." 2>/dev/null || true
fi
