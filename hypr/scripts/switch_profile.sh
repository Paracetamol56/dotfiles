#!/bin/bash

asusctl profile next

profile=$(asusctl profile get | grep -oP '(?<=Active profile: ).*')

notify-send "Reactor mode: $profile"
