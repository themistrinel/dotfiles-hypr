#!/bin/sh
# scripts/install-fonts.sh
# Instala JetBrainsMono Nerd Font e Bibata-Modern-Classic cursor theme

set -e

# ── JetBrainsMono Nerd Font ───────────────────────────────────
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
if fc-list | grep -qi "JetBrainsMono Nerd"; then
    echo "JetBrainsMono Nerd Font já instalada."
else
    echo "Instalando JetBrainsMono Nerd Font..."
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
        | grep '"browser_download_url"' \
        | grep 'JetBrainsMono\.tar\.xz"' \
        | head -1 \
        | sed 's/.*": "\(.*\)"/\1/' \
        | tr -d '"')
    [ -z "$DOWNLOAD_URL" ] && DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.tar.xz"
    mkdir -p "$FONT_DIR"
    TMP=$(mktemp -d)
    curl -fsSL "$DOWNLOAD_URL" -o "$TMP/JetBrainsMono.tar.xz"
    tar -xf "$TMP/JetBrainsMono.tar.xz" -C "$FONT_DIR" --wildcards "*.ttf" 2>/dev/null || \
        tar -xf "$TMP/JetBrainsMono.tar.xz" -C "$FONT_DIR"
    rm -rf "$TMP"
    fc-cache -f "$FONT_DIR"
    echo "JetBrainsMono Nerd Font instalada com sucesso."
fi

# ── Bibata-Modern-Classic cursor theme ───────────────────────
CURSOR_DIR="$HOME/.local/share/icons/Bibata-Modern-Classic"
if [ ! -d "$CURSOR_DIR" ]; then
    echo "Instalando Bibata-Modern-Classic cursor theme..."
    TMP=$(mktemp -d)
    curl -fsSL "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz" \
        -o "$TMP/bibata.tar.xz"
    mkdir -p "$HOME/.local/share/icons"
    tar -xf "$TMP/bibata.tar.xz" -C "$HOME/.local/share/icons"
    rm -rf "$TMP"
    echo "Bibata-Modern-Classic instalado."
else
    echo "Bibata-Modern-Classic já instalado."
fi
