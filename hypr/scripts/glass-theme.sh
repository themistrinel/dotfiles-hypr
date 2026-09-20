#!/usr/bin/env bash
# glass-theme.sh — Glass mode toggle for Hyprland
# Usage: glass-theme.sh [on [dark|light]|off|refresh [dark|light]|toggle [dark|light]|status]
#
# Glass mode applies:
#   - Real transparency on all surfaces
#   - Enhanced compositor blur
#   - Translucent Waybar, Rofi, Foot, Kitty
#   - Colors derived from current wallpaper via pywal (with dark/light variants)
#
# This changes the RENDERING of the current theme and adapts contrast.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -d "$DOTFILES/hypr" ] || DOTFILES="$HOME/.dotfiles"

WAL_CACHE="$HOME/.cache/wal"
STATE="$HOME/.cache/.glass-theme"
VARIANT_FILE="$HOME/.cache/.glass-theme-variant"
BACKUP_DIR="$HOME/.cache/.glass-backup"

# ── Helpers ────────────────────────────────────────────────────

read_wal_colors() {
    local colors_file="$WAL_CACHE/colors"
    if [ ! -f "$colors_file" ]; then
        echo "[glass] No pywal colors found. Run 'wal -i <wallpaper>' first." >&2
        return 1
    fi
    mapfile -t C < "$colors_file"
}

