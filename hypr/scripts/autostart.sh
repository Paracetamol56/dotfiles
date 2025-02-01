#!/bin/zsh

# ------ Start Wallpaper ------ #
swww init

# ------ Start Waybar ------ #
waybar &

# ------ Network Manager Applet ------ #
nm-applet &

# ------ Start Authentication Agent ------ #
# Used when an application wants to elevate its privileges
exec /usr/lib/polkit-kde-authentication-agent-1
