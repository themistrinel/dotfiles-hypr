#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

print_status()  { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Dependências ---
PACMAN_DEPS=(
    hyprland waybar hyprpaper dunst rofi-wayland
    wl-clipboard grim slurp pavucontrol
    pipewire pipewire-pulse pipewire-alsa wireplumber
    fish neovim fastfetch btop git base-devel
    qt5-wayland qt6-wayland
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    ttf-jetbrains-mono-nerd otf-font-awesome papirus-icon-theme
    brightnessctl playerctl starship zoxide direnv eza lazygit
    thunar thunar-archive-plugin thunar-volman tumbler
    gvfs udiskie xdg-utils polkit-gnome
    ffmpeg wf-recorder
    nwg-look python-pywal
    foot zellij kitty
    network-manager-applet
)

AUR_DEPS=(
    cliphist waypaper
    zen-browser-bin
    catppuccin-gtk-theme-mocha kora-icon-theme
)

# --- Dependências para build (yay) ---
sudo pacman -S --needed --noconfirm base-devel fakeroot

# --- Instalar yay ---
if ! command -v yay &>/dev/null; then
    print_status "Instalando yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
fi

# --- Instalar pacotes ---
print_status "Instalando dependências..."
yay -S --needed --noconfirm "${PACMAN_DEPS[@]}" "${AUR_DEPS[@]}"

# --- Submodules ---
print_status "Inicializando submodules..."
git submodule update --init --recursive

# --- Links de configuração ---
print_status "Criando symlinks..."
mkdir -p "$CONFIG_DIR"

FOLDERS=(hypr waybar dunst rofi fastfetch fish nvim kitty foot zellij wal waypaper)

for folder in "${FOLDERS[@]}"; do
    src="$DOTFILES_DIR/$folder"
    dst="$CONFIG_DIR/$folder"
    if [ ! -d "$src" ]; then
        print_warning "$folder não encontrado no dotfiles, pulando..."
        continue
    fi
    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -d "$dst" ]; then
        print_warning "Backup de $folder existente -> ${dst}_backup"
        rm -rf "${dst}_backup"
        mv "$dst" "${dst}_backup"
    fi
    ln -sf "$src" "$dst"
    print_success "Linkado: $folder"
done

# --- Fontes ---
print_status "Instalando fontes..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
cp -rf "$DOTFILES_DIR/fonts/"* "$FONT_DIR/"
fc-cache -f
print_success "Fontes instaladas."

# --- Scripts executáveis ---
find "$DOTFILES_DIR" -type f -name "*.sh" -exec chmod +x {} +

# --- Shell padrão ---
if [ "$SHELL" != "/usr/bin/fish" ]; then
    sudo chsh -s /usr/bin/fish "$USER"
    print_success "Shell alterado para fish (efetivo no próximo login)."
fi

print_success "Instalação completa! Reinicie o Hyprland."
