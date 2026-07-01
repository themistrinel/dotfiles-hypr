#!/bin/sh
# Uso: wallpaper.sh [--random | /caminho/imagem]
# Sem argumento: usa ~/.dotfiles/wallpaper/default se existir, senão aleatório

WALLDIR="$(cd "$(dirname "$0")/.." && pwd)/wallpaper"
DEFAULT="$WALLDIR/default"

case "$1" in
    --random)
        feh --no-fehbg --bg-fill --randomize "$WALLDIR/" ;;
    "")
        if [ -f "$DEFAULT" ] || { [ -d "$DEFAULT" ] && [ "$(ls -A "$DEFAULT" 2>/dev/null)" ]; }; then
            feh --no-fehbg --bg-fill --randomize "$DEFAULT"
        else
            feh --no-fehbg --bg-fill --randomize "$WALLDIR/"
        fi ;;
    *)
        feh --no-fehbg --bg-fill "$1" ;;
esac
