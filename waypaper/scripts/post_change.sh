#!/bin/bash

# Script called by Waypaper to handle video wallpapers and color generation

WALLPAPER="$1"
TEMP_DIR="$HOME/Pictures/tmp"
FRAME_OUT="$TEMP_DIR/current_wall_frame.png"

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"

# Check if the file is a video
extension="${WALLPAPER##*.}"
is_video=false

case "$extension" in
    mp4|mkv|mov|avi|webm)
        is_video=true
        ;;
esac

set_wallpaper_img() {
    local img="$1"
    if command -v awww >/dev/null 2>&1; then
        awww img "$img" --transition-type grow --transition-pos top-right --transition-duration 2
    elif command -v swww >/dev/null 2>&1; then
        swww img "$img" --transition-type grow --transition-pos top-right --transition-duration 2
    fi
}

if [ "$is_video" = true ]; then
    # Extract the first frame as high quality image for pywal
    ffmpeg -y -i "$WALLPAPER" -frames:v 1 -q:v 2 "$FRAME_OUT" > /dev/null 2>&1
    COLOR_SOURCE="$FRAME_OUT"

    # Set the extracted frame as static wallpaper with awww/swww
    set_wallpaper_img "$FRAME_OUT"

    # Stop any previous video and start the new one
    killall mpvpaper 2>/dev/null
    # Wait a bit for it to release the surface if needed
    sleep 0.1
    # Run mpvpaper
    mpvpaper -o "no-audio loop" "*" "$WALLPAPER" &
else
    COLOR_SOURCE="$WALLPAPER"
    # Kill mpvpaper if we are switching to a static image
    killall mpvpaper 2>/dev/null
    # Apply static wallpaper
    set_wallpaper_img "$WALLPAPER"
fi

# Run pywal to generate colors (skip GTK theming)
if command -v wal >/dev/null 2>&1; then
    PRESET=$(cat "$HOME/.cache/wal/.preset" 2>/dev/null || echo "dark")
    case "$PRESET" in
        soft)   wal -i "$COLOR_SOURCE" -n -t -e --saturate 0.4 ;;
        light)  wal -i "$COLOR_SOURCE" -n -t -e --saturate 0.6 -l ;;
        light-vivid) wal -i "$COLOR_SOURCE" -n -t -e --backend colorthief --saturate 0.7 -l ;;
        earthy) wal -i "$COLOR_SOURCE" -n -t -e --backend haishoku ;;
        muted)  wal -i "$COLOR_SOURCE" -n -t -e --backend colorthief ;;
        colorz) wal -i "$COLOR_SOURCE" -n -t -e --backend colorz ;;
        mono)   wal -i "$COLOR_SOURCE" -n -t -e --saturate 0.0 ;;
        *)      wal -i "$COLOR_SOURCE" -n -t -e --saturate 0.8 ;;  # dark (default)
    esac
fi

# Reload configurations
killall -SIGUSR1 kitty 2>/dev/null
killall -SIGUSR1 wezterm 2>/dev/null

GLASS_STATE="$HOME/.cache/.glass-theme"
GLASS_SCRIPT="$HOME/.dotfiles/hypr/scripts/glass-theme.sh"

if [ -f "$GLASS_STATE" ] && [ -x "$GLASS_SCRIPT" ]; then
    # Se o modo Glass estiver ativo, recalcula o tema Glass com as cores do novo wallpaper
    "$GLASS_SCRIPT" refresh
else
    # Reload configurations padrão
    hyprctl reload

    # Aplica o CSS gerado pelo pywal diretamente no waybar
    WAYBAR_STYLE="$HOME/.config/waybar/style.css"
    WAL_CSS="$HOME/.cache/wal/colors-waybar.css"
    if [ -f "$WAL_CSS" ]; then
        cp "$WAL_CSS" "$WAYBAR_STYLE"
    fi

    # Recarrega o waybar de forma segura (SIGUSR2 recarrega CSS/config sem duplicar processo)
    if pgrep -x waybar >/dev/null; then
        killall -SIGUSR2 waybar 2>/dev/null || true
    else
        setsid waybar >/dev/null 2>&1 &
    fi
fi

# Update the default wallpaper for the current theme in theme-schedule.conf
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

get_current_theme() {
    local ov auto_mode
    ov=$(cat "$HOME/.cache/wal/.theme-override" 2>/dev/null || echo "")
    if [ -n "$ov" ]; then
        echo "$ov"
        return
    fi
    auto_mode=$(cat "$HOME/.cache/wal/.theme-auto-mode" 2>/dev/null || echo "")
    if [ -n "$auto_mode" ]; then
        echo "$auto_mode"
        return
    fi
    local conf="$HOME/.dotfiles/hypr/scripts/theme-schedule.conf"
    local l_start="06:00" d_start="18:00"
    if [ -f "$conf" ]; then
        source "$conf" 2>/dev/null || true
        l_start="${LIGHT_START:-06:00}"
        d_start="${DARK_START:-18:00}"
    fi
    to_min() { IFS=: read h m <<< "$1"; echo $(( 10#$h * 60 + 10#$m )); }
    local now; now=$(to_min "$(date +%H:%M)")
    local light; light=$(to_min "$l_start")
    local dark; dark=$(to_min "$d_start")
    if (( now >= light && now < dark )); then
        echo "light"
    else
        echo "dark"
    fi
}

current_theme=$(get_current_theme)
wallpaper_name=$(basename "$WALLPAPER")

confs=("$DOTFILES_DIR/hypr/scripts/theme-schedule.conf" "$HOME/.dotfiles/hypr/scripts/theme-schedule.conf")
if command -v git >/dev/null 2>&1; then
    while IFS= read -r wt; do
        wt_path=$(awk '{print $1}' <<< "$wt")
        [ -n "$wt_path" ] && [ -d "$wt_path" ] && confs+=("$wt_path/hypr/scripts/theme-schedule.conf")
    done < <(git -C "$DOTFILES_DIR" worktree list 2>/dev/null || true)
fi

for conf in "${confs[@]}"; do
    if [ -f "$conf" ]; then
        if [ "$current_theme" = "light" ] || [ "$current_theme" = "glass-light" ]; then
            sed -i "s|^LIGHT_WALLPAPER=.*|LIGHT_WALLPAPER=\"$wallpaper_name\"|" "$conf"
        elif [ "$current_theme" = "dark" ] || [ "$current_theme" = "glass-dark" ]; then
            sed -i "s|^DARK_WALLPAPER=.*|DARK_WALLPAPER=\"$wallpaper_name\"|" "$conf"
        fi
    fi
done
