#!/usr/bin/env bash

# OCR usando Tesseract (português + inglês)

SCREENSHOT="/tmp/ocr/screenshot.png"

mkdir -p /tmp/ocr

for cmd in grim slurp wl-copy tesseract; do
    if ! command -v "$cmd" &>/dev/null; then
        notify-send "OCR" "Dependência não encontrada: $cmd" -u critical
        exit 1
    fi
done

grim -g "$(slurp)" "$SCREENSHOT" 2>/dev/null || exit 1

TEXT=$(tesseract "$SCREENSHOT" stdout -l por+eng 2>/dev/null)

rm -f "$SCREENSHOT"

if [ -z "$TEXT" ]; then
    notify-send "OCR" "Nenhum texto detectado" -u normal
    exit 1
fi

echo "$TEXT" | wl-copy

PREVIEW=$(echo "$TEXT" | head -c 80)
[ ${#TEXT} -gt 80 ] && PREVIEW="${PREVIEW}..."
notify-send "OCR ⚡" "$PREVIEW" -t 3000
