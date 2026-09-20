#!/bin/sh

handle() {
  case $1 in
    monitoradded*HDMI*)
      sleep 0.5
      wall=$(cat "$HOME/.cache/wal/wal" 2>/dev/null) && [ -f "$wall" ] && {
        if command -v awww >/dev/null 2>&1; then
          awww img "$wall" --transition-type none
        elif command -v swww >/dev/null 2>&1; then
          swww img "$wall" --transition-type none
        fi
      }
      ;;
  esac
}

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
