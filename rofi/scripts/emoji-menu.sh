#!/usr/bin/env bash

set -e

EMOJI_FILE="$HOME/.cache/rofi-emoji.txt"
URLS=(
  "https://emojipedia.org/people"
  "https://emojipedia.org/nature"
  "https://emojipedia.org/food-drink"
  "https://emojipedia.org/activity"
  "https://emojipedia.org/travel-places"
  "https://emojipedia.org/objects"
  "https://emojipedia.org/symbols"
  "https://emojipedia.org/flags"
)

function notify() {
  if command -v notify-send &>/dev/null; then
    notify-send "$1" "$2"
  else
    echo "$1: $2"
  fi
}

function download() {
  notify "$(basename "$0")" 'Downloading all emoji for your pleasure'

  echo "" >"$EMOJI_FILE"

  for url in "${URLS[@]}"; do
    echo "📥 Downloading: $url"
    emojis=$(curl -s "$url" |
      xmllint --html --xpath '//ul[@class="emoji-list"]' - 2>/dev/null || true)

    # If the xpath result is empty, skip
    if [[ -z "$emojis" ]]; then
      echo "⚠️ Failed to extract emoji from $url"
      continue
    fi

    # Remove opening/closing ul
    emojis=$(echo "$emojis" | head -n -1 | tail -n +1)

    # Extract emoji and description
    emojis=$(echo "$emojis" | sed -rn 's/.*<span class="emoji">(.*)<\/span> (.*)<\/a><\/li>/\1 \2/p')

    echo "$emojis" >>"$EMOJI_FILE"
  done

  notify "$(basename "$0")" "✅ Emoji updated!"
}

# Run download if file doesn't exist
if [ ! -f "$EMOJI_FILE" ] || [ ! -s "$EMOJI_FILE" ]; then
  download
fi

# Use rofi to pick emoji
selected=$(cat "$EMOJI_FILE" | rofi -dmenu -i -p "😀 Emoji:")

# Extract emoji character
emoji_char="${selected%% *}"

# Copy to clipboard and notify
if [[ -n "$emoji_char" ]]; then
  echo -n "$emoji_char" | xclip -selection clipboard
  notify "📋 Copied!" "$emoji_char copied to clipboard."
fi
