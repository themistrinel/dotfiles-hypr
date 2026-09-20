#!/usr/bin/env bash
# theme.sh — muda o tema manualmente, ignorando o horário automático
# Uso: theme [light|dark|glass [dark|light]|toggle|auto|status]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [ ! -f "$DOTFILES_DIR/hypr/scripts/theme-schedule.conf" ]; then
    DOTFILES_DIR="$HOME/.dotfiles"
fi

CONF="$DOTFILES_DIR/hypr/scripts/theme-schedule.conf"
GLASS_SCRIPT="$DOTFILES_DIR/hypr/scripts/glass-theme.sh"
AUTO_SCRIPT="$DOTFILES_DIR/hypr/scripts/theme-auto.sh"
POST_CHANGE="$HOME/.config/waypaper/scripts/post_change.sh"
PRESET_FILE="$HOME/.cache/wal/.preset"
OVERRIDE_FILE="$HOME/.cache/wal/.theme-override"

[ -f "$CONF" ] && source "$CONF"

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
    waypaper --wallpaper "$WALLPAPER_DIR/$LIGHT_WALLPAPER" 2>/dev/null || true
    notify-send "Tema" "Modo claro ativado" -i weather-clear 2>/dev/null || true
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
    waypaper --wallpaper "$WALLPAPER_DIR/$DARK_WALLPAPER" 2>/dev/null || true
    notify-send "Tema" "Modo escuro ativado" -i weather-clear-night 2>/dev/null || true
}

get_current() {
    if [ -f "$OVERRIDE_FILE" ]; then
        cat "$OVERRIDE_FILE" 2>/dev/null
    else
        local st
        st=$("$GLASS_SCRIPT" status 2>/dev/null || echo "")
        if [ -n "$st" ] && [ "$st" != "off" ]; then
            echo "$st"
        else
            cat "$HOME/.cache/wal/.theme-auto-mode" 2>/dev/null || echo "auto"
        fi
    fi
}

apply_glass() {
    local variant="${1:-}"

    # Se a variante não foi informada, infere pelo estado atual ou fallback para dark
    if [ -z "$variant" ]; then
        local current
        current=$(get_current)
        if [ "$current" = "light" ] || [ "$current" = "glass-light" ]; then
            variant="light"
        elif [ "$current" = "dark" ] || [ "$current" = "glass-dark" ]; then
            variant="dark"
        else
            variant="dark"
        fi
    fi

    case "$variant" in
        light)
            echo "glass-light" > "$OVERRIDE_FILE"
            mkdir -p "$(dirname "$PRESET_FILE")"
            echo "$LIGHT_PRESET" > "$PRESET_FILE"
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            gsettings set org.gnome.desktop.interface gtk-theme "$LIGHT_GTK_THEME"
            update_settings_ini "$LIGHT_GTK_THEME"
            sleep 0.15
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            "$GLASS_SCRIPT" on light
            notify-send "🔮 Glass" "Modo Glass Claro ativado" -i weather-clear 2>/dev/null || true
            ;;
        dark)
            echo "glass-dark" > "$OVERRIDE_FILE"
            mkdir -p "$(dirname "$PRESET_FILE")"
            echo "$DARK_PRESET" > "$PRESET_FILE"
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            gsettings set org.gnome.desktop.interface gtk-theme "$DARK_GTK_THEME"
            update_settings_ini "$DARK_GTK_THEME"
            sleep 0.15
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            "$GLASS_SCRIPT" on dark
            notify-send "🔮 Glass" "Modo Glass Escuro ativado" -i weather-clear-night 2>/dev/null || true
            ;;
        *)
            echo "Variante de glass inválida: $variant. Use 'light' ou 'dark'." >&2
            echo "Uso: theme [light|dark|glass [dark|light]|toggle|auto|status]" >&2
            return 1
            ;;
    esac
}

case "${1:-toggle}" in
    light)
        # If glass is active, disable it first
        "$GLASS_SCRIPT" off 2>/dev/null || true
        apply_light
        ;;
    dark)
        # If glass is active, disable it first
        "$GLASS_SCRIPT" off 2>/dev/null || true
        apply_dark
        ;;
    glass)
        apply_glass "${2:-}"
        ;;
    toggle)
        current=$(get_current)
        case "$current" in
            glass*)
                # Glass → modo sólido correspondente sem alterar o wallpaper
                "$GLASS_SCRIPT" off 2>/dev/null || true
                if [ "$current" = "glass-light" ]; then
                    echo "light" > "$OVERRIDE_FILE"
                    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
                    notify-send "Tema" "Modo claro sólido ativado" -i weather-clear 2>/dev/null || true
                else
                    echo "dark" > "$OVERRIDE_FILE"
                    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
                    notify-send "Tema" "Modo escuro sólido ativado" -i weather-clear-night 2>/dev/null || true
                fi
                ;;
            light)
                apply_dark
                ;;
            *)
                # dark → glass
                apply_glass
                ;;
        esac
        ;;
    auto)
        rm -f "$OVERRIDE_FILE"
        "$AUTO_SCRIPT" --preserve-wallpaper
        notify-send "Tema" "Modo automático restaurado" 2>/dev/null || true
        ;;
    status)
        get_current
        ;;
    *)
        echo "Uso: theme [light|dark|glass [dark|light]|toggle|auto|status]"
        exit 1
        ;;
esac
