#!/usr/bin/env bash

# Notifications
source "$HOME/.config/hypr/scripts/notify-handler.sh"

killall hypridle
sleep 1
hypridle &

notify_user --a "Hypridle" \
        --s "Hypridle has been restarted." \
        --m ""
