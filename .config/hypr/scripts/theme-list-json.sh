#!/usr/bin/env bash
# Emits the same theme-list.sh entries as a JSON array, for ThemePickerApp
# (the QML grid picker) to consume via a Process/StdioCollector + JSON.parse.
# One object per entry: {id, label, tier, wallpaperDir, thumbnail, applyCmd, active}.
#
# wallpaperDir is always $HOME/Pictures/wallpaper/<id> (deterministic, see
# CREATING-A-THEME.md); thumbnail is one random image from it, or "" if the
# folder is empty/missing (wallpapers aren't tracked in git, so this can
# legitimately happen on a fresh machine -- the QML app shows a placeholder
# card in that case rather than a broken image).
#
# Known v1 limitation: Hellsing's 5 tier entries all share one wallpaper
# folder and one ACTIVE_STATIC value ("hellsing"), so all 5 cards will
# highlight together with no way to tell which specific tier is active --
# distinguishing tiers would need a new state file written by
# hellsing-theme.sh, out of scope here.
set -uo pipefail
SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"
ACTIVE_STATIC="$HOME/.cache/ml4w/active-static-theme"

source "$SCRIPTS_DIR/theme-list.sh"

active_id=""
[ -f "$ACTIVE_STATIC" ] && active_id="$(cat "$ACTIVE_STATIC")"

entries=()
for entry in "${THEMES[@]}"; do
    IFS='|' read -r id label tier <<< "$entry"
    wallpaper_dir="$HOME/Pictures/wallpaper/$id"
    thumbnail="$(find "$wallpaper_dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | shuf -n1)"
    apply_cmd="$SCRIPTS_DIR/${id}-theme.sh on${tier:+ $tier}"
    is_active="false"
    [ "$id" = "$active_id" ] && is_active="true"

    entries+=("$(jq -n \
        --arg id "$id" \
        --arg label "$label" \
        --arg tier "$tier" \
        --arg wallpaperDir "$wallpaper_dir" \
        --arg thumbnail "${thumbnail:-}" \
        --arg applyCmd "$apply_cmd" \
        --argjson active "$is_active" \
        '{id: $id, label: $label, tier: $tier, wallpaperDir: $wallpaperDir, thumbnail: $thumbnail, applyCmd: $applyCmd, active: $active}')")
done

printf '%s\n' "${entries[@]}" | jq -s '.'
