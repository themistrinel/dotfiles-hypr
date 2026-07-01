#!/usr/bin/env bash
# launch.sh — wrapper para pomodoro-tasks com log e instância única
set -euo pipefail

BINARY="$(dirname "$0")/build/pomodoro-tasks"
LOGFILE="/tmp/pomodoro-tasks.log"
PIDFILE="/tmp/pomodoro.pid"

# Se já está rodando, apenas mostra a janela via SIGUSR2 (ou mata e relança)
if [[ -f "$PIDFILE" ]]; then
    PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
    if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
        echo "Instância já rodando (PID $PID) — mostrando janela..."
        # Envia sinal para mostrar a janela (o app responde SIGUSR1 com pause/resume)
        # Não há sinal de "show window" — melhor matar e relançar limpo
        # Descomente a linha abaixo se preferir reabrir:
        # kill "$PID" && sleep 0.5
        hyprctl dispatch focuswindow "class:Pomodoro" 2>/dev/null || true
        exit 0
    fi
fi

# Limpa arquivos temporários órfãos
rm -f /tmp/pomodoro-active /tmp/pomodoro.pid /tmp/pomodoro-running

echo "Iniciando pomodoro-tasks... (log: $LOGFILE)"
cd "$(dirname "$0")"
exec "$BINARY" > >(tee "$LOGFILE") 2>&1
