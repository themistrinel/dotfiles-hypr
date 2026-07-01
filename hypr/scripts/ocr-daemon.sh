#!/usr/bin/env bash

# Gerencia o servidor EasyOCR (daemon)

VENV_DIR="$HOME/.local/share/ocr-venv"
PYTHON_BIN="$VENV_DIR/bin/python"
PID_FILE="/tmp/ocr/daemon.pid"
SERVER_SCRIPT="/tmp/ocr/server.py"

mkdir -p /tmp/ocr

_write_server() {
    cat > "$SERVER_SCRIPT" << 'EOF'
import os, sys, time

INPUT_FILE  = "/tmp/ocr/daemon.input"
OUTPUT_FILE = "/tmp/ocr/daemon.output"
READY_FILE  = "/tmp/ocr/daemon.ready"
STOP_FILE   = "/tmp/ocr/daemon.stop"

import easyocr
from PIL import Image
import numpy as np

reader = easyocr.Reader(['pt', 'en'], gpu=False, verbose=False)

# Signal ready
open(READY_FILE, 'w').close()

while not os.path.exists(STOP_FILE):
    if not os.path.exists(INPUT_FILE):
        time.sleep(0.1)
        continue

    try:
        img_path = open(INPUT_FILE).read().strip()
        os.remove(INPUT_FILE)

        img = Image.open(img_path)
        img_w, img_h = img.size

        slice_height = 800
        overlap = 100
        slices = []
        if img_h > slice_height:
            y = 0
            while y < img_h:
                y_end = min(y + slice_height, img_h)
                slices.append((y, np.array(img.crop((0, y, img_w, y_end)))))
                if y_end == img_h:
                    break
                y += slice_height - overlap
        else:
            slices = [(0, np.array(img))]

        all_results = []
        for y_offset, arr in slices:
            res = reader.readtext(arr, detail=1, text_threshold=0.5, low_text=0.3)
            for bbox, text, conf in res:
                adjusted = [[p[0], p[1] + y_offset] for p in bbox]
                all_results.append((adjusted, text))

        # Deduplica overlap
        seen, deduped = set(), []
        for bbox, text in all_results:
            key = (text.strip().lower(), round(bbox[0][1] / 15))
            if key not in seen:
                seen.add(key)
                deduped.append((bbox, text))

        result_sorted = sorted(deduped, key=lambda x: (int(x[0][0][1] / 10), x[0][0][0]))

        lines, current_line, current_y = [], [], None
        for bbox, text in result_sorted:
            y = bbox[0][1]
            if current_y is None or abs(y - current_y) < 15:
                current_line.append(text)
                current_y = y if current_y is None else current_y
            else:
                lines.append(' '.join(current_line))
                current_line, current_y = [text], y
        if current_line:
            lines.append(' '.join(current_line))

        with open(OUTPUT_FILE, 'w') as f:
            f.write('\n'.join(lines))

    except Exception as e:
        with open(OUTPUT_FILE, 'w') as f:
            f.write(f"ERROR: {e}")
EOF
}

start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        notify-send "OCR Daemon" "Já está rodando (PID $(cat "$PID_FILE"))" -u normal
        exit 0
    fi

    if [ ! -f "$PYTHON_BIN" ]; then
        notify-send "OCR Daemon" "Virtualenv não encontrado\nExecute: install-ocr-deps.sh" -u critical
        exit 1
    fi

    notify-send "OCR Daemon" "Iniciando... (carregando modelo)" -t 4000

    rm -f /tmp/ocr/daemon.ready /tmp/ocr/daemon.stop
    _write_server
    "$PYTHON_BIN" "$SERVER_SCRIPT" &
    echo $! > "$PID_FILE"

    for i in $(seq 1 30); do
        [ -f /tmp/ocr/daemon.ready ] && break
        sleep 1
    done

    if [ -f /tmp/ocr/daemon.ready ]; then
        notify-send "OCR Daemon" "✅ Pronto! (PID $(cat "$PID_FILE"))" -t 3000
    else
        notify-send "OCR Daemon" "❌ Falha ao iniciar" -u critical
        stop
    fi
}

stop() {
    touch /tmp/ocr/daemon.stop
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE" /tmp/ocr/daemon.ready /tmp/ocr/daemon.stop
        notify-send "OCR Daemon" "🛑 Parado" -t 2000
    else
        notify-send "OCR Daemon" "Não está rodando" -u normal
    fi
}

status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        notify-send "OCR Daemon" "✅ Rodando (PID $(cat "$PID_FILE"))" -t 2000
    else
        notify-send "OCR Daemon" "🛑 Parado" -t 2000
    fi
}

case "${1:-}" in
    start)  start ;;
    stop)   stop ;;
    status) status ;;
    toggle)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            stop
        else
            start
        fi
        ;;
    *)
        echo "Uso: $0 {start|stop|status|toggle}"
        exit 1
        ;;
esac
