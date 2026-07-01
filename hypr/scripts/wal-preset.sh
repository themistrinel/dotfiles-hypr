#!/usr/bin/env bash

PRESET_FILE="$HOME/.cache/wal/.preset"
PRESETS="dark\nsoft\nlight\nlight-vivid\nearthy\nmuted\ncolorz\nmono"

chosen=$(echo -e "$PRESETS" | rofi -dmenu -p "Pywal Preset" -i)
[ -z "$chosen" ] && exit 0

mkdir -p "$(dirname "$PRESET_FILE")"
echo "$chosen" > "$PRESET_FILE"

notify-send "Pywal Preset" "Preset '$chosen' saved. Change wallpaper to apply." -t 3000

# Re-apply immediately using last wallpaper if available
LAST_WALL=$(cat "$HOME/.cache/wal/wal" 2>/dev/null)
[ -n "$LAST_WALL" ] && "$HOME/.config/waypaper/scripts/post_change.sh" "$LAST_WALL"
