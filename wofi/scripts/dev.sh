#!/bin/bash

# Check if zen-browser is already running; launch it if not
if ! pgrep -x "zen-browser" >/dev/null; then
  echo "Launching zen-browser on workspace 2"
  hyperctl dispatch exec [workspace 2] "zen-browser"
else
  echo "zen-browser is already running"
fi

# Launch first kitty on workspace 3
echo "Launching kitty on workspace 3"
hyprctl dispatch exec [workspace 3 silent] "kitty --directory /mnt/data/dev/"

# Launch second kitty with nvim in workspace 3
echo "Launching nvim in kitty on workspace 3"
hyprctl dispatch exec [workspace 3 silent] "kitty --directory /mnt/data/dev/ -e nvim"
