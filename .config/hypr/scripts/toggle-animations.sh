#!/usr/bin/env bash
# Toggle animations live. (Hyprland 0.57 removed `hyprctl keyword`; options
# are now set by evaluating Lua.)
cache_file="$HOME/.cache/toggle_animation"
if [ -f "$cache_file" ]; then
    hyprctl eval 'hl.config({ animations = { enabled = true } })'
    rm "$cache_file"
else
    hyprctl eval 'hl.config({ animations = { enabled = false } })'
    touch "$cache_file"
fi
