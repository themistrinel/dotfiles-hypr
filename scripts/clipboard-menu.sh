#!/bin/sh
# Abre rofi com histórico do clipboard e cola a seleção
export DISPLAY="${DISPLAY:-:0}"
HIST="$HOME/.cache/clipboard-history"

[ -f "$HIST" ] || exit 1

CHOICE=$(rofi -dmenu -p "clipboard" -theme ~/.config/rofi/config.rasi < "$HIST")

[ -z "$CHOICE" ] && exit 0

# Restaura newlines e copia para clipboard
printf '%s' "$CHOICE" | tr '␤' '\n' | xclip -selection clipboard

# Cola na janela focada
xdotool key --clearmodifiers ctrl+v
