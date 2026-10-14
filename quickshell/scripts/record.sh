#!/usr/bin/env bash
# Records a selected area to ~/Videos/Recordings with wf-recorder.
# Stop it with SIGINT (the dashboard does this); the file is finalised before exiting.

dir="$HOME/Videos/Recordings"
file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').mp4"
mkdir -p "$dir"

geometry=$(slurp) || exit 1 # cancelled with Esc

wf-recorder -g "$geometry" -f "$file" &
pid=$!
# Forward the stop signal to wf-recorder, then wait for it to finish writing
trap 'kill -INT $pid' INT TERM
wait $pid
wait $pid

notify-send "Recording saved" "${file##*/}"
