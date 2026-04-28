#!/usr/bin/env bash
set -e

DOTFILES="$HOME/.dotfiles"
DESKTOP_DIR="$HOME/.local/share/applications"

echo "Installing Dotfiles Manager..."

chmod +x "$DOTFILES/dotfiles-manager/main.py"

mkdir -p "$DESKTOP_DIR"
cp "$DOTFILES/dotfiles-manager/dotfiles-manager.desktop" "$DESKTOP_DIR/"

# Update Exec path in .desktop to use correct home
sed -i "s|/home/abyssal|$HOME|g" "$DESKTOP_DIR/dotfiles-manager.desktop"

echo "Done! Launch with: python3 $DOTFILES/dotfiles-manager/main.py"
echo "Or search 'Dotfiles Manager' in your app launcher."
