#!/usr/bin/env bash

# Toggle floating and pinning (sticky) for the active window
hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })'
hyprctl dispatch 'hl.dsp.window.pin()'