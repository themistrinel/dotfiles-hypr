#!/usr/bin/env bash

# OCR preciso usando daemon EasyOCR

SCREENSHOT="/tmp/ocr/screenshot_precise.png"
INPUT_FILE="/tmp/ocr/daemon.input"
OUTPUT_FILE="/tmp/ocr/daemon.output"
PID_FILE="/tmp/ocr/daemon.pid"

mkdir -p /tmp/ocr

for cmd in grim slurp wl-copy; do
    if ! command -v "$cmd" &>/dev/null; then
        notify-send "OCR Preciso" "Dependência não encontrada: $cmd" -u critical
        exit 1
    fi
done

if [ ! -f "$PID_FILE" ] || ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    notify-send "OCR Preciso" "Daemon não está rodando\nInicie com Super+Alt+O" -u critical
    exit 1
fi

grim -g "$(slurp)" "$SCREENSHOT" 2>/dev/null || exit 1

# Envia para o daemon via arquivo
rm -f "$OUTPUT_FILE"
echo "$SCREENSHOT" > "$INPUT_FILE"

# Aguarda resposta (max 15s)
for i in $(seq 1 150); do
    [ -f "$OUTPUT_FILE" ] && break
    sleep 0.1
done

TEXT=$(cat "$OUTPUT_FILE" 2>/dev/null)
rm -f "$SCREENSHOT" "$OUTPUT_FILE"

if [ -z "$TEXT" ] || [[ "$TEXT" == ERROR:* ]]; then
    notify-send "OCR Preciso" "Nenhum texto detectado" -u normal
    exit 1
fi

echo "$TEXT" | wl-copy

PREVIEW=$(echo "$TEXT" | head -c 80)
[ ${#TEXT} -gt 80 ] && PREVIEW="${PREVIEW}..."
notify-send "OCR Preciso 🎯" "$PREVIEW" -t 3000
