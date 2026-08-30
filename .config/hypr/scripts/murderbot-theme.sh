#!/usr/bin/env bash
# Static "Murderbot" (The Murderbot Diaries, by Martha Wells) theme --
# gunmetal-grey SecUnit armor, dark chassis, media-feed cyan, warning-orange
# alert accent on near-black. Deliberately NOT scheduled/evolving like the
# Hellsing theme. One-shot apply/revert, not a poller. Shared apply/
# deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# No sound: no clean pre-isolated clip exists anywhere (myinstants has
# nothing, and this is a narration-heavy book-first property with only a
# very recent, 2025, TV adaptation) -- skipped rather than faking one, same
# principle as Proxima.
#
# On/off lines are real, verbatim, web-verified quotes from the first book,
# "All Systems Red" (both confirmed via Goodreads' quote pages): the
# opening line, and a later line about not caring.
#
# Usage: murderbot-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="murderbot"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/murderbot"
COLORS_JSON="$HOME/.config/ml4w/colors/murderbot.json"
COLORS_CONF="$HOME/.config/hypr/colors/murderbot.conf"
LOGO="$HOME/.config/fastfetch/assets/murderbot-face.png"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Murderbot" "I could have become a mass murderer after I hacked my governor module, but then I realized I could access the combined feed of entertainment channels carried on the company satellites." 2>/dev/null || true
else
    deactivate_static_theme "$ID"
    notify-send -a "Murderbot" "Also, you may have noticed, I don't care." 2>/dev/null || true
fi
