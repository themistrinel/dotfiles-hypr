#!/usr/bin/env bash

RECORDINGS_DIR="$HOME/Videos/Recordings"
PID_FILE="/tmp/screen-record-area.pid"
LOG_FILE="/tmp/screen-record-area.log"
FILE_FILE="/tmp/screen-record-area.file"

mkdir -p "$RECORDINGS_DIR"

# --- Parar gravação ---
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")

    notify-send "Screen Recording" "Finalizando, aguarde..." -t 3000

    kill -INT "$PID" 2>/dev/null

    while kill -0 "$PID" 2>/dev/null; do sleep 0.2; done

    rm -f "$PID_FILE"

    FINAL_FILE=$(cat "$FILE_FILE" 2>/dev/null)
    rm -f "$FILE_FILE"

    if [ -f "$FINAL_FILE" ] && [ -s "$FINAL_FILE" ]; then
        SIZE=$(du -h "$FINAL_FILE" | cut -f1)
        notify-send "Screen Recording" "✓ Salvo!\n$FINAL_FILE\nTamanho: $SIZE" -t 8000
    else
        notify-send "Screen Recording" "✗ Nenhum arquivo gerado!\nLog: $LOG_FILE" -u critical -t 8000
    fi

    exit 0
fi

# --- Verificar dependências ---
for dep in wf-recorder slurp; do
    if ! command -v "$dep" &>/dev/null; then
        notify-send "Screen Recording Error" "$dep não instalado" -u critical
        exit 1
    fi
done

# --- Selecionar área com slurp ---
AREA=$(slurp 2>/dev/null)

if [ -z "$AREA" ]; then
    notify-send "Screen Recording" "Seleção cancelada." -t 2000
    exit 0
fi

FINAL_FILE="$RECORDINGS_DIR/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
echo "$FINAL_FILE" > "$FILE_FILE"

# Inicia wf-recorder na área selecionada
wf-recorder -g "$AREA" -f "$FINAL_FILE" 2>"$LOG_FILE" &
echo $! > "$PID_FILE"

notify-send "Screen Recording" "🔴 Gravando área selecionada...\nPressione Super+Ctrl+R para parar" -t 4000
