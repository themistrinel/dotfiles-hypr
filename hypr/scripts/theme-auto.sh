#!/usr/bin/env bash
# theme-auto.sh — aplica wallpaper, preset pywal, modo glass e filtro conforme horário
# Horários configurados em theme-schedule.conf (LIGHT_START=06:00, DARK_START=18:00)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [ ! -f "$DOTFILES_DIR/hypr/scripts/theme-schedule.conf" ]; then
    DOTFILES_DIR="$HOME/.dotfiles"
fi

CONF="$DOTFILES_DIR/hypr/scripts/theme-schedule.conf"
POST_CHANGE="$HOME/.config/waypaper/scripts/post_change.sh"
GLASS_SCRIPT="$DOTFILES_DIR/hypr/scripts/glass-theme.sh"
PRESET_FILE="$HOME/.cache/wal/.preset"
OVERRIDE_FILE="$HOME/.cache/wal/.theme-override"
AUTO_MODE_FILE="$HOME/.cache/wal/.theme-auto-mode"
PID_FILE="$HOME/.cache/.theme-auto.pid"

[ -f "$CONF" ] && source "$CONF"

AUTO_THEME_TYPE="${AUTO_THEME_TYPE:-glass}"

# Converte HH:MM em minutos desde meia-noite
to_min() { IFS=: read h m <<< "$1"; echo $(( 10#$h * 60 + 10#$m )); }

has_active_wallpaper() {
    if command -v awww >/dev/null 2>&1 && awww query 2>/dev/null | grep -q 'displaying: image:'; then
        return 0
    fi
    if command -v swww >/dev/null 2>&1 && swww query 2>/dev/null | grep -q 'image:'; then
        return 0
    fi
    local last_w; last_w=$(cat "$HOME/.cache/wal/wal" 2>/dev/null || echo "")
    [ -n "$last_w" ] && [ -f "$last_w" ] && return 0
    return 1
}

update_settings_ini() {
    local theme="$1"
    for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
        [ -f "$ini" ] && sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$theme/" "$ini"
    done
}

update_filter() {
    local now="$1" fstart="$2" fend="$3"
    local filter_on
    if (( fstart > fend )); then
        filter_on=$(( now >= fstart || now < fend ))
    else
        filter_on=$(( now >= fstart && now < fend ))
    fi

    if (( filter_on )); then
        hyprshade on orange-filter 2>/dev/null || true
    else
        hyprshade off 2>/dev/null || true
    fi
}

apply_scheduled_theme() {
    local opt="${1:-}"
    local now light dark fstart fend
    now=$(to_min "$(date +%H:%M)")
    light=$(to_min "$LIGHT_START")
    dark=$(to_min "$DARK_START")
    fstart=$(to_min "$FILTER_START")
    fend=$(to_min "$FILTER_END")

    # Se cruzou o marco de horário de troca (06:00 ou 18:00), limpa override manual
    if [ -f "$OVERRIDE_FILE" ]; then
        if (( now == light || now == dark )); then
            rm -f "$OVERRIDE_FILE"
        fi
    fi

    local override
    override=$(cat "$OVERRIDE_FILE" 2>/dev/null || echo "")

    local period
    if (( now >= light && now < dark )); then
        period="light"
    else
        period="dark"
    fi

    local target_mode
    if [ -n "$override" ]; then
        target_mode="$override"
    elif [ "$AUTO_THEME_TYPE" = "glass" ]; then
        target_mode="glass-$period"
    else
        target_mode="$period"
    fi

    local current_applied
    current_applied=$(cat "$AUTO_MODE_FILE" 2>/dev/null || echo "")

    # Se já está aplicado e não é forçado, apenas atualiza filtro
    if [ "$target_mode" = "$current_applied" ] && [ "$opt" != "--force" ] && [ "$opt" != "--preserve-wallpaper" ]; then
        update_filter "$now" "$fstart" "$fend"
        return 0
    fi

    mkdir -p "$HOME/.cache/wal"
    echo "$target_mode" > "$AUTO_MODE_FILE"

    # Deve alterar o wallpaper?
    # Se --preserve-wallpaper foi passado e já temos um wallpaper ativo, não troca.
    local should_set_wall=true
    if [ "$opt" = "--preserve-wallpaper" ] && has_active_wallpaper; then
        should_set_wall=false
    fi

    case "$target_mode" in
        glass-light)
            mkdir -p "$(dirname "$PRESET_FILE")"
            echo "$LIGHT_PRESET" > "$PRESET_FILE"
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            gsettings set org.gnome.desktop.interface gtk-theme "$LIGHT_GTK_THEME"
            update_settings_ini "$LIGHT_GTK_THEME"
            sleep 0.15
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            if [ "$should_set_wall" = true ]; then
                waypaper --wallpaper "$WALLPAPER_DIR/$LIGHT_WALLPAPER" 2>/dev/null || true
            fi
            "$GLASS_SCRIPT" on light
            notify-send "🔮 Glass Auto" "Modo Glass Claro ativado (06:00 - 18:00)" -i weather-clear 2>/dev/null || true
            ;;
        glass-dark)
            mkdir -p "$(dirname "$PRESET_FILE")"
            echo "$DARK_PRESET" > "$PRESET_FILE"
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            gsettings set org.gnome.desktop.interface gtk-theme "$DARK_GTK_THEME"
            update_settings_ini "$DARK_GTK_THEME"
            sleep 0.15
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            if [ "$should_set_wall" = true ]; then
                waypaper --wallpaper "$WALLPAPER_DIR/$DARK_WALLPAPER" 2>/dev/null || true
            fi
            "$GLASS_SCRIPT" on dark
            notify-send "🔮 Glass Auto" "Modo Glass Escuro ativado (18:00 - 06:00)" -i weather-clear-night 2>/dev/null || true
            ;;
        light)
            "$GLASS_SCRIPT" off 2>/dev/null || true
            mkdir -p "$(dirname "$PRESET_FILE")"
            echo "$LIGHT_PRESET" > "$PRESET_FILE"
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            gsettings set org.gnome.desktop.interface gtk-theme "$LIGHT_GTK_THEME"
            update_settings_ini "$LIGHT_GTK_THEME"
            sleep 0.15
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            if [ "$should_set_wall" = true ]; then
                waypaper --wallpaper "$WALLPAPER_DIR/$LIGHT_WALLPAPER" 2>/dev/null || true
            fi
            notify-send "Tema Auto" "Modo claro ativado" -i weather-clear 2>/dev/null || true
            ;;
        dark)
            "$GLASS_SCRIPT" off 2>/dev/null || true
            mkdir -p "$(dirname "$PRESET_FILE")"
            echo "$DARK_PRESET" > "$PRESET_FILE"
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            gsettings set org.gnome.desktop.interface gtk-theme "$DARK_GTK_THEME"
            update_settings_ini "$DARK_GTK_THEME"
            sleep 0.15
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            if [ "$should_set_wall" = true ]; then
                waypaper --wallpaper "$WALLPAPER_DIR/$DARK_WALLPAPER" 2>/dev/null || true
            fi
            notify-send "Tema Auto" "Modo escuro ativado" -i weather-clear-night 2>/dev/null || true
            ;;
    esac

    update_filter "$now" "$fstart" "$fend"
}

run_daemon() {
    echo "$$" > "$PID_FILE"
    trap 'rm -f "$PID_FILE"; exit 0' SIGTERM SIGINT EXIT

    # No boot inicial, preserva o wallpaper já restaurado pelo waypaper --restore
    apply_scheduled_theme --preserve-wallpaper

    while true; do
        sleep 30
        apply_scheduled_theme
    done
}

# Aguarda daemon de wallpaper estar pronto se for boot inicial
for i in $(seq 1 20); do
    (awww query >/dev/null 2>&1 || swww query >/dev/null 2>&1) && break
    sleep 0.5
done

case "${1:-}" in
    --daemon|-d|--loop)
        if [ -f "$PID_FILE" ]; then
            old_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
            if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
                kill "$old_pid" 2>/dev/null || true
                sleep 0.2
            fi
        fi
        run_daemon
        ;;
    --force|-f)
        apply_scheduled_theme --force
        ;;
    --preserve-wallpaper)
        apply_scheduled_theme --preserve-wallpaper
        ;;
    *)
        apply_scheduled_theme
        ;;
esac
