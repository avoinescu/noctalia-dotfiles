#!/usr/bin/env bash
# Flip between the "ml4w" (Waybar/swaync/hypridle) and "noctalia" shell
# profiles live, without a full Hyprland restart. Also updates the state file
# that ~/.config/hypr/scripts/autostart-shell.sh reads on the next real
# login (via conf/autostart.conf's exec-once), so the choice sticks across
# reboots too -- that script just re-invokes this one with the saved value.
#
# Usage: switch-shell-profile.sh [ml4w|noctalia]   (no arg = toggle)
set -uo pipefail

# Hyprland's `bind` fires on every raw key-down, and OS key-repeat can send
# more than one for a combo held a fraction too long -- so this can genuinely
# double-fire. Unlike waybar/launch.sh's lock (skip if one's already running),
# this one must BLOCK: `hyprctl dispatch exec` is fire-and-forget, so a second
# switch fired right after a first one can pkill *before* the first's target
# process has actually materialized, miss it, and see it appear seconds later
# looking like a leftover bar. Queuing behind a blocking lock, combined with
# each branch waiting for its own dispatched process to actually appear
# before exiting (see wait_for below), guarantees a queued switch never starts
# until the previous one's spawn has genuinely settled.
lock_file="$XDG_RUNTIME_DIR/switch-shell-profile.lock"
exec 200>"$lock_file"
flock 200

SETTINGS_FILE="$HOME/.config/ml4w/settings/shell-profile"
CURRENT="ml4w"
[ -f "$SETTINGS_FILE" ] && CURRENT="$(cat "$SETTINGS_FILE")"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "noctalia" ] && TARGET="ml4w" || TARGET="noctalia"
fi

if [ "$TARGET" != "ml4w" ] && [ "$TARGET" != "noctalia" ]; then
    echo "Usage: $0 [ml4w|noctalia]" >&2
    exit 1
fi

mkdir -p "$(dirname "$SETTINGS_FILE")"
echo "$TARGET" > "$SETTINGS_FILE"
echo "Shell profile set to: $TARGET"

# swaync is registered as a D-Bus-activatable service for
# org.freedesktop.Notifications (/usr/share/dbus-1/services/org.erikreider.swaync.service).
# Under the noctalia profile, Noctalia owns that D-Bus name itself -- but the
# *instant* it's not running, the next notify-send from anything (Bluetooth,
# a browser, our own hellsing-scheduler.sh) makes systemd auto-activate
# swaync.service again, bypassing this script entirely. Stopping it isn't
# enough -- it must be masked so D-Bus activation can't bring it back.
stop_swaync() {
    systemctl --user mask --now swaync.service 2>/dev/null
    pkill -x swaync 2>/dev/null
}

start_swaync() {
    systemctl --user unmask swaync.service 2>/dev/null
    pgrep -x swaync >/dev/null || hyprctl dispatch exec swaync
}

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

# Block until a just-dispatched process actually shows up, so the lock isn't
# released -- and a queued next switch can't start -- while it's still in
# flight. Uncapped is fine: this only runs while holding the lock, for a
# process we ourselves just told Hyprland to start.
wait_for() {
    local name="$1"
    while ! pgrep -x "$name" >/dev/null 2>&1; do
        sleep 0.1
    done
}

if [ "$TARGET" = "noctalia" ]; then
    kill_and_confirm waybar
    stop_swaync
    kill_and_confirm hypridle
    if ! pgrep -x noctalia >/dev/null; then
        hyprctl dispatch exec noctalia
        wait_for noctalia
    fi
else
    kill_and_confirm noctalia
    if ! pgrep -x hypridle >/dev/null; then
        hyprctl dispatch exec hypridle
        wait_for hypridle
    fi
    start_swaync
    if ! pgrep -x waybar >/dev/null; then
        hyprctl dispatch exec "$HOME/.config/waybar/launch.sh"
        wait_for waybar
    fi
fi
