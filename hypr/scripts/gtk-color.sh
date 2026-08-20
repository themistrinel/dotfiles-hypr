#!/usr/bin/env bash
# gtk-color.sh — muda só o color-scheme GTK (light/dark) sem trocar wallpaper/pywal
# Uso: gtk-color [light|dark|toggle|status]

CONF="$HOME/.dotfiles/hypr/scripts/theme-schedule.conf"
source "$CONF"

GNOME_SCHEMA="org.gnome.desktop.interface"

get_current() {
    gsettings get "$GNOME_SCHEMA" color-scheme | tr -d "'"
}

update_gtk_ini() {
    local theme="$1"
    for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
        [ -f "$ini" ] && sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$theme/" "$ini"
    done
}

apply_light() {
    gsettings set "$GNOME_SCHEMA" color-scheme 'prefer-light'
    gsettings set "$GNOME_SCHEMA" gtk-theme "$LIGHT_GTK_THEME"
    update_gtk_ini "$LIGHT_GTK_THEME"
    notify-send "GTK" "Modo claro ativado ($LIGHT_GTK_THEME)" -i weather-clear -t 2000 2>/dev/null
    echo "light"
}

apply_dark() {
    gsettings set "$GNOME_SCHEMA" color-scheme 'prefer-dark'
    gsettings set "$GNOME_SCHEMA" gtk-theme "$DARK_GTK_THEME"
    update_gtk_ini "$DARK_GTK_THEME"
    notify-send "GTK" "Modo escuro ativado ($DARK_GTK_THEME)" -i weather-clear-night -t 2000 2>/dev/null
    echo "dark"
}

case "${1:-toggle}" in
    light)
        apply_light
        ;;
    dark)
        apply_dark
        ;;
    toggle)
        current=$(get_current)
        if [[ "$current" == *"light"* ]]; then
            apply_dark
        else
            apply_light
        fi
        ;;
    status)
        current=$(get_current)
        gtk_theme=$(gsettings get "$GNOME_SCHEMA" gtk-theme | tr -d "'")
        echo "color-scheme: $current"
        echo "gtk-theme:    $gtk_theme"
        ;;
    *)
        echo "Uso: gtk-color [light|dark|toggle|status]"
        exit 1
        ;;
esac
