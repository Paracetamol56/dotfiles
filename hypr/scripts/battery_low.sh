#!/bin/bash

notified=false

while true; do
  if [[ -r /sys/class/power_supply/BAT0/capacity ]] && [[ -r /sys/class/power_supply/BAT0/status ]]; then
    bat_lvl=$(cat /sys/class/power_supply/BAT0/capacity)
    bat_status=$(cat /sys/class/power_supply/BAT0/status)
  else
    echo "Erreur : fichiers de batterie introuvables ou non accessibles."
    exit 1
  fi

  if ! [[ "$bat_lvl" =~ ^[0-9]+$ ]]; then
    echo "Erreur : niveau batterie invalide : $bat_lvl"
    exit 1
  fi

  if [ "$bat_lvl" -le 20 ] && [ "$bat_status" = "Discharging" ]; then
    if ! $notified; then
      notify-send --urgency=high "Battery Low" "Level: ${bat_lvl}%"
      notified=true
    fi
  else
    # Batterie OK ou en charge, on reset la notification
    notified=false
  fi

  sleep 60
done
