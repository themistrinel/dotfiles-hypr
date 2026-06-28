#!/bin/bash
# ~/.dotfiles/install.sh
# Instalação unificada: Hyprland (Wayland) e/ou i3 (X11)
# Arch Linux — pacman + yay (AUR)

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# ── Cores ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[ERR ]${NC} $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }

# ── Pacotes ───────────────────────────────────────────────────

# Pacotes comuns aos dois setups
PKGS_COMMON=(
    fish neovim fastfetch btop git base-devel
    ttf-jetbrains-mono-nerd otf-font-awesome papirus-icon-theme
    brightnessctl playerctl starship zoxide direnv eza lazygit
    rofi dunst
    thunar thunar-archive-plugin thunar-volman tumbler
    gvfs udiskie xdg-utils polkit-gnome
    pavucontrol
    alacritty foot
    pipewire pipewire-pulse pipewire-alsa wireplumber
    network-manager-applet
    curl wget unzip
)
PKGS_COMMON_AUR=(
    kora-icon-theme
)

# Pacotes exclusivos do Hyprland (Wayland)
PKGS_HYPR=(
    hyprland waybar hyprpaper
    wl-clipboard grim slurp
    qt5-wayland qt6-wayland
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    ffmpeg wf-recorder
    nwg-look python-pywal
    kitty zellij
    rofi-wayland   # versão Wayland (diferente do rofi do i3)
    ly             # display manager
)
PKGS_HYPR_AUR=(
    cliphist waypaper
    catppuccin-gtk-theme-mocha
)

# Pacotes exclusivos do i3 (X11)
PKGS_I3=(
    i3-wm i3status-rust
    picom feh xorg-server xorg-xinit xorg-xrandr
    xorg-xsetroot scrot xclip xdotool
    xss-lock autorandr
    dmenu
    ly
    rofi          # versão X11 (diferente do rofi-wayland do Hyprland)
    alacritty
    nodejs npm    # necessário para prettier e eslint_d (Mason/Neovim)
    pulsemixer    # mixer de áudio TUI
)
PKGS_I3_AUR=(
    autotiling
    i3lock-color
    gruvbox-plus-icon-theme
)

# ── Helpers ───────────────────────────────────────────────────

# Cria symlink com backup se o destino existir
link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$dst" "$BACKUP_DIR/"
        warn "Backup: $dst → $BACKUP_DIR/"
    fi
    ln -sf "$src" "$dst"
    ok "Link: $(basename "$dst")"
}

# Instala yay se necessário
ensure_yay() {
    if ! command -v yay &>/dev/null; then
        info "Instalando yay (AUR helper)..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay-install
        cd /tmp/yay-install && makepkg -si --noconfirm
        cd "$DOTFILES"
        rm -rf /tmp/yay-install
        ok "yay instalado."
    fi
}

# ── Menu ──────────────────────────────────────────────────────

show_menu() {
    echo -e "\n${BOLD}${CYAN}"
    echo "  ╔═══════════════════════════════════╗"
    echo "  ║        xyz dotfiles               ║"
    echo "  ║   Selecione o setup a instalar    ║"
    echo "  ╠═══════════════════════════════════╣"
    echo "  ║  1) Hyprland  (Wayland)           ║"
    echo "  ║  2) i3        (X11)               ║"
    echo "  ║  3) Ambos     (Hyprland + i3)     ║"
    echo "  ║  4) Somente links (sem pacotes)   ║"
    echo "  ║  q) Sair                          ║"
    echo "  ╚═══════════════════════════════════╝"
    echo -e "${NC}"
    read -rp "  Opção: " CHOICE
}

# ── Instalação de pacotes ─────────────────────────────────────

install_packages() {
    local mode="$1"  # hyprland | i3 | both
    header "Instalando pacotes"
    ensure_yay

    local pkgs=("${PKGS_COMMON[@]}")
    local aur_pkgs=("${PKGS_COMMON_AUR[@]}")

    case "$mode" in
        hyprland)
            pkgs+=("${PKGS_HYPR[@]}")
            aur_pkgs+=("${PKGS_HYPR_AUR[@]}")
            ;;
        i3)
            pkgs+=("${PKGS_I3[@]}")
            aur_pkgs+=("${PKGS_I3_AUR[@]}")
            ;;
        both)
            pkgs+=("${PKGS_HYPR[@]}" "${PKGS_I3[@]}")
            aur_pkgs+=("${PKGS_HYPR_AUR[@]}" "${PKGS_I3_AUR[@]}")
            ;;
    esac

    info "Instalando ${#pkgs[@]} pacotes oficiais + ${#aur_pkgs[@]} AUR..."
    yay -S --needed --noconfirm "${pkgs[@]}" "${aur_pkgs[@]}"
    ok "Pacotes instalados."
}

