#!/usr/bin/env bash
# theme.sh — muda o tema manualmente, ignorando o horário automático
# Uso: theme [light|dark|toggle]

CONF="$HOME/.dotfiles/hypr/scripts/theme-schedule.conf"
POST_CHANGE="$HOME/.config/waypaper/scripts/post_change.sh"
PRESET_FILE="$HOME/.cache/wal/.preset"
OVERRIDE_FILE="$HOME/.cache/wal/.theme-override"

source "$CONF"

update_settings_ini() {
    local theme="$1"
    for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
        [ -f "$ini" ] && sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$theme/" "$ini"
    done
}

apply_light() {
    echo "light" > "$OVERRIDE_FILE"
    mkdir -p "$(dirname "$PRESET_FILE")"
    echo "$LIGHT_PRESET" > "$PRESET_FILE"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme "$LIGHT_GTK_THEME"
    update_settings_ini "$LIGHT_GTK_THEME"
    sleep 0.15
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    waypaper --wallpaper "$WALLPAPER_DIR/$LIGHT_WALLPAPER"
    notify-send "Tema" "Modo claro ativado" -i weather-clear 2>/dev/null
}

apply_dark() {
    echo "dark" > "$OVERRIDE_FILE"
    mkdir -p "$(dirname "$PRESET_FILE")"
    echo "$DARK_PRESET" > "$PRESET_FILE"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    gsettings set org.gnome.desktop.interface gtk-theme "$DARK_GTK_THEME"
    update_settings_ini "$DARK_GTK_THEME"
    sleep 0.15
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    waypaper --wallpaper "$WALLPAPER_DIR/$DARK_WALLPAPER"
    notify-send "Tema" "Modo escuro ativado" -i weather-clear-night 2>/dev/null
}

get_current() {
    cat "$OVERRIDE_FILE" 2>/dev/null || echo "auto"
}

case "${1:-toggle}" in
    light)  apply_light ;;
    dark)   apply_dark ;;
    toggle)
        current=$(get_current)
        if [ "$current" = "light" ]; then apply_dark; else apply_light; fi
        ;;
    auto)
        rm -f "$OVERRIDE_FILE"
        "$HOME/.dotfiles/hypr/scripts/theme-auto.sh"
        notify-send "Tema" "Modo automático restaurado" 2>/dev/null
        ;;
    status) get_current ;;
    *)
        echo "Uso: theme [light|dark|toggle|auto|status]"
        exit 1
        ;;
esac
