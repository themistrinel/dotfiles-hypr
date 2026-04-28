#!/bin/bash

# Script to apply GTK themes and settings in Hyprland
# This ensures that settings changed in nwg-look or manually
# are correctly applied via gsettings for Wayland applications.

GNOME_SCHEMA="org.gnome.desktop.interface"
GTK3_CONFIG="$HOME/.config/gtk-3.0/settings.ini"
GTK4_CONFIG="$HOME/.config/gtk-4.0/settings.ini"

# Check if GTK-3.0 config exists
if [ ! -f "$GTK3_CONFIG" ]; then
    echo "GTK-3.0 config not found at $GTK3_CONFIG"
    exit 1
fi

# Get values from ~/.config/gtk-3.0/settings.ini
GTK_THEME=$(grep 'gtk-theme-name' "$GTK3_CONFIG" | cut -d'=' -f2 | tr -d ' ')
ICON_THEME=$(grep 'gtk-icon-theme-name' "$GTK3_CONFIG" | cut -d'=' -f2 | tr -d ' ')
CURSOR_THEME=$(grep 'gtk-cursor-theme-name' "$GTK3_CONFIG" | cut -d'=' -f2 | tr -d ' ')
FONT_NAME=$(grep 'gtk-font-name' "$GTK3_CONFIG" | cut -d'=' -f2 | tr -d ' ')
CURSOR_SIZE=$(grep 'gtk-cursor-theme-size' "$GTK3_CONFIG" | cut -d'=' -f2 | tr -d ' ')

# Set defaults if empty
CURSOR_SIZE=${CURSOR_SIZE:-24}

# Apply settings via gsettings
gsettings set "$GNOME_SCHEMA" gtk-theme "$GTK_THEME"
gsettings set "$GNOME_SCHEMA" icon-theme "$ICON_THEME"
gsettings set "$GNOME_SCHEMA" cursor-theme "$CURSOR_THEME"
gsettings set "$GNOME_SCHEMA" font-name "$FONT_NAME"
gsettings set "$GNOME_SCHEMA" cursor-size "$CURSOR_SIZE"

# Also set color scheme preference (prefer-dark if theme suggests it)
# Set color-scheme based on schedule (same logic as theme-auto.sh)
SCHEDULE="$HOME/.dotfiles/hypr/scripts/theme-schedule.conf"
if [ -f "$SCHEDULE" ]; then
    source "$SCHEDULE"
    to_min() { IFS=: read h m <<< "$1"; echo $(( 10#$h * 60 + 10#$m )); }
    now=$(to_min "$(date +%H:%M)")
    light=$(to_min "$LIGHT_START")
    dark=$(to_min "$DARK_START")
    if (( now >= light && now < dark )); then
        gsettings set "$GNOME_SCHEMA" color-scheme "prefer-light"
    else
        gsettings set "$GNOME_SCHEMA" color-scheme "prefer-dark"
    fi
else
    # Fallback: infer from theme name
    if [[ "$GTK_THEME" == *"dark"* ]] || [[ "$GTK_THEME" == *"Dark"* ]] || [[ "$GTK_THEME" == *"mocha"* ]]; then
        gsettings set "$GNOME_SCHEMA" color-scheme "prefer-dark"
    elif [[ "$GTK_THEME" == *"light"* ]] || [[ "$GTK_THEME" == *"Light"* ]]; then
        gsettings set "$GNOME_SCHEMA" color-scheme "prefer-light"
    else
        gsettings set "$GNOME_SCHEMA" color-scheme "default"
    fi
fi

# Sync GTK-4.0 settings with GTK-3.0
mkdir -p "$HOME/.config/gtk-4.0"
cat > "$GTK4_CONFIG" << EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-font-name=$FONT_NAME
EOF

# Update GTK_THEME environment variable in hyprland.conf
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    sed -i "s/^env = GTK_THEME,.*/env = GTK_THEME,$GTK_THEME/" "$HYPR_CONF"
fi

# Apply cursor theme to Hyprland specifically
hyprctl setcursor "$CURSOR_THEME" "$CURSOR_SIZE"

# Restart Thunar to apply changes (if running)
if pgrep -x "thunar" > /dev/null; then
    killall thunar
fi

echo "GTK theme applied: $GTK_THEME"

