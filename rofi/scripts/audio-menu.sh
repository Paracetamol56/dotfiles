#!/usr/bin/env bash

# Rofi config
config="$HOME/.config/rofi/audio-menu.rasi"

# Rofi window override
override_disabled="mainbox { children: [ listview ]; } listview { lines: 1; padding: 6px; }"

# Notification handler (consistent with your existing scripts)
if command -v notify-send >/dev/null 2>&1; then
  SEND="notify-send"
elif command -v dunstify >/dev/null 2>&1; then
  SEND="dunstify"
else
  SEND="/bin/false"
fi

# Get audio device icon based on description
get_audio_icon() {
  local description="$1"
  case "$description" in
  *"Headphones"* | *"Headset"*) echo "󰋋 " ;;
  *"Speakers"* | *"Speaker"*) echo "󰓃 " ;;
  *"Monitor"* | *"Display"* | *"HDMI"*) echo "󰍹 " ;;
  *"USB"*) echo "󰗮 " ;;
  *"Bluetooth"* | *"BT"*) echo "󰂯 " ;;
  *"Built-in"* | *"Internal"*) echo "󰕾 " ;;
  *) echo "󰓃 " ;; # Default speaker icon
  esac
}

# Get microphone icon based on description
get_mic_icon() {
  local description="$1"
  case "$description" in
  *"Headphones"* | *"Headset"*) echo "󰋎 " ;;
  *"USB"*) echo "󰍬 " ;;
  *"Bluetooth"* | *"BT"*) echo "󰂰 " ;;
  *"Built-in"* | *"Internal"*) echo "󰍬 " ;;
  *"Webcam"* | *"Camera"*) echo "󰄀 " ;;
  *) echo "󰍬 " ;; # Default microphone icon
  esac
}

while true; do
  # Check if PulseAudio is available
  if ! command -v pactl >/dev/null 2>&1; then
    echo "PulseAudio not found"
    $SEND -t 3000 -u critical "PulseAudio not available"
    exit 1
  fi

  # Get current default devices
  current_sink=$(pactl get-default-sink 2>/dev/null)
  current_source=$(pactl get-default-source 2>/dev/null)

  # Get current sink description
  current_sink_desc=""
  if [[ -n "$current_sink" ]]; then
    current_sink_desc=$(pactl list sinks | grep -A 10 "Name: $current_sink" | grep "Description:" | cut -d: -f2 | xargs)
  fi

  # Get current source description
  current_source_desc=""
  if [[ -n "$current_source" ]]; then
    current_source_desc=$(pactl list sources | grep -A 10 "Name: $current_source" | grep "Description:" | cut -d: -f2 | xargs)
  fi

  # Build output devices list
  output_devices=""
  while IFS= read -r description; do
    clean_desc=$(echo "$description" | xargs)
    if [[ -n "$clean_desc" ]]; then
      icon=$(get_audio_icon "$clean_desc")
      # Mark current device
      if [[ "$clean_desc" == "$current_sink_desc" ]]; then
        output_devices+="● ${icon}${clean_desc}"$'\n'
      else
        output_devices+="  ${icon}${clean_desc}"$'\n'
      fi
    fi
  done < <(pactl list sinks | grep -i "description:" | cut -d: -f2 | sort)

  # Build input devices list
  input_devices=""
  while IFS= read -r description; do
    clean_desc=$(echo "$description" | xargs)
    # Skip monitor sources (they're outputs being monitored)
    if [[ -n "$clean_desc" && ! "$clean_desc" =~ \.monitor$ ]]; then
      icon=$(get_mic_icon "$clean_desc")
      # Mark current device
      if [[ "$clean_desc" == "$current_source_desc" ]]; then
        input_devices+="● ${icon}${clean_desc}"$'\n'
      else
        input_devices+="  ${icon}${clean_desc}"$'\n'
      fi
    fi
  done < <(pactl list sources | grep -i "description:" | cut -d: -f2 | sort)

  # Remove trailing newlines
  output_devices="${output_devices%$'\n'}"
  input_devices="${input_devices%$'\n'}"

  # Build complete menu
  menu_content=$(
    echo "󰕾  Refresh Devices"
    echo "󰖁  Toggle Output Mute"
    echo "󰍭  Toggle Input Mute"
    echo ""
    echo "━━━ 󰓃 OUTPUT DEVICES ━━━"
    echo "$output_devices"
    echo ""
    echo "━━━ 󰍬 INPUT DEVICES ━━━"
    echo "$input_devices"
  )

  # Display menu
  selected_option=$(echo -e "$menu_content" | rofi -dmenu -i -selected-row 4 -config "${config}" -p "󰕿 " || pkill -x rofi)

  # Exit if no option is selected
  if [ -z "$selected_option" ]; then
    exit
  fi

  # Actions based on selected option
  case "$selected_option" in
  "󰕾  Refresh Devices")
    $SEND -t 1000 -u low "Refreshing audio devices..."
    continue
    ;;
  "󰖁  Toggle Output Mute")
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    if pactl get-sink-mute @DEFAULT_SINK@ | grep -q "yes"; then
      $SEND -t 2000 -u low "Output muted"
    else
      $SEND -t 2000 -u low "Output unmuted"
    fi
    continue
    ;;
  "󰍭  Toggle Input Mute")
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
    if pactl get-source-mute @DEFAULT_SOURCE@ | grep -q "yes"; then
      $SEND -t 2000 -u low "Input muted"
    else
      $SEND -t 2000 -u low "Input unmuted"
    fi
    continue
    ;;
  "" | "━━━"*)
    # Skip empty lines and section headers
    continue
    ;;
  *)
    # Extract device description (remove status indicator and icon)
    desc="${selected_option#* }" # Remove status indicator (● or spaces)
    desc="${desc#* }"            # Remove icon
    desc="${desc## }"            # Clean whitespace

    if [[ -n "$desc" ]]; then
      # Check if it's an output or input device
      if echo "$output_devices" | grep -qF "$desc"; then
        # Handle output device
        device=$(pactl list sinks | grep -C2 -F "Description: $desc" | grep "Name:" | cut -d: -f2 | xargs)

        if [[ -n "$device" ]]; then
          if pactl set-default-sink "$device"; then
            $SEND -t 2000 -u low "Output: $desc"
            exit
          else
            $SEND -t 3000 -u critical "Error setting output: $desc"
          fi
        else
          $SEND -t 3000 -u critical "Output device not found: $desc"
        fi
      elif echo "$input_devices" | grep -qF "$desc"; then
        # Handle input device
        device=$(pactl list sources | grep -C2 -F "Description: $desc" | grep "Name:" | cut -d: -f2 | xargs)

        if [[ -n "$device" ]]; then
          if pactl set-default-source "$device"; then
            $SEND -t 2000 -u low "Input: $desc"
            exit
          else
            $SEND -t 3000 -u critical "Error setting input: $desc"
          fi
        else
          $SEND -t 3000 -u critical "Input device not found: $desc"
        fi
      fi
    fi
    ;;
  esac
done
