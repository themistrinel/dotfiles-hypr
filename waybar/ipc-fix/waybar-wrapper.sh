#!/usr/bin/env bash
# Wrapper for Waybar to intercept and translate Hyprland IPC dispatch calls
# on Hyprland 0.55+ (which expects Lua syntax in Lua-config mode).

LIB="$HOME/.local/lib/waybar-hypr-ipc.so"
if [ -f "$LIB" ]; then
    export LD_PRELOAD="$LIB${LD_PRELOAD:+:$LD_PRELOAD}"
fi

# Locate the actual system waybar binary (skipping this wrapper)
SELF="$(readlink -f "$0" 2>/dev/null || echo "$0")"
SYSTEM_WAYBAR=$(type -a -p waybar 2>/dev/null | while read -r p; do
    rp="$(readlink -f "$p" 2>/dev/null || echo "$p")"
    if [ "$rp" != "$SELF" ] && [ -x "$p" ]; then
        echo "$p"
        break
    fi
done)

if [ -z "$SYSTEM_WAYBAR" ]; then
    if [ -x "/usr/sbin/waybar" ]; then
        SYSTEM_WAYBAR="/usr/sbin/waybar"
    elif [ -x "/usr/bin/waybar" ]; then
        SYSTEM_WAYBAR="/usr/bin/waybar"
    else
        echo "Error: system waybar executable not found" >&2
        exit 1
    fi
fi

exec "$SYSTEM_WAYBAR" "$@"
