#!/usr/bin/env bash
#                                      __   
#   ___ ____ ___ _  ___ __ _  ___  ___/ /__ 
#  / _ `/ _ `/  ' \/ -_)  ' \/ _ \/ _  / -_)
#  \_, /\_,_/_/_/_/\__/_/_/_/\___/\_,_/\__/ 
# /___/                                     
# 


ml4w_cache_folder="$HOME/.cache/ml4w/hyprland-dotfiles"

# Notifications
source "$HOME/.config/hypr/scripts/notify-handler.sh"
APP_NAME="System"
NOTIFICATION_ICON="joystick"

if [ -f $HOME/.cache/hypr/gamemode-enabled ]; then
  if [ -f $ml4w_cache_folder/restart-wpauto ]; then
    rm $ml4w_cache_folder/restart-wpauto
    $HOME/.config/hypr/scripts/wallpaper-automation.sh &
  fi
  hyprctl reload
  rm $HOME/.cache/hypr/gamemode-enabled
  notify_user --a "${APP_NAME}" \
            --i "${NOTIFICATION_ICON}" \
            --s "Gamemode deactivated" \
            --m "Animations and blur are now enabled."
else
  if [ -f $ml4w_cache_folder/wallpaper-automation ]; then
    touch $ml4w_cache_folder/restart-wpauto
    $HOME/.config/hypr/scripts/wallpaper-automation.sh
  fi
  hyprctl eval "activate_gamemode()"
  touch $HOME/.cache/hypr/gamemode-enabled
  notify_user --a "${APP_NAME}" \
          --i "${NOTIFICATION_ICON}" \
          --s "Gamemode activated" \
          --m "Animations and blur are now disabled."
fi