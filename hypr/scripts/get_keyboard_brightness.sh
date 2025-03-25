#!/bin/bash

# Run the command and extract the brightness level
brightness=$(asusctl -k | grep "Current keyboard led brightness" | awk '{print $NF}')

# Map brightness levels to percentages
case "$brightness" in
"Off") percent=0 ;;
"Low") percent=33 ;;
"Med") percent=66 ;;
"High") percent=100 ;;
*) percent="Unknown" ;;
esac

# Output the percentage
echo $percent