# ── Symlinks comuns ───────────────────────────────────────────

links_common() {
    header "Links comuns"

    # Shell
    link "$DOTFILES/fish/config.fish"       "$CONFIG_DIR/fish/config.fish"
    link "$DOTFILES/fish/fish_variables"    "$CONFIG_DIR/fish/fish_variables"
    for f in "$DOTFILES/fish/conf.d/"*.fish; do
        [ -f "$f" ] && link "$f" "$CONFIG_DIR/fish/conf.d/$(basename "$f")"
    done

    # Editor
    link "$DOTFILES/nvim"                   "$CONFIG_DIR/nvim"

    # Terminal
    link "$DOTFILES/foot/foot.ini"          "$CONFIG_DIR/foot/foot.ini"

    # Notificações
    link "$DOTFILES/dunst/dunstrc"          "$CONFIG_DIR/dunst/dunstrc"

    # Fastfetch
    link "$DOTFILES/fastfetch/config.jsonc" "$CONFIG_DIR/fastfetch/config.jsonc"

    # Fontes
    info "Copiando fontes..."
    mkdir -p "$HOME/.local/share/fonts"
    cp -rf "$DOTFILES/fonts/"* "$HOME/.local/share/fonts/"
    fc-cache -f
    ok "Fontes instaladas."
}

# ── Symlinks Hyprland ─────────────────────────────────────────

links_hyprland() {
    header "Links Hyprland"

    link "$DOTFILES/hypr"       "$CONFIG_DIR/hypr"
    link "$DOTFILES/waybar"     "$CONFIG_DIR/waybar"
    link "$DOTFILES/kitty"      "$CONFIG_DIR/kitty"
    link "$DOTFILES/zellij"     "$CONFIG_DIR/zellij"
    link "$DOTFILES/wal"        "$CONFIG_DIR/wal"
    link "$DOTFILES/waypaper"   "$CONFIG_DIR/waypaper"
    link "$DOTFILES/zed"        "$CONFIG_DIR/zed"

    # rofi-wayland com config pywal
    link "$DOTFILES/rofi/config.rasi"        "$CONFIG_DIR/rofi/config.rasi"
    link "$DOTFILES/rofi/clipboard-theme.rasi" "$CONFIG_DIR/rofi/clipboard-theme.rasi"
    link "$DOTFILES/rofi/clipboard.sh"       "$CONFIG_DIR/rofi/clipboard.sh"

    # Cursores (Xcursor)
    mkdir -p "$HOME/.local/share/icons"
    if [ -d "$DOTFILES/cursors_xcursor" ]; then
        cp -rf "$DOTFILES/cursors_xcursor/"* "$HOME/.local/share/icons/"
        ok "Cursores Xcursor instalados."
    fi

    # Submodules (nvim, rofi-themes)
    info "Atualizando submodules..."
    git -C "$DOTFILES" submodule update --init --recursive 2>/dev/null || warn "Submodules: verifique manualmente."

    # ~/.icons/default aponta para FrierenBLZ (fallback para apps Wayland/GTK)
    mkdir -p "$HOME/.icons/default"
    printf '[Icon Theme]\nName=Default\nInherits=FrierenBLZ\n' > "$HOME/.icons/default/index.theme"
    ok "~/.icons/default → FrierenBLZ"

    _set_cursor_gtk "FrierenBLZ"

    # ly como display manager
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable ly.service 2>/dev/null && ok "ly: serviço habilitado." || warn "ly: habilite manualmente: sudo systemctl enable ly"
    fi

    _set_fish_default_shell
}

# ── Symlinks i3 ───────────────────────────────────────────────

