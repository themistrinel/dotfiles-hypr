#!/bin/bash
# appimage-install.sh — "instala" um AppImage no sistema (Void Linux)
# Uso: ./appimage-install.sh <arquivo.AppImage> [nome]
#
# O que faz:
#   1. Copia o AppImage para ~/Applications/
#   2. Extrai o ícone e o .desktop do AppImage
#   3. Instala ícone e .desktop entry para aparecer no launcher

set -e

APPIMAGE="$1"
NAME="${2:-}"

# --- validação ---
[[ -z "$APPIMAGE" ]] && { echo "Uso: $0 <arquivo.AppImage> [nome]"; exit 1; }
[[ ! -f "$APPIMAGE" ]] && { echo "Erro: arquivo não encontrado: $APPIMAGE"; exit 1; }
[[ "$APPIMAGE" != *.AppImage && "$APPIMAGE" != *.appimage ]] && \
    echo "Aviso: arquivo não tem extensão .AppImage, continuando mesmo assim..."

chmod +x "$APPIMAGE"

# nome base do app (sem extensão, sem espaços)
if [[ -z "$NAME" ]]; then
    NAME=$(basename "$APPIMAGE" | sed 's/\.appimage$//I' | sed 's/[^a-zA-Z0-9._-]/-/g')
fi
NAME_LOWER=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')

APPS_DIR="$HOME/Applications"
DEST="$APPS_DIR/$NAME.AppImage"
ICONS_DIR="$HOME/.local/share/icons"
DESKTOP_DIR="$HOME/.local/share/applications"

mkdir -p "$APPS_DIR" "$ICONS_DIR" "$DESKTOP_DIR"

# 1. copiar AppImage
cp "$APPIMAGE" "$DEST"
chmod +x "$DEST"
echo "→ AppImage copiado para $DEST"

# 2. extrair conteúdo em diretório temporário
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
"$DEST" --appimage-extract > /dev/null 2>&1 || true
SQUASHFS="$TMPDIR/squashfs-root"

# 3. ícone
ICON_DEST="$ICONS_DIR/$NAME_LOWER.png"
if [[ -d "$SQUASHFS" ]]; then
    ICON=$(find "$SQUASHFS" -maxdepth 2 \( -name "*.png" -o -name "*.svg" \) | head -1)
    if [[ -n "$ICON" ]]; then
        cp "$ICON" "$ICON_DEST"
        echo "→ Ícone instalado em $ICON_DEST"
    fi
fi

# 4. .desktop entry — tenta reutilizar o do AppImage, senão cria um simples
DESKTOP_SRC=$(find "$SQUASHFS" -maxdepth 2 -name "*.desktop" 2>/dev/null | head -1)
DESKTOP_DEST="$DESKTOP_DIR/$NAME_LOWER.desktop"

if [[ -n "$DESKTOP_SRC" ]]; then
    cp "$DESKTOP_SRC" "$DESKTOP_DEST"
    # corrige o Exec para apontar para o AppImage instalado
    sed -i "s|^Exec=.*|Exec=$DEST %U|" "$DESKTOP_DEST"
    # corrige o ícone se necessário
    sed -i "s|^Icon=.*|Icon=$ICON_DEST|" "$DESKTOP_DEST"
    echo "→ .desktop entry reutilizado e ajustado"
else
    cat > "$DESKTOP_DEST" <<EOF
[Desktop Entry]
Name=$NAME
Exec=$DEST %U
Icon=$ICON_DEST
Type=Application
Categories=Utility;
EOF
    echo "→ .desktop entry criado"
fi

# 5. atualiza cache de ícones / desktop (sem sudo)
command -v update-desktop-database &>/dev/null && update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
command -v gtk-update-icon-cache  &>/dev/null && gtk-update-icon-cache -f "$ICONS_DIR"  2>/dev/null || true

echo ""
echo "✓ $NAME instalado. Reinicie o launcher (rofi/dmenu) se necessário."
