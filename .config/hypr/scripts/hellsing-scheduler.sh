#!/usr/bin/env bash
# "Control Art Restriction System" -- cycles through four Hellsing-inspired
# color tiers over the course of the day, like Alucard's restriction releases:
# more restrained by day, fully unleashed at night. Applies to both Noctalia's
# own palette (bar/panels/kitty/gtk via its app-theming) and the still-running
# ml4w Quickshell apps (Sidebar, Power, AIUsageWindow, etc.) via colors.json.
#
# Toggle: ~/.config/hypr/settings/hellsing-theme ("on"/"off", default on) --
# or Super+Shift+H (hellsing-theme.sh) for an instant on/off that doesn't
# wait for this poller's next tick.
# Palettes: ~/.config/noctalia/palettes/hellsing-*.json (Noctalia)
#           ~/.config/ml4w/colors/hellsing/*.json (Quickshell Theme.qml)
# Wallpapers: ~/Pictures/wallpaper/hellsing/ (4K, from wallhaven.cc)
# Fastfetch logo swap: ~/.config/fastfetch/config*.jsonc "source" line
# Shared apply/announce logic lives in hellsing-lib.sh (also used by
# hellsing-theme.sh) so the two can't drift apart on what "on" means.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/hellsing-lib.sh"

POLL_SECONDS=300

while true; do
    if [ -f "$HELLSING_TOGGLE" ] && [ "$(cat "$HELLSING_TOGGLE")" = "off" ]; then
        if [ "$(cat "$HELLSING_STATE" 2>/dev/null || true)" != "off" ]; then
            set_fastfetch_logo "$NORMAL_LOGO"
            echo "off" > "$HELLSING_STATE"
        fi
        sleep "$POLL_SECONDS"
        continue
    fi

    current_hour=$(date +%H | sed 's/^0*//')
    [ -z "$current_hour" ] && current_hour=0
    tier=$(hellsing_tier_for_hour "$current_hour")
    last="$(cat "$HELLSING_STATE" 2>/dev/null || true)"

    if [ "$tier" != "$last" ]; then
        hellsing_apply_tier "$tier"
        hellsing_announce "$tier"
    fi

    sleep "$POLL_SECONDS"
done