links_i3() {
    header "Links i3"

    link "$DOTFILES/i3/config"                  "$CONFIG_DIR/i3/config"
    link "$DOTFILES/i3status-rust/config.toml"  "$CONFIG_DIR/i3status-rust/config.toml"
    link "$DOTFILES/picom/picom.conf"           "$CONFIG_DIR/picom/picom.conf"
    link "$DOTFILES/alacritty/alacritty.toml"   "$CONFIG_DIR/alacritty/alacritty.toml"

    # rofi com config própria (gruvbox, sem pywal) — sobrescreve o link do Hyprland se ambos instalados
    link "$DOTFILES/rofi-i3/config.rasi"        "$CONFIG_DIR/rofi/config.rasi"

    # X11
    link "$DOTFILES/x11/xprofile"   "$HOME/.xprofile"
    link "$DOTFILES/x11/xinitrc"    "$HOME/.xinitrc"
    link "$DOTFILES/x11/Xresources" "$HOME/.Xresources"

    # GTK
    link "$DOTFILES/gtk/settings.ini" "$CONFIG_DIR/gtk-3.0/settings.ini"
    link "$DOTFILES/gtk/gtkrc-2.0"   "$HOME/.gtkrc-2.0"

    # Cursor Capitaine-Gruvbox (i3/X11)
    if [ -d "$DOTFILES/cursors/Capitaine-Gruvbox" ]; then
        mkdir -p "$HOME/.icons/Capitaine-Gruvbox"
        cp -r "$DOTFILES/cursors/Capitaine-Gruvbox/cursors" "$HOME/.icons/Capitaine-Gruvbox/"
        ok "Cursor Capitaine-Gruvbox instalado em ~/.icons."
    else
        warn "Cursor Capitaine-Gruvbox não encontrado em $DOTFILES/cursors/Capitaine-Gruvbox — instale manualmente."
    fi
    # ~/.icons/default aponta para Capitaine-Gruvbox (fallback X11/GTK)
    mkdir -p "$HOME/.icons/default"
    printf '[Icon Theme]\nName=Default\nInherits=Capitaine-Gruvbox\n' > "$HOME/.icons/default/index.theme"
    ok "~/.icons/default → Capitaine-Gruvbox"

    # ly como display manager (habilita o serviço)
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable ly.service 2>/dev/null && ok "ly: serviço habilitado." || warn "ly: habilite manualmente: sudo systemctl enable ly"
    fi

    _set_fish_default_shell
}

# ── Helpers internos ──────────────────────────────────────────

_set_cursor_gtk() {
    local theme="$1"
    for ver in gtk-3.0 gtk-4.0; do
        local cfg="$HOME/.config/$ver/settings.ini"
        mkdir -p "$(dirname "$cfg")"
        if grep -q "gtk-cursor-theme-name" "$cfg" 2>/dev/null; then
            sed -i "s/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$theme/" "$cfg"
        else
            grep -q "\[Settings\]" "$cfg" 2>/dev/null || echo "[Settings]" >> "$cfg"
            echo "gtk-cursor-theme-name=$theme" >> "$cfg"
            echo "gtk-cursor-theme-size=24" >> "$cfg"
        fi
    done
    ok "Cursor GTK definido: $theme"
}

_set_fish_default_shell() {
    if command -v fish &>/dev/null; then
        local fish_bin
        fish_bin="$(command -v fish)"
        if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$fish_bin" ]; then
            sudo chsh -s "$fish_bin" "$USER" && ok "Shell padrão → fish." || warn "chsh falhou — execute: chsh -s $fish_bin"
        else
            ok "fish já é o shell padrão."
        fi
    fi
}

# ── Execução principal ────────────────────────────────────────

main() {
    # Permite passar opção via argumento: ./install.sh hyprland | i3 | both | links
    local mode="${1:-}"

    if [ -z "$mode" ]; then
        show_menu
        case "$CHOICE" in
            1) mode="hyprland" ;;
            2) mode="i3" ;;
            3) mode="both" ;;
            4) mode="links" ;;
            q|Q) echo "Saindo."; exit 0 ;;
            *) die "Opção inválida." ;;
        esac
    fi

    find "$DOTFILES" -type f -name "*.sh" -exec chmod +x {} +

    case "$mode" in
        hyprland)
            install_packages hyprland
            links_common
            links_hyprland
            echo -e "\n${GREEN}${BOLD}✓ Hyprland instalado! Execute: Hyprland${NC}"
            ;;
        i3)
            install_packages i3
            links_common
            links_i3
            echo -e "\n${GREEN}${BOLD}✓ i3 instalado! Execute: startx ou reinicie para emptty.${NC}"
            ;;
        both)
            install_packages both
            links_common
            links_hyprland
            links_i3
            echo -e "\n${GREEN}${BOLD}✓ Hyprland + i3 instalados! Escolha a sessão no login.${NC}"
            ;;
        links|links-only)
            links_common
            echo -e "\n${YELLOW}Modo links: instale os pacotes manualmente se necessário.${NC}"
            echo "  Hyprland: ./install.sh hyprland --links-only (não implementado ainda)"
            ;;
        *)
            die "Modo desconhecido: $mode. Use: hyprland | i3 | both | links"
            ;;
    esac
}

main "$@"
