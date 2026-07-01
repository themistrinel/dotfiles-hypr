#!/usr/bin/env bash

# Rofi Clipboard Manager
# Uses cliphist for Wayland clipboard history

# Check dependencies
if ! command -v cliphist &> /dev/null; then
    notify-send "Clipboard Manager" "cliphist not installed\nInstall: yay -S cliphist" -u critical
    exit 1
fi

if ! command -v wl-copy &> /dev/null; then
    notify-send "Clipboard Manager" "wl-clipboard not installed\nInstall: sudo pacman -S wl-clipboard" -u critical
    exit 1
fi

# Use custom clipboard theme
THEME="$HOME/.dotfiles/rofi/clipboard-theme.rasi"

# Fallback to default launcher theme if custom doesn't exist
if [ ! -f "$THEME" ]; then
    THEME="$HOME/.config/rofi/config.rasi"
fi

# Get clipboard history and show in rofi
cliphist list | rofi -dmenu -theme "$THEME" -p "Clipboard" | cliphist decode | wl-copy
