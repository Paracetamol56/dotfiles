#!/bin/bash

asusctl profile -n

profile=$(asusctl profile -p | grep -oP '(?<=Active profile is ).*')

notify-send "Current Profile: $profile"
