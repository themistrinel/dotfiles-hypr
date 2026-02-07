#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Variables ---
TERMINAL_OPT="both"
DEP_FILE="dependencies.txt"

# --- Functions ---
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --terminal [kitty|wezterm|both]  Select terminal to install (default: both)"
    echo "  -h, --help                       Show this help message"
    exit 1
}

# --- Parse Arguments ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --terminal)
            TERMINAL_OPT="$2"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown parameter passed: $1"
            usage
            ;;
    esac
    shift
done

# --- Dependencies Lists ---
PACMAN_DEPS=(
    "hyprland" "waybar" "hyprpaper" "swww" "dunst" "rofi-wayland"
    "network-manager-applet" "wl-clipboard" "grim" "slurp"
    "pavucontrol" "pipewire" "pipewire-pulse" "pipewire-alsa" "wireplumber"
    "fish" "neovim" "fastfetch" "btop" "git" "base-devel"
    "qt5-wayland" "qt6-wayland" "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk"
    "ttf-jetbrains-mono-nerd" "otf-font-awesome" "papirus-icon-theme"
    "brightnessctl" "playerctl" "starship" "zoxide" "direnv" "eza" "lazygit" "zsh"
    "thunar" "thunar-archive-plugin" "thunar-volman" "tumbler" "imv"
    "gvfs" "gvfs-smb" "udiskie" "xdg-utils" "polkit-gnome"
)

AUR_DEPS=(
    "cliphist" "spotify" "discord" "waypaper" "swaylock-effects-git" "wlogout" "wallust"
    "adw-gtk-theme" "qt5ct-kde" "qt6ct-kde"
)

# --- Start Installation ---
print_status "Starting Arch Linux installation script..."

# 0. Enable Multilib
print_status "Enabling multilib repository..."
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Syu --noconfirm
elif grep -q "^#\[multilib\]" /etc/pacman.conf; then
    sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm
fi

# 1. Update System and install essential build tools
print_status "Updating system and installing essential tools..."
sudo pacman -Syu --needed --noconfirm git base-devel

# 2. Check for yay (AUR helper)
if ! command -v yay &> /dev/null; then
    print_warning "yay not found. Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay || exit
    makepkg -si --noconfirm
    cd - || exit
else
    print_success "yay is already installed."
fi

# 3. Install all dependencies using yay
print_status "Installing all dependencies..."
yay -S --needed --noconfirm "${PACMAN_DEPS[@]}" "${AUR_DEPS[@]}"

# 4. Handle Terminal Installation
case $TERMINAL_OPT in
    kitty)
        print_status "Installing Kitty terminal..."
        yay -S --needed --noconfirm kitty
        ;;
    wezterm)
        print_status "Installing WezTerm terminal..."
        yay -S --needed --noconfirm wezterm
        ;;
    both)
        print_status "Installing both Kitty and WezTerm..."
        yay -S --needed --noconfirm kitty wezterm
        ;;
    *)
        print_error "Invalid terminal option: $TERMINAL_OPT"
        usage
        ;;
esac

# 5. Initialize Submodules
print_status "Initializing submodules..."
git submodule update --init --recursive

# 6. Setup Configuration (Linking folders)
print_status "Setting up configurations (linking folders)..."
CONFIG_DIR="$HOME/.config"
DOTFILES_DIR=$(pwd)

mkdir -p "$CONFIG_DIR"

# List of folders to link
FOLDERS=("hypr" "waybar" "dunst" "rofi" "fastfetch" "fish" "nvim" "wallust" "waypaper")

# Add terminals to link list based on selection
if [[ "$TERMINAL_OPT" == "kitty" || "$TERMINAL_OPT" == "both" ]]; then
    FOLDERS+=("kitty")
fi
if [[ "$TERMINAL_OPT" == "wezterm" || "$TERMINAL_OPT" == "both" ]]; then
    FOLDERS+=("wezterm")
fi

for folder in "${FOLDERS[@]}"; do
    if [ -d "$DOTFILES_DIR/$folder" ]; then
        if [ -d "$CONFIG_DIR/$folder" ] || [ -L "$CONFIG_DIR/$folder" ]; then
            print_warning "Config for $folder already exists. Backing up to $CONFIG_DIR/${folder}_backup..."
            rm -rf "$CONFIG_DIR/${folder}_backup"
            mv "$CONFIG_DIR/$folder" "$CONFIG_DIR/${folder}_backup"
        fi
        ln -s "$DOTFILES_DIR/$folder" "$CONFIG_DIR/$folder"
        print_success "Linked $folder"
    else
        print_error "Source folder $folder not found in dotfiles!"
    fi
done

# 7. GPU Driver Installation
print_status "Detecting GPU for driver installation..."
GPU_INFO=$(lspci 2>/dev/null | grep -i vga)

if [[ $GPU_INFO == *"NVIDIA"* ]]; then
    print_status "NVIDIA GPU detected. Installing nvidia and nvidia-utils..."
    yay -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
elif [[ $GPU_INFO == *"AMD"* || $GPU_INFO == *"ATI"* ]]; then
    print_status "AMD GPU detected. Installing xf86-video-amdgpu and mesa..."
    yay -S --needed --noconfirm xf86-video-amdgpu mesa lib32-mesa
elif [[ $GPU_INFO == *"Intel"* ]]; then
    print_status "Intel GPU detected. Installing xf86-video-intel and mesa..."
    yay -S --needed --noconfirm xf86-video-intel mesa lib32-mesa
else
    print_warning "Could not accurately detect GPU or lspci not found. Please install drivers manually."
fi

# 8. Set Fish as default shell
print_status "Setting Fish as the default shell..."
if [ "$SHELL" != "/usr/bin/fish" ]; then
    sudo chsh -s /usr/bin/fish "$USER"
    print_success "Shell changed to Fish. It will take effect on next login."
else
    print_success "Fish is already the default shell."
fi

print_success "Installation complete! Please restart Hyprland or log out/in to see changes."
