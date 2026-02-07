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
    # Extract the first frame as high quality image
    # -y: overwrite
    # -i: input
    # -frames:v 1: only one frame
    # -q:v 2: high quality (2-5 is good)
    ffmpeg -y -i "$WALLPAPER" -frames:v 1 -q:v 2 "$FRAME_OUT" > /dev/null 2>&1
    COLOR_SOURCE="$FRAME_OUT"
else
    COLOR_SOURCE="$WALLPAPER"
fi

# Run wallust to generate colors
if command -v wallust >/dev/null 2>&1; then
    wallust run "$COLOR_SOURCE"
fi

# Reload configurations
hyprctl reload
killall -SIGUSR1 kitty 2>/dev/null
killall -SIGUSR1 wezterm 2>/dev/null

# Send notification (optional)
# notify-send "Wallpaper Updated" "Colors generated from $(basename "$COLOR_SOURCE")"
