#!/usr/bin/env bash

WALLPAPER_FOLDER="$HOME/Pictures/wallpapers"
if [ -f "$HOME/.config/hypr/settings/wallpaper-folder" ]; then
    RAW_FOLDER=$(cat "$HOME/.config/hypr/settings/wallpaper-folder")
    WALLPAPER_FOLDER="${RAW_FOLDER//\$HOME/$HOME}"
    WALLPAPER_FOLDER="${WALLPAPER_FOLDER//\~/$HOME}"
fi

if [ -f /usr/bin/waypaper ]; then
    echo ":: Launching waybar in /usr/bin"
    waypaper $1 --folder "$WALLPAPER_FOLDER" &
elif [ -f $HOME/.local/bin/waypaper ]; then
    echo ":: Launching waybar in $HOME/.local/bin"
    $HOME/.local/bin/waypaper $1 --folder "$WALLPAPER_FOLDER" &
else
    echo ":: waypaper not found"
fi
