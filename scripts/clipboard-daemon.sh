#!/bin/sh
# Clipboard history daemon — salva últimas 50 entradas em ~/.cache/clipboard-history
export DISPLAY="${DISPLAY:-:0}"
HIST="$HOME/.cache/clipboard-history"
MAX=50

mkdir -p "$(dirname "$HIST")"
[ -f "$HIST" ] || touch "$HIST"

LAST=""
while true; do
    # Tenta clipboard (Ctrl+C), depois primary (seleção com mouse)
    CLIP=$(xclip -selection clipboard -o 2>/dev/null)
    [ -z "$CLIP" ] && CLIP=$(xclip -selection primary -o 2>/dev/null)

    if [ -n "$CLIP" ] && [ "$CLIP" != "$LAST" ]; then
        LAST="$CLIP"
        ENTRY=$(printf '%s' "$CLIP" | tr '\n' '␤')
        TMP=$(grep -vxF "$ENTRY" "$HIST")
        printf '%s\n%s' "$ENTRY" "$TMP" | head -n "$MAX" > "$HIST"
    fi
    sleep 0.5
done
