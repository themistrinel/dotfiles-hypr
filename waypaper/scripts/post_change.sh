#!/bin/bash

# Script called by Waypaper to handle video wallpapers and color generation

WALLPAPER="$1"
TEMP_DIR="$HOME/Pictures/tmp"
FRAME_OUT="$TEMP_DIR/current_wall_frame.png"

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"

# Check if the file is a video
extension="${WALLPAPER##*.}"
is_video=false

case "$extension" in
    mp4|mkv|mov|avi|webm)
        is_video=true
        ;;
esac

if [ "$is_video" = true ]; then
    # Extract the first frame as high quality image for wallust
    ffmpeg -y -i "$WALLPAPER" -frames:v 1 -q:v 2 "$FRAME_OUT" > /dev/null 2>&1
    COLOR_SOURCE="$FRAME_OUT"

    # Set the extracted frame as static wallpaper with swww
    if command -v swww >/dev/null 2>&1; then
        swww img "$FRAME_OUT" --transition-type grow --transition-pos top-right --transition-duration 2
    fi

    # Stop any previous video and start the new one
    killall mpvpaper 2>/dev/null
    # Wait a bit for it to release the surface if needed
    sleep 0.1
    # Run mpvpaper
    mpvpaper -o "no-audio loop" "*" "$WALLPAPER" &
else
    COLOR_SOURCE="$WALLPAPER"
    # Kill mpvpaper if we are switching to a static image
    killall mpvpaper 2>/dev/null
fi

# Run wallust to generate colors
if command -v wallust >/dev/null 2>&1; then
    wallust run "$COLOR_SOURCE"
fi

# Reload configurations
hyprctl reload
killall -SIGUSR1 kitty 2>/dev/null
killall -SIGUSR1 wezterm 2>/dev/null

# Restart waybar to apply new colors
killall waybar 2>/dev/null
waybar &

# Send notification (optional)
# notify-send "Wallpaper Updated" "Colors generated from $(basename "$COLOR_SOURCE")"
