#!/bin/bash

# Script to apply GTK themes and settings in Hyprland
# This ensures that settings changed in LXAppearance (which writes to settings.ini) 
# are correctly applied via gsettings for Wayland applications.

GNOME_SCHEMA="org.gnome.desktop.interface"

# Get values from ~/.config/gtk-3.0/settings.ini
GTK_THEME=$(grep 'gtk-theme-name' ~/.config/gtk-3.0/settings.ini | cut -d'=' -f2)
ICON_THEME=$(grep 'gtk-icon-theme-name' ~/.config/gtk-3.0/settings.ini | cut -d'=' -f2)
CURSOR_THEME=$(grep 'gtk-cursor-theme-name' ~/.config/gtk-3.0/settings.ini | cut -d'=' -f2)
FONT_NAME=$(grep 'gtk-font-name' ~/.config/gtk-3.0/settings.ini | cut -d'=' -f2)
CURSOR_SIZE=$(grep 'gtk-cursor-theme-size' ~/.config/gtk-3.0/settings.ini | cut -d'=' -f2)

# Apply settings via gsettings
gsettings set "$GNOME_SCHEMA" gtk-theme "$GTK_THEME"
gsettings set "$GNOME_SCHEMA" icon-theme "$ICON_THEME"
gsettings set "$GNOME_SCHEMA" cursor-theme "$CURSOR_THEME"
gsettings set "$GNOME_SCHEMA" font-name "$FONT_NAME"
gsettings set "$GNOME_SCHEMA" cursor-size "${CURSOR_SIZE:-24}"

# Also set color scheme preference (prefer-dark if theme suggests it)
if [[ "$GTK_THEME" == *"dark"* ]] || [[ "$GTK_THEME" == *"Dark"* ]] || [[ "$GTK_THEME" == *"mocha"* ]]; then
    gsettings set "$GNOME_SCHEMA" color-scheme "prefer-dark"
else
    gsettings set "$GNOME_SCHEMA" color-scheme "default"
fi

# Apply cursor theme to Hyprland specifically
hyprctl setcursor "$CURSOR_THEME" "${CURSOR_SIZE:-24}"
