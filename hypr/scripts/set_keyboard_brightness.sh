#!/bin/bash

# Function to get current brightness percentage
get_brightness_percent() {
  brightness=$(asusctl leds get | grep "Current keyboard led brightness" | awk '{print $NF}')

  case "$brightness" in
  "Off") echo 0 ;;
  "Low") echo 33 ;;
  "Med") echo 66 ;;
  "High") echo 100 ;;
  *) echo 0 ;;
  esac
}

# Function to get brightness level name
get_brightness_name() {
  brightness=$(asusctl leds get | grep "Current keyboard led brightness" | awk '{print $NF}')
  echo "$brightness"
}

# Check if an argument was provided
if [ $# -eq 0 ]; then
  # No argument, just display current brightness
  percent=$(get_brightness_percent)
  echo "$percent"
  exit 0
fi

# Handle next/prev options
case "$1" in
next | n)
  asusctl leds next
  ;;
prev | previous | p)
  asusctl leds prev
  ;;
*)
  echo "Usage: $0 [next|prev]"
  echo "  next, n        - Increase keyboard brightness"
  echo "  prev, p        - Decrease keyboard brightness"
  echo "  (no option)    - Display current brightness percentage"
  exit 1
  ;;
esac

# Get the new brightness level
sleep 0.1 # Small delay to ensure the change is registered
percent=$(get_brightness_percent)
level=$(get_brightness_name)

# Send notification
notify-send "Keyboard Brightness" "$level ($percent%)" -h int:value:"$percent" -t 2000
