#!/bin/sh
# Mantém o clipboard-daemon rodando — reinicia se morrer
export DISPLAY="${DISPLAY:-:0}"
while true; do
    ~/.dotfiles/scripts/clipboard-daemon.sh
    sleep 1
done
