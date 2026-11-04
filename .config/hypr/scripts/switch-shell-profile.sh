#!/usr/bin/env bash
# Ensure Noctalia is the running shell and nothing from the retired
# ml4w/waybar profile is lingering. Used both at login (conf/autostart.conf's
# exec-once) and idempotently any other time -- safe to run repeatedly.
set -uo pipefail

# Hyprland's `bind` fires on every raw key-down, and OS key-repeat can send
# more than one for a combo held a fraction too long -- so a stray rebind of
# this script could genuinely double-fire. Block instead of racing.
lock_file="$XDG_RUNTIME_DIR/switch-shell-profile.lock"
exec 200>"$lock_file"
flock 200

# Kill by name and confirm it's actually dead (handles slow SIGTERM shutdown).
kill_and_confirm() {
    local name="$1" waited=0
    while pgrep -x "$name" >/dev/null 2>&1; do
        pkill -x "$name" 2>/dev/null
        sleep 0.2
        waited=$((waited + 1))
        [ "$waited" -ge 15 ] && break   # ~3s cap
    done
}

kill_and_confirm waybar
kill_and_confirm swaync
kill_and_confirm hypridle

if ! pgrep -x noctalia >/dev/null; then
    hyprctl dispatch exec noctalia
    while ! pgrep -x noctalia >/dev/null; do
        sleep 0.1
    done
fi
