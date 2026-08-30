#!/usr/bin/env bash
# Static "Darth Maul" theme (Star Wars) -- Sith blood-red, Zabrak-tattoo
# black, saber-hilt gold accent, on near-black. One-shot apply/revert, not
# a poller. Shared apply/deactivate logic (including cross-theme
# preemption) lives in custom-theme-lib.sh, used by every static custom
# theme.
#
# The on-quote is Maul's real line from The Phantom Menace, verified via
# web search -- he speaks only 33 words in the entire film, and this is
# the most iconic of them: "At last we will reveal ourselves to the Jedi.
# At last we will have revenge."
#
# The on-notification also plays sounds/darthmaul.mp3 -- a real Darth Maul
# voice line, sourced from myinstants.com.
#
# The fastfetch logo is a generated Sith-horn glyph rather than sourced
# character art -- pngegg's "darth maul" results kept returning other
# Star Wars characters (Kylo Ren, Vader) mislabeled as him.
#
# Usage: darthmaul-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="darthmaul"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/darthmaul"
COLORS_JSON="$HOME/.config/ml4w/colors/darthmaul.json"
COLORS_CONF="$HOME/.config/hypr/colors/darthmaul.conf"
LOGO="$HOME/.config/fastfetch/assets/darthmaul-face.png"
SOUND="$HOME/.config/hypr/sounds/darthmaul.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Darth Maul" "At last we will reveal ourselves to the Jedi. At last we will have revenge." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Darth Maul" "The double blade goes dark." 2>/dev/null || true
fi