hex_to_rgb() {
    local hex="${1#\#}"
    printf "%d, %d, %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

reload_waybar_safe() {
    if pgrep -x waybar >/dev/null; then
        killall -SIGUSR2 waybar 2>/dev/null || true
    else
        setsid waybar >/dev/null 2>&1 &
    fi
}

is_light_color() {
    local hex="${1#\#}"
    local r=$(( 16#${hex:0:2} ))
    local g=$(( 16#${hex:2:2} ))
    local b=$(( 16#${hex:4:2} ))
    local lum=$(( (r * 299 + g * 587 + b * 114) / 1000 ))
    (( lum >= 128 ))
}

get_variant() {
    local requested="${1:-}"
    if [ -n "$requested" ]; then
        echo "$requested"
    elif [ -f "$VARIANT_FILE" ]; then
        cat "$VARIANT_FILE" 2>/dev/null || echo "dark"
    else
        local ov
        ov=$(cat "$HOME/.cache/wal/.theme-override" 2>/dev/null || echo "")
        if [ "$ov" = "light" ] || [ "$ov" = "glass-light" ]; then
            echo "light"
        else
            echo "dark"
        fi
    fi
}

# ── Generate Glass Waybar CSS ──────────────────────────────────

generate_waybar_glass() {
    local variant="${1:-dark}"
    read_wal_colors || return 1

    local bg_hex="${C[0]}"
    local fg_hex="${C[7]}"

    local c1="${C[1]}"
    local c4="${C[4]}"
    local c4_rgb; c4_rgb=$(hex_to_rgb "${C[4]}")
    local c5="${C[5]}"
    local c5_rgb; c5_rgb=$(hex_to_rgb "${C[5]}")
    local c6="${C[6]}"
    local c6_rgb; c6_rgb=$(hex_to_rgb "${C[6]}")
    local c8="${C[8]}"

    local module_bg ws_inactive_fg ws_active_fg ws_active_bg ws_active_border
    local ws_focused_fg ws_focused_bg ws_focused_border ws_hover_bg ws_hover_fg ws_hover_border
    local ws_urgent_bg ws_urgent_fg pomodoro_fg pomodoro_work pomodoro_break pomodoro_paused

    if [ "$variant" = "light" ]; then
        if ! is_light_color "$bg_hex"; then
            bg_hex="#f0f3f6"
        fi
        if is_light_color "$fg_hex"; then
            fg_hex="#1a1c23"
        fi
        local bg_rgb; bg_rgb=$(hex_to_rgb "$bg_hex")
        local fg="$fg_hex"
        local fg_rgb; fg_rgb=$(hex_to_rgb "$fg_hex")

        module_bg="rgba($bg_rgb, 0.58)"
        ws_inactive_fg="rgba($fg_rgb, 0.70)"
        ws_active_fg="#0f1117"
        ws_active_bg="rgba($c6_rgb, 0.35)"
        ws_active_border="rgba(0, 0, 0, 0.18)"
        ws_focused_fg="#0f1117"
        ws_focused_bg="rgba($c6_rgb, 0.22)"
        ws_focused_border="rgba(0, 0, 0, 0.12)"
        ws_hover_bg="rgba(0, 0, 0, 0.08)"
        ws_hover_fg="#0f1117"
        ws_hover_border="rgba(0, 0, 0, 0.16)"
        ws_urgent_bg="rgba(225, 45, 55, 0.80)"
        ws_urgent_fg="#ffffff"
        pomodoro_fg="rgba(55, 60, 75, 0.85)"
        pomodoro_work="rgba(195, 30, 65, 0.95)"
        pomodoro_break="rgba(30, 75, 185, 0.95)"
        pomodoro_paused="rgba(100, 105, 115, 0.75)"
    else
        if is_light_color "$bg_hex"; then
            bg_hex="#14151b"
        fi
        if ! is_light_color "$fg_hex"; then
            fg_hex="#e4e5eb"
        fi
        local bg_rgb; bg_rgb=$(hex_to_rgb "$bg_hex")
        local fg="$fg_hex"
        local fg_rgb; fg_rgb=$(hex_to_rgb "$fg_hex")

        module_bg="rgba($bg_rgb, 0.42)"
        ws_inactive_fg="rgba($fg_rgb, 0.75)"
        ws_active_fg="#ffffff"
        ws_active_bg="rgba($c6_rgb, 0.38)"
        ws_active_border="rgba(255, 255, 255, 0.30)"
        ws_focused_fg="#ffffff"
        ws_focused_bg="rgba($c6_rgb, 0.25)"
        ws_focused_border="rgba(255, 255, 255, 0.20)"
        ws_hover_bg="rgba($fg_rgb, 0.22)"
        ws_hover_fg="#ffffff"
        ws_hover_border="rgba($fg_rgb, 0.35)"
        ws_urgent_bg="rgba(240, 100, 100, 0.70)"
        ws_urgent_fg="#ffffff"
        pomodoro_fg="rgba(180, 170, 160, 0.85)"
        pomodoro_work="rgba(231, 158, 176, 0.95)"
        pomodoro_break="rgba(149, 171, 228, 0.95)"
        pomodoro_paused="rgba(139, 142, 145, 0.75)"
    fi

    cat > "$DOTFILES/waybar/style-glass.css" << CSS
/* ═══════════════════════════════════════════════════════════════
   Glass Waybar ($variant) — generated by glass-theme.sh
   Translucent surfaces with wallpaper-derived colors
   ═══════════════════════════════════════════════════════════════ */

* {
    border: none;
    box-shadow: none;
    border-radius: 0;
    font-family: JetBrainsMono Nerd Font, monospace;
    font-weight: bold;
    font-size: 13px;
    min-height: 0;
}

window#waybar,
window#waybar > box,
.modules-left,
.modules-center,
.modules-right {
    background-color: rgba(0, 0, 0, 0);
    background: transparent;
    background-image: none;
    border: none;
    box-shadow: none;
    color: $fg;
}

/* ── Workspaces ─────────────────────────────────────────── */

#workspaces {
    background: $module_bg;
    border: none;
    box-shadow: none;
    border-radius: 10px;
    margin: 2px 4px;
    padding: 2px 3px;
}

#workspaces button {
    padding: 1px 7px;
    color: $ws_inactive_fg;
    margin: 0 1px;
    border: 1px solid transparent;
    box-shadow: none;
    border-radius: 7px;
    background: transparent;
}

#workspaces button.active {
    color: $ws_active_fg;
    background: $ws_active_bg;
    border: 1px solid $ws_active_border;
    box-shadow: none;
    border-radius: 7px;
}

#workspaces button.focused {
    color: $ws_focused_fg;
    background: $ws_focused_bg;
    border: 1px solid $ws_focused_border;
    box-shadow: none;
    border-radius: 7px;
}

#workspaces button.urgent {
    color: $ws_urgent_fg;
    background: $ws_urgent_bg;
    border: 1px solid rgba(255, 255, 255, 0.45);
    box-shadow: none;
    border-radius: 7px;
}

#workspaces button:hover {
    background: $ws_hover_bg;
    color: $ws_hover_fg;
    border: 1px solid $ws_hover_border;
    box-shadow: none;
    border-radius: 7px;
}

/* ── Modules Flutuantes (Ilhas) ──────────────────────────── */

#custom-window,
#clock,
#battery,
#pulseaudio,
#network,
#cpu,
#memory,
#tray,
#backlight,
#custom-moon,
#custom-pomodoro,
#custom-recording {
    background: $module_bg;
    border: none;
    box-shadow: none;
    border-radius: 10px;
    padding: 1px 10px;
}

/* ── Ilhas Individuais ──────────────────────────────────── */

#clock {
    color: $fg;
    border-radius: 10px;
    margin: 2px 4px;
}

