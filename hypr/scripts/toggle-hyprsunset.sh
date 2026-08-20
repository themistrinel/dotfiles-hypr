#!/bin/bash
# toggle-hyprsunset.sh — Liga/desliga o filtro de luz azul (hyprsunset)

TEMPERATURE=2000
PID_FILE="/tmp/hyprsunset.pid"

if pgrep -x hyprsunset > /dev/null 2>&1; then
    # Está rodando → desligar
    killall hyprsunset
    rm -f "$PID_FILE"
    notify-send "HyprSunset" "Filtro de luz azul desligado" -i display-brightness-low 2>/dev/null
else
    # Não está rodando → ligar
    hyprsunset --temperature "$TEMPERATURE" &
    echo $! > "$PID_FILE"
    notify-send "HyprSunset" "Filtro de luz azul ligado ($TEMPERATURE K)" -i display-brightness-high 2>/dev/null
fi
