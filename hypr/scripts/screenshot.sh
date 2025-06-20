#!/bin/bash
# Script to capture screenshots using grim

capture_full_screen() {
  local filename="$HOME/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S.png')"
  grim "$filename" | wl-copy && notify-send "Captured Screen"
}

capture_area() {
  local filename="$HOME/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S.png')"
  grim -g "$(slurp)" "$filename" | wl-copy && notify-send "Captured Area"
}

case "$1" in
full)
  capture_full_screen
  ;;
area)
  capture_area
  ;;
*)
  echo "Usage: $0 [full|area]" >&2
  exit 1
  ;;
esac

exit 0