#custom-moon {
    color: $fg;
    border-radius: 10px;
    margin: 2px 4px;
}

#custom-pomodoro {
    color: $pomodoro_fg;
    border-radius: 10px;
    margin: 2px 4px;
}

#custom-pomodoro.work {
    color: $pomodoro_work;
}

#custom-pomodoro.break {
    color: $pomodoro_break;
}

#custom-pomodoro.paused {
    color: $pomodoro_paused;
}

#custom-window {
    border-radius: 10px;
    margin: 2px 4px;
}

#tray {
    border-radius: 10px;
    margin: 2px 4px;
}

#custom-recording {
    color: $c1;
    border-radius: 10px;
    margin: 2px 4px;
    font-size: 13px;
}

/* ── Grupo de Métricas (Direita) ────────────────────────── */

#memory {
    border-radius: 10px 0px 0px 10px;
    margin: 2px 0px 2px 4px;
}

#cpu,
#network,
#battery,
#backlight,
#pulseaudio {
    border-radius: 0;
    margin: 2px 0px;
}

#pulseaudio.microphone {
    border-radius: 0px 10px 10px 0px;
    margin: 2px 8px 2px 0px;
}
CSS
}

# ── Generate Glass Rofi Config ─────────────────────────────────

generate_rofi_glass() {
    local variant="${1:-dark}"
    read_wal_colors || return 1

    local bg_hex="${C[0]}"
    local fg_hex="${C[7]}"

    local sel_rgb; sel_rgb=$(hex_to_rgb "${C[4]}")
    local rofi_bg rofi_border text_main inputbar_bg inputbar_border entry_text placeholder_color sel_bg sel_text sel_border

    if [ "$variant" = "light" ]; then
        if ! is_light_color "$bg_hex"; then
            bg_hex="#f2f4f8"
        fi
        if is_light_color "$fg_hex"; then
            fg_hex="#1e1f26"
        fi
        local bg_rgb; bg_rgb=$(hex_to_rgb "$bg_hex")

        rofi_bg="rgba($bg_rgb, 0.72)"
        rofi_border="rgba(0, 0, 0, 0.15)"
        text_main="#1e1f26"
        inputbar_bg="rgba(0, 0, 0, 0.04)"
        inputbar_border="rgba(0, 0, 0, 0.10)"
        entry_text="#0f1015"
        placeholder_color="rgba(85, 90, 105, 0.55)"
        sel_bg="rgba($sel_rgb, 0.32)"
        sel_text="#090a0f"
        sel_border="rgba(0, 0, 0, 0.16)"
    else
        if is_light_color "$bg_hex"; then
            bg_hex="#13141a"
        fi
        if ! is_light_color "$fg_hex"; then
            fg_hex="#e0e0e5"
        fi
        local bg_rgb; bg_rgb=$(hex_to_rgb "$bg_hex")

        rofi_bg="rgba($bg_rgb, 0.55)"
        rofi_border="rgba(255, 255, 255, 0.25)"
        text_main="#e0e0e5"
        inputbar_bg="rgba(255, 255, 255, 0.08)"
        inputbar_border="rgba(255, 255, 255, 0.12)"
        entry_text="#ffffff"
        placeholder_color="rgba(180, 185, 205, 0.50)"
        sel_bg="rgba($sel_rgb, 0.45)"
        sel_text="#ffffff"
        sel_border="rgba(255, 255, 255, 0.30)"
    fi

    cat > "$DOTFILES/rofi/glass.rasi" << RASI
/* ═══════════════════════════════════════════════════════════════
   Glass Rofi ($variant) — generated by glass-theme.sh
   Translucent glass surface with wallpaper-derived colors
   ═══════════════════════════════════════════════════════════════ */

configuration {
    modi: "drun,run,window";
    show-icons: true;
    icon-theme: "Papirus";
    display-drun: "Apps";
    display-run: "Run";
    display-window: "Windows";
    drun-display-format: "{name}";
    font: "JetBrains Mono Nerd Font 10";
}

* {
    border: 0;
    margin: 0;
    padding: 0;
    spacing: 0;
    background-color: transparent;
    text-color: $text_main;
}

window {
    transparency: "real";
    background-color: $rofi_bg;
    border: 1px;
    border-color: $rofi_border;
    border-radius: 14px;
    width: 620px;
    padding: 12px;
}

mainbox {
    background-color: transparent;
    padding: 0;
    spacing: 10px;
    children: [ inputbar, listview ];
}

inputbar {
    background-color: $inputbar_bg;
    border: 1px;
    border-color: $inputbar_border;
    border-radius: 10px;
    padding: 8px 12px;
    spacing: 10px;
    children: [ prompt, entry ];
}

prompt {
    text-color: rgba($sel_rgb, 0.95);
}

entry {
    text-color: $entry_text;
    placeholder: "Search...";
    placeholder-color: $placeholder_color;
}

listview {
    background-color: transparent;
    columns: 1;
    lines: 8;
    spacing: 4px;
    padding: 6px 0 0 0;
}

element {
    background-color: transparent;
    text-color: $text_main;
    border-radius: 8px;
    padding: 8px 12px;
    spacing: 12px;
}

element-icon {
    size: 24px;
    background-color: transparent;
}

element-text {
    background-color: transparent;
    text-color: inherit;
    vertical-align: 0.5;
}

element normal.normal {
    background-color: transparent;
    text-color: $text_main;
}

element alternate.normal {
    background-color: transparent;
    text-color: $text_main;
}

element selected.normal {
    background-color: $sel_bg;
    text-color: $sel_text;
    border: 1px;
    border-color: $sel_border;
    border-radius: 8px;
}

element normal.active,
element alternate.active {
    background-color: transparent;
    text-color: $sel_text;
}

element selected.active {
    background-color: rgba($sel_rgb, 0.55);
    text-color: $sel_text;
}
RASI
}

