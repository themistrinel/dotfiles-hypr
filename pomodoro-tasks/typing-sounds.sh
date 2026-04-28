#!/bin/bash
# typing-sounds — start | stop | toggle | status | reload
DAEMON="$(dirname "$0")/build/typing-sounds"
PID_FILE="$HOME/.cache/typing-sounds.pid"

pid() { cat "$PID_FILE" 2>/dev/null; }
running() { local p=$(pid); [ -n "$p" ] && kill -0 "$p" 2>/dev/null; }

case "${1:-start}" in
  start)
    running && echo "already running ($(pid))" && exit 0
    "$DAEMON" &
    echo "started (PID $!)"
    ;;
  stop)
    running && kill "$(pid)" && echo "stopped" || echo "not running"
    ;;
  toggle)
    running && kill -SIGUSR1 "$(pid)" && echo "toggled" || echo "not running"
    ;;
  reload)
    running && kill -SIGUSR2 "$(pid)" && echo "config reloaded" || echo "not running"
    ;;
  status)
    running && echo "running ($(pid))" || echo "stopped"
    ;;
  restart)
    "$0" stop; sleep 0.2; "$0" start
    ;;
esac
