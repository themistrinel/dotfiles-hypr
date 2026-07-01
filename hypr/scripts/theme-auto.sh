#!/usr/bin/env bash
# theme-auto.sh — aplica wallpaper, preset pywal e filtro conforme horário

CONF="$HOME/.dotfiles/hypr/scripts/theme-schedule.conf"
POST_CHANGE="$HOME/.config/waypaper/scripts/post_change.sh"
PRESET_FILE="$HOME/.cache/wal/.preset"

source "$CONF"

# Aguarda o swww-daemon estar pronto
for i in $(seq 1 20); do
    swww query 2>/dev/null && break
    sleep 0.5
done

OVERRIDE_FILE="$HOME/.cache/wal/.theme-override"

# Converte HH:MM em minutos desde meia-noite
to_min() { IFS=: read h m <<< "$1"; echo $(( 10#$h * 60 + 10#$m )); }

now=$(to_min "$(date +%H:%M)")
light=$(to_min "$LIGHT_START")
dark=$(to_min "$DARK_START")
fstart=$(to_min "$FILTER_START")
fend=$(to_min "$FILTER_END")

# Respeita override manual (definido por theme.sh); limpa ao cruzar horário
override=$(cat "$OVERRIDE_FILE" 2>/dev/null)
if [ -n "$override" ]; then
    if (( now == light || now == dark )); then
        rm -f "$OVERRIDE_FILE"
        override=""
    fi
fi

# Determina modo: light ou dark
if (( now >= light && now < dark )); then auto_mode="light"; else auto_mode="dark"; fi
mode="${override:-$auto_mode}"

if [ "$mode" = "light" ]; then
    WALLPAPER="$WALLPAPER_DIR/$LIGHT_WALLPAPER"
    PRESET="$LIGHT_PRESET"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
else
    WALLPAPER="$WALLPAPER_DIR/$DARK_WALLPAPER"
    PRESET="$DARK_PRESET"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi

# Aplica preset e wallpaper (post_change.sh já roda pywal + reload)
mkdir -p "$(dirname "$PRESET_FILE")"
echo "$PRESET" > "$PRESET_FILE"
"$POST_CHANGE" "$WALLPAPER"

# Determina se filtro deve estar ativo (fstart até fend, cruzando meia-noite)
if (( fstart > fend )); then
    filter_on=$(( now >= fstart || now < fend ))
else
    filter_on=$(( now >= fstart && now < fend ))
fi

if (( filter_on )); then
    hyprshade on orange-filter 2>/dev/null
else
    hyprshade off 2>/dev/null
fi
