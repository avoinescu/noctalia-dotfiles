#!/bin/bash
# Sidebar/Wallpaper/Calendar/Welcome/Settings panels this script used to
# special-case (close-instead-of-kill, or as SUPER+Q window titles) were
# retired once Noctalia became the sole daily-driver shell.

# Fetch the active window data as JSON and extract the title
ACTIVE_TITLE=$(hyprctl activewindow -j | jq -r '.title')

# Exit silently if no window is currently active
if [ -z "$ACTIVE_TITLE" ] || [ "$ACTIVE_TITLE" == "null" ]; then
    exit 0
fi

# Updated for Hyprland 0.55+ Lua dispatcher syntax
hyprctl dispatch 'hl.dsp.window.close()'