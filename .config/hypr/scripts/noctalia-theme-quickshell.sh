#!/usr/bin/env bash
# Two jobs, both because Noctalia's own wallpaper picker never touches
# ml4w's old wallpaper.sh/Matugen pipeline:
#  1. Regenerates the rofi theme-picker's blurred background image (below).
#  2. Keeps the two surviving ml4w Quickshell panels (Power, AIUsageWindow --
#     see shell.qml) and the standalone Overview switcher in sync with the
#     wallpaper's colors, via the scoped config-quickshell.toml Matugen pass.
#
# Wired up via Noctalia's [hooks] wallpaper_changed
# (~/.config/noctalia/config.toml), which passes the new path as $1.
#
# Skips entirely while a custom theme (static or Hellsing) is applying/
# active: those scripts call wallpaper-set too, and this hook firing on that
# same wallpaper change would recolor Quickshell from the raw photo (a
# generic, unrelated-looking palette) moments before the theme script's own
# hand-picked colors.json overwrites it -- a brief but visible "wrong colors
# first" flash. Both custom-theme-lib.sh's apply_static_theme and Hellsing's
# toggle write their "active" markers before calling wallpaper-set, so this
# check is never stale for that race.
set -uo pipefail

wallpaper="${1:?usage: noctalia-theme-quickshell.sh <wallpaper-path>}"

# Regenerate the rofi theme-picker's blurred background from the real,
# current wallpaper -- unconditionally, even while a custom theme is
# applying/active, since (unlike the matugen/Quickshell recolor below) this
# has no race to guard against, just a cosmetic background image. Was
# previously ml4w-wallpaper's job (never called by Noctalia's own wallpaper
# picker), which is why it kept going stale.
CACHE_FOLDER="$HOME/.cache/ml4w/hyprland-dotfiles"
BLURRED_WALLPAPER="$CACHE_FOLDER/blurred_wallpaper.png"
RASI_FILE="$CACHE_FOLDER/current_wallpaper.rasi"
BLUR="$(cat "$HOME/.config/ml4w/settings/blur.sh" 2>/dev/null || echo "50x30")"
mkdir -p "$CACHE_FOLDER"
magick "$wallpaper" -resize 75% "$BLURRED_WALLPAPER"
[ "$BLUR" != "0x0" ] && magick "$BLURRED_WALLPAPER" -blur "$BLUR" "$BLURRED_WALLPAPER"
echo "* { current-image: url(\"$BLURRED_WALLPAPER\", height); }" > "$RASI_FILE"

active_static=""
[ -f "$HOME/.cache/ml4w/active-static-theme" ] && active_static="$(cat "$HOME/.cache/ml4w/active-static-theme")"
hellsing_on="off"
[ -f "$HOME/.config/ml4w/settings/hellsing-theme" ] && hellsing_on="$(cat "$HOME/.config/ml4w/settings/hellsing-theme")"
if [ -n "$active_static" ] || [ "$hellsing_on" = "on" ]; then
    exit 0
fi

mode="dark"
gtk_settings="$HOME/.config/gtk-3.0/settings.ini"
if [ -f "$gtk_settings" ]; then
    pref=$(grep -E '^gtk-application-prefer-dark-theme=' "$gtk_settings" | awk -F'=' '{print $2}')
    [ "$pref" = "0" ] && mode="light"
fi

matugen image "$wallpaper" -c "$HOME/.config/matugen/config-quickshell.toml" -m "$mode" --prefer saturation

# Theme.qml doesn't watch colors.json -- it only re-reads it on this IPC call.
qs ipc call theme-manager reload 2>/dev/null || true