# ── Generate Glass Foot Config ─────────────────────────────────

generate_foot_glass() {
    local variant="${1:-dark}"
    read_wal_colors || return 1

    local bg="${C[0]#\#}"
    local fg="${C[7]#\#}"
    local alpha="0.65"

    if [ "$variant" = "light" ]; then
        alpha="0.75"
        if ! is_light_color "${C[0]}"; then
            bg="f0f3f6"
        fi
        if is_light_color "${C[7]}"; then
            fg="1a1c23"
        fi
    else
        alpha="0.65"
        if is_light_color "${C[0]}"; then
            bg="14151b"
        fi
        if ! is_light_color "${C[7]}"; then
            fg="e4e5eb"
        fi
    fi

    cat > "$DOTFILES/foot/foot-glass.ini" << INI
[main]
font=JetBrainsMono Nerd Font:size=15
shell=fish
alpha=$alpha

[colors]
background=$bg
foreground=$fg
regular0=${C[0]#\#}
regular1=${C[1]#\#}
regular2=${C[2]#\#}
regular3=${C[3]#\#}
regular4=${C[4]#\#}
regular5=${C[5]#\#}
regular6=${C[6]#\#}
regular7=${C[7]#\#}
bright0=${C[8]#\#}
bright1=${C[9]#\#}
bright2=${C[10]#\#}
bright3=${C[11]#\#}
bright4=${C[12]#\#}
bright5=${C[13]#\#}
bright6=${C[14]#\#}
bright7=${C[15]#\#}

[cursor]
style=beam

[key-bindings]
scrollback-up-page=Control+Shift+Page_Up
scrollback-down-page=Control+Shift+Page_Down

[mouse-bindings]
primary-paste=BTN_MIDDLE
INI
}

# ── Apply Glass ────────────────────────────────────────────────

apply_glass() {
    read_wal_colors || return 1

    local variant
    variant=$(get_variant "${1:-}")
    echo "$variant" > "$VARIANT_FILE"

    # Backup current configs (apenas se ainda não estiver em modo glass)
    if [ ! -f "$STATE" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$DOTFILES/foot/foot.ini" "$BACKUP_DIR/foot.ini" 2>/dev/null || true
        cp "$DOTFILES/waybar/style.css" "$BACKUP_DIR/style.css" 2>/dev/null || true
        cp "$DOTFILES/rofi/config.rasi" "$BACKUP_DIR/config.rasi" 2>/dev/null || true
    fi

    # State flag — define ANTES do reload para o hyprland.lua detectar
    echo "on" > "$STATE"

    # Generate all Glass configs from current pywal colors with variant
    generate_waybar_glass "$variant"
    generate_rofi_glass "$variant"
    generate_foot_glass "$variant"

    # ── Waybar: apply Glass CSS ──
    cp "$DOTFILES/waybar/style-glass.css" "$DOTFILES/waybar/style.css"
    cp "$DOTFILES/waybar/style-glass.css" "$HOME/.config/waybar/style.css" 2>/dev/null || true
    echo "glass-$variant" > "$DOTFILES/waybar/.theme-mode"
    reload_waybar_safe

    # ── Foot: apply Glass config ──
    cp "$DOTFILES/foot/foot-glass.ini" "$DOTFILES/foot/foot.ini"
    cp "$DOTFILES/foot/foot.ini" "$HOME/.config/foot/foot.ini" 2>/dev/null || true

    # ── Rofi: apply Glass theme ──
    cp "$DOTFILES/rofi/glass.rasi" "$DOTFILES/rofi/config.rasi"
    cp "$DOTFILES/rofi/config.rasi" "$HOME/.config/rofi/config.rasi" 2>/dev/null || true

    # ── Hyprland: recarrega a configuração nativa com suporte completo a Glass ──
    hyprctl reload

    notify-send "🔮 Glass" "Tema Glass ($variant) ativado com as cores do wallpaper" -t 2000 2>/dev/null || true
    echo "[glass] Glass mode enabled ($variant)"
}

# ── Refresh Glass (quando o wallpaper/cores mudam) ──────────────

refresh_glass() {
    if [ ! -f "$STATE" ]; then
        return 0
    fi
    read_wal_colors || return 1

    local variant
    variant=$(get_variant "${1:-}")
    echo "$variant" > "$VARIANT_FILE"

    generate_waybar_glass "$variant"
    generate_rofi_glass "$variant"
    generate_foot_glass "$variant"

    cp "$DOTFILES/waybar/style-glass.css" "$DOTFILES/waybar/style.css"
    cp "$DOTFILES/waybar/style-glass.css" "$HOME/.config/waybar/style.css" 2>/dev/null || true
    reload_waybar_safe

    cp "$DOTFILES/rofi/glass.rasi" "$DOTFILES/rofi/config.rasi"
    cp "$DOTFILES/rofi/config.rasi" "$HOME/.config/rofi/config.rasi" 2>/dev/null || true

    hyprctl reload
    echo "[glass] Glass theme ($variant) refreshed with new wallpaper colors"
}

# ── Remove Glass ───────────────────────────────────────────────

remove_glass() {
    rm -f "$STATE"
    rm -f "$VARIANT_FILE"

    # ── Restore Waybar ──
    WAL_CSS="$HOME/.cache/wal/colors-waybar.css"
    if [ -f "$WAL_CSS" ]; then
        cp "$WAL_CSS" "$DOTFILES/waybar/style.css"
        cp "$WAL_CSS" "$HOME/.config/waybar/style.css" 2>/dev/null || true
    elif [ -f "$BACKUP_DIR/style.css" ]; then
        cp "$BACKUP_DIR/style.css" "$DOTFILES/waybar/style.css"
        cp "$BACKUP_DIR/style.css" "$HOME/.config/waybar/style.css" 2>/dev/null || true
    fi
    echo "pywal" > "$DOTFILES/waybar/.theme-mode"
    reload_waybar_safe

    # ── Restore Foot ──
    if [ -f "$BACKUP_DIR/foot.ini" ]; then
        cp "$BACKUP_DIR/foot.ini" "$DOTFILES/foot/foot.ini"
        cp "$DOTFILES/foot/foot.ini" "$HOME/.config/foot/foot.ini" 2>/dev/null || true
    fi

    # ── Restore Kitty ──
    rm -f "$DOTFILES/kitty/glass.conf"

    # ── Restore Rofi ──
    if [ -f "$BACKUP_DIR/config.rasi" ]; then
        cp "$BACKUP_DIR/config.rasi" "$DOTFILES/rofi/config.rasi"
        cp "$DOTFILES/rofi/config.rasi" "$HOME/.config/rofi/config.rasi" 2>/dev/null || true
    fi

    # ── Hyprland: recarrega para restaurar o look padrão ──
    hyprctl reload

    notify-send "🔮 Glass" "Tema Glass desativado" -t 2000 2>/dev/null || true
    echo "[glass] Glass mode disabled"
}

# ── Main ───────────────────────────────────────────────────────

case "${1:-toggle}" in
    on)
        apply_glass "${2:-}"
        ;;
    off)
        remove_glass
        ;;
    refresh)
        refresh_glass "${2:-}"
        ;;
    toggle)
        if [ -f "$STATE" ]; then
            remove_glass
        else
            apply_glass "${2:-}"
        fi
        ;;
    status)
        if [ -f "$STATE" ]; then
            var=$(get_variant)
            echo "glass-$var"
        else
            echo "off"
        fi
        ;;
    *)
        echo "Usage: glass-theme.sh [on [dark|light]|off|refresh [dark|light]|toggle [dark|light]|status]"
        exit 1
        ;;
esac
