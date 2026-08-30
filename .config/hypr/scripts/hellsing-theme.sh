#!/usr/bin/env bash
# Instant on/off for the Hellsing scheduler (hellsing-scheduler.sh), which
# only polls every 5 minutes -- flipping its toggle file alone means waiting
# up to that long to actually see anything change. This applies the current
# tier immediately instead. Shared apply/announce logic lives in
# hellsing-lib.sh so this can't drift from what the poller itself does.
#
# Usage: hellsing-theme.sh [on|off] [tier]
#   (no arg = toggle based on current state; tier one of seal/release-1/
#   release-2/release-true forces that tier instead of the current-hour one
#   -- a preview, since the 5-minute poller will correct it back to the
#   current-hour tier on its next tick if they differ)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/hellsing-lib.sh"
# hellsing-lib.sh already sources custom-theme-lib.sh (for play_theme_sound),
# which also gives deactivate_active_static_theme used below.

CURRENT="off"
[ -f "$HELLSING_TOGGLE" ] && CURRENT="$(cat "$HELLSING_TOGGLE")"

TARGET="${1:-}"
FORCED_TIER="${2:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    # Symmetric with the static themes preempting Hellsing: if one of them
    # is active, turn it off cleanly first so it doesn't fight over the
    # same resources (fastfetch logo, ml4w colors.json, hypr colors.conf).
    deactivate_active_static_theme
    echo "on" > "$HELLSING_TOGGLE"
    if [ -n "$FORCED_TIER" ]; then
        tier="$FORCED_TIER"
    else
        current_hour=$(date +%H | sed 's/^0*//')
        [ -z "$current_hour" ] && current_hour=0
        tier=$(hellsing_tier_for_hour "$current_hour")
    fi
    hellsing_apply_tier "$tier"
    hellsing_announce "$tier"
else
    echo "off" > "$HELLSING_TOGGLE"
    set_fastfetch_logo "$NORMAL_LOGO"
    echo "off" > "$HELLSING_STATE"
fi
