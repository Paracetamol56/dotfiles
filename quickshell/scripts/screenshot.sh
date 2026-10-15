#!/usr/bin/env bash
# Screenshot to ~/Pictures/Screenshots and the clipboard.
# Usage: screenshot.sh area|window|screen   (screen = the focused monitor)

dir="$HOME/Pictures/Screenshots"
file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"
mkdir -p "$dir"

case "$1" in
area)
  geometry=$(slurp) || exit 1 # cancelled with Esc
  grim -g "$geometry" "$file"
  ;;
window)
  geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
  grim -g "$geometry" "$file"
  ;;
screen)
  grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" "$file"
  ;;
*)
  echo "Usage: $0 area|window|screen" >&2
  exit 1
  ;;
esac || exit 1

wl-copy --type image/png <"$file"
notify-send --icon "$file" "Screenshot saved" "${file##*/} · copied to clipboard"
