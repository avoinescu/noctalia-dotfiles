#!/usr/bin/env bash
# The "papirus-icons" Noctalia community template (and anything else that
# calls `gsettings set org.gnome.desktop.interface icon-theme`) only updates
# gsettings/dconf. Under this ml4w/Hyprland setup that's the wrong direction:
# ~/.config/hypr/scripts/gtk.sh pushes FROM gtk-3.0/settings.ini INTO
# gsettings on every login (the standard sway-wiki GTK-on-Wayland pattern),
# so without this, a recolored icon theme silently reverts to whatever
# settings.ini says (e.g. "kora-pgrey") the next time Hyprland starts, and
# GTK3 apps that read settings.ini directly never see the change at all.
# Wire this to Noctalia's `colors_changed` hook so it runs after every
# palette resolve, once the community template has already set gsettings.
set -uo pipefail

icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
[ -n "$icon_theme" ] || exit 0

for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    [ -f "$f" ] || continue
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_theme/" "$f"
done
