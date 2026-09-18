#!/usr/bin/env bash

# Gerencia o servidor EasyOCR (daemon)

VENV_DIR="$HOME/.venvs/ocr"
PYTHON_BIN="$VENV_DIR/bin/python"
PID_FILE="/tmp/ocr/daemon.pid"
SERVER_SCRIPT="/tmp/ocr/server.py"

mkdir -p /tmp/ocr

_write_server() {
    cat > "$SERVER_SCRIPT" << 'EOF'
import os, time

INPUT_FILE  = "/tmp/ocr/daemon.input"
OUTPUT_FILE = "/tmp/ocr/daemon.output"
READY_FILE  = "/tmp/ocr/daemon.ready"
STOP_FILE   = "/tmp/ocr/daemon.stop"

from paddleocr import PaddleOCR

# Carrega modelo uma vez (mantido em memória)
ocr = PaddleOCR(use_textline_orientation=True, lang='en')

# Sinaliza que está pronto
open(READY_FILE, 'w').close()

while not os.path.exists(STOP_FILE):
    if not os.path.exists(INPUT_FILE):
        time.sleep(0.1)
        continue

    try:
        img_path = open(INPUT_FILE).read().strip()
        os.remove(INPUT_FILE)

        result = ocr.ocr(img_path)

        lines = []
        if result and result[0]:
            items = sorted(result[0], key=lambda x: x[0][0][1])
            for item in items:
                text = item[1][0].strip()
                if text:
                    lines.append(text)

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
