#!/usr/bin/env bash
# Applies the persisted shell profile (~/.config/hypr/settings/shell-profile)
# at Hyprland login. This is what conf/autostart.conf actually execs -- see
# its header for why conf/autostart.lua's branching logic never runs.
#
# Reuses switch-shell-profile.sh with the saved value passed explicitly as
# the target (never its no-arg toggle form -- boot must reproduce the saved
# choice, not flip it) so login and live-switching share one code path
# instead of two copies of the same swaync/hypridle/noctalia/waybar logic.
set -uo pipefail

shell_profile="ml4w"
f="$HOME/.config/hypr/settings/shell-profile"
[ -f "$f" ] && shell_profile="$(cat "$f")"

exec "$(dirname "${BASH_SOURCE[0]}")/switch-shell-profile.sh" "$shell_profile"
