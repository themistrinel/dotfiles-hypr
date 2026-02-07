#!/bin/bash
# Reload script for Hyprland and components

# Reload Hyprland
hyprctl reload

# Restart Waybar
killall waybar
waybar &

# Reload Dunst
killall dunst
dunst &

# Reload Hyprpaper (if used)
if pgrep -x "hyprpaper" > /dev/null; then
    killall hyprpaper
    hyprpaper &
fi

# Reload SWWW (if used)
if pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon --format xrgb &
fi

~/.config/hypr/scripts/gtk.sh


notify-send "Hyprland" "Configuration Reloaded"
