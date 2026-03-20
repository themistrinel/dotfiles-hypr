#!/usr/bin/env bash

RECORDINGS_DIR="$HOME/Videos/Recordings"
PID_FILE="/tmp/screen-record.pid"
PID_MIC_FILE="/tmp/screen-record-mic.pid"
LOG_FILE="/tmp/screen-record.log"
FILE_FILE="/tmp/screen-record.file"

mkdir -p "$RECORDINGS_DIR"

# --- Parar gravação ---
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    PID_MIC=$(cat "$PID_MIC_FILE" 2>/dev/null)
    BASE_FILE=$(cat "$FILE_FILE" 2>/dev/null)

    notify-send "Screen Recording" "Finalizando, aguarde..." -t 3000

    kill -INT "$PID" 2>/dev/null
    [ -n "$PID_MIC" ] && kill -INT "$PID_MIC" 2>/dev/null

    # Aguarda ambos terminarem
    while kill -0 "$PID" 2>/dev/null; do sleep 0.2; done
    [ -n "$PID_MIC" ] && while kill -0 "$PID_MIC" 2>/dev/null; do sleep 0.2; done

    rm -f "$PID_FILE" "$PID_MIC_FILE" "$FILE_FILE"

    VIDEO_FILE="${BASE_FILE}_video.mkv"
    MIC_FILE="${BASE_FILE}_mic.wav"
    FINAL_FILE="${BASE_FILE}.mkv"

    if [ -f "$VIDEO_FILE" ] && [ -s "$MIC_FILE" ]; then
        # Mescla vídeo+sistema com mic em faixas separadas
        ffmpeg -i "$VIDEO_FILE" -i "$MIC_FILE" \
            -map 0:v -map 0:a -map 1:a \
            -metadata:s:a:0 title="Sistema" \
            -metadata:s:a:1 title="Microfone" \
            -c copy "$FINAL_FILE" 2>>"$LOG_FILE"

        if [ -f "$FINAL_FILE" ]; then
            rm -f "$VIDEO_FILE" "$MIC_FILE"
            SIZE=$(du -h "$FINAL_FILE" | cut -f1)
            notify-send "Screen Recording" "✓ Salvo!\n$FINAL_FILE\nTamanho: $SIZE" -t 8000
        else
            notify-send "Screen Recording" "✗ Erro ao mesclar!\nLog: $LOG_FILE" -u critical -t 8000
        fi
    elif [ -f "$VIDEO_FILE" ]; then
        mv "$VIDEO_FILE" "$FINAL_FILE"
        SIZE=$(du -h "$FINAL_FILE" | cut -f1)
        notify-send "Screen Recording" "✓ Salvo (sem mic)\n$FINAL_FILE\nTamanho: $SIZE" -t 8000
    else
        notify-send "Screen Recording" "✗ Nenhum arquivo gerado!\nLog: $LOG_FILE" -u critical -t 8000
    fi

    exit 0
fi

# --- Verificar dependências ---
for dep in wf-recorder ffmpeg pw-record pactl; do
    if ! command -v "$dep" &>/dev/null; then
        notify-send "Screen Recording Error" "$dep não instalado" -u critical
        exit 1
    fi
done

# --- Fontes de áudio ---
SYSTEM_AUDIO=$(pactl get-default-sink).monitor
MIC_SOURCE=$(pactl list short sources | grep -v monitor | grep "alsa_input" | awk 'NR==1{print $2}')

if [ -z "$MIC_SOURCE" ]; then
    notify-send "Screen Recording" "Mic não encontrado, gravando só sistema..." -t 3000
fi

BASE_FILE="$RECORDINGS_DIR/recording_$(date +%Y-%m-%d_%H-%M-%S)"
VIDEO_FILE="${BASE_FILE}_video.mkv"
MIC_FILE="${BASE_FILE}_mic.wav"

echo "$BASE_FILE" > "$FILE_FILE"

# Inicia wf-recorder (vídeo + sistema)
wf-recorder -a="$SYSTEM_AUDIO" -f "$VIDEO_FILE" 2>"$LOG_FILE" &
echo $! > "$PID_FILE"

# Inicia pw-record (microfone)
if [ -n "$MIC_SOURCE" ]; then
    pw-record --target "$MIC_SOURCE" "$MIC_FILE" 2>>"$LOG_FILE" &
    echo $! > "$PID_MIC_FILE"
fi

notify-send "Screen Recording" "Gravando...\nPressione Super+Shift+R para parar" -t 4000
