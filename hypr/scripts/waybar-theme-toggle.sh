#!/usr/bin/env bash

DOTFILES_DIR="$HOME/.dotfiles"
WAYBAR_DIR="$DOTFILES_DIR/waybar"
WAL_CACHE_DIR="$HOME/.cache/wal"
STYLE_LINK="$WAYBAR_DIR/style.css"
FIXED_STYLE="$WAYBAR_DIR/style-fixed.css"
PYWAL_STYLE="$WAL_CACHE_DIR/colors-waybar.css"
STATE_FILE="$WAYBAR_DIR/.theme-mode"

reload_waybar() {
    if pgrep -x waybar > /dev/null; then
        pkill -USR2 waybar
    fi
}

get_current_mode() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "fixed"
    fi
}

apply_fixed() {
    cp "$FIXED_STYLE" "$STYLE_LINK"
    echo "fixed" > "$STATE_FILE"
    echo "[waybar-theme] Applied fixed theme"
    reload_waybar
}

apply_pywal() {
    if [ -f "$PYWAL_STYLE" ]; then
        cp "$PYWAL_STYLE" "$STYLE_LINK"
        echo "pywal" > "$STATE_FILE"
        echo "[waybar-theme] Applied pywal theme"
        reload_waybar
    else
        echo "[waybar-theme] No pywal colors found. Set a wallpaper first with 'wal -i <image>'"
        exit 1
    fi
}

case "${1:-toggle}" in
    fixed)
        apply_fixed
        ;;
    pywal)
        apply_pywal
        ;;
    toggle)
        current_mode=$(get_current_mode)
        if [ "$current_mode" = "pywal" ]; then
            apply_fixed
        else
            apply_pywal
        fi
        ;;
    current)
        get_current_mode
        ;;
    *)
        echo "Usage: $0 [toggle|fixed|pywal|current]"
        exit 1
        ;;
esac
