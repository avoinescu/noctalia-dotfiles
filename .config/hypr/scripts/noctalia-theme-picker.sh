#!/usr/bin/env bash
# Rofi menu to switch between our custom themes -- Hellsing's tiers and
# every static theme. Deliberately does NOT list Noctalia's own
# builtin/community schemes or "Wallpaper (auto)" -- this menu is for our
# hand-built themes only, not a general Noctalia scheme picker.
#
# Kept as a dormant fallback: $mainMod SHIFT, P now opens the QML grid
# picker (ThemePickerApp, shows a wallpaper thumbnail per theme) instead,
# but this still works standalone if that ever breaks. Both read the same
# theme-list.sh, so they can't drift out of sync with each other.
set -uo pipefail
SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"

shell_profile="ml4w"
[ -f "$HOME/.config/hypr/settings/shell-profile" ] && shell_profile="$(cat "$HOME/.config/hypr/settings/shell-profile")"
if [ "$shell_profile" != "noctalia" ]; then
    notify-send -a "Theme" "Switch to the noctalia profile first" "Super+Shift+N" 2>/dev/null
    exit 0
fi

ORDER=()
declare -A ACTIONS

add() {
    ORDER+=("$1")
    ACTIONS["$1"]="$2"
}

# Entries live in theme-list.sh, shared with theme-list-json.sh (the QML
# grid picker's data source) so the two pickers can't drift out of sync.
source "$SCRIPTS_DIR/theme-list.sh"
for entry in "${THEMES[@]}"; do
    IFS='|' read -r id label tier <<< "$entry"
    add "$label" "$SCRIPTS_DIR/${id}-theme.sh on${tier:+ $tier}"
done

choice=$(printf '%s\n' "${ORDER[@]}" | rofi -dmenu -replace -i -config ~/.config/rofi/config-themes.rasi -no-show-icons -width 35 -p "Custom Theme")

[ -n "$choice" ] && [ -n "${ACTIONS["$choice"]+x}" ] || exit 0
eval "${ACTIONS["$choice"]}"
