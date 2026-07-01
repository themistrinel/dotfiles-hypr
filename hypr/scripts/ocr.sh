#!/usr/bin/env bash

# OCR rápido usando Tesseract

SCREENSHOT="/tmp/ocr/screenshot.png"
mkdir -p /tmp/ocr

for cmd in grim slurp wl-copy tesseract; do
    if ! command -v "$cmd" &>/dev/null; then
        notify-send "OCR" "Dependência não encontrada: $cmd" -u critical
        exit 1
    fi
done

grim -g "$(slurp)" "$SCREENSHOT" 2>/dev/null || exit 1

TEXT=$(tesseract "$SCREENSHOT" stdout -l por+eng --psm 3 --oem 3 2>/dev/null | sed '/^$/d')

rm -f "$SCREENSHOT"

if [ -z "$TEXT" ]; then
    notify-send "OCR Rápido" "Nenhum texto detectado" -u normal
    exit 1
fi

echo "$TEXT" | wl-copy

PREVIEW=$(echo "$TEXT" | head -c 80)
[ ${#TEXT} -gt 80 ] && PREVIEW="${PREVIEW}..."
notify-send "OCR Rápido ⚡" "$PREVIEW" -t 3000
