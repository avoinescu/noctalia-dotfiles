#!/usr/bin/env bash
# Static "Proxima, the Broodseeker" theme (Mortal Shell II, 2026) -- sacred
# amber flame and ashen stone on near-black bone, with an electric-blue
# accent for Proxima's Biosampler lightning ability. One-shot apply/revert,
# not a poller. Shared apply/deactivate logic (including cross-theme
# preemption) lives in custom-theme-lib.sh, used by every static custom
# theme.
#
# Mortal Shell II released Aug 2026, days before this theme was built, and
# no canonical Proxima dialogue was findable yet -- the notification lines
# below are mechanic-inspired flavor text ("Harden" is the franchise's
# signature stone-shell ability), not verbatim character quotes like the
# other themes' notifications.
#
# Usage: proxima-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="proxima"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/proxima"
COLORS_JSON="$HOME/.config/ml4w/colors/proxima.json"
COLORS_CONF="$HOME/.config/hypr/colors/proxima.conf"
LOGO="$HOME/.config/fastfetch/assets/proxima-face.png"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Proxima, the Broodseeker" "Harden. Endure. Become the shell." 2>/dev/null || true
else
    deactivate_static_theme "$ID"
    notify-send -a "Proxima, the Broodseeker" "The shell falls silent once more." 2>/dev/null || true
fi
