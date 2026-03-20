#!/usr/bin/env bash

# Zen Mode Toggle - Remove borders and gaps when waybar is hidden

# Check if waybar is running
if pgrep -x "waybar" > /dev/null; then
    # Waybar is running, kill it and enable zen mode
    killall waybar
    
    # Remove borders and gaps
    hyprctl keyword general:border_size 0
    hyprctl keyword general:gaps_in 0
    hyprctl keyword general:gaps_out 0
    hyprctl keyword decoration:rounding 0
    
    notify-send "Zen Mode" "Enabled" -t 1000
else
    # Waybar is not running, start it and disable zen mode
    waybar &
    
    # Restore borders and gaps
    hyprctl keyword general:border_size 2
    hyprctl keyword general:gaps_in 5
    hyprctl keyword general:gaps_out 5
    hyprctl keyword decoration:rounding 10
    
    notify-send "Zen Mode" "Disabled" -t 1000
fi
