#!/bin/bash

# Script para aplicar tema GTK manualmente
# Execute este script após mudar o tema no nwg-look

echo "=== Aplicando tema GTK ==="

# Executar o script principal
~/.config/hypr/scripts/gtk.sh

# Limpar cache do GTK
echo "Limpando cache do GTK..."
rm -rf ~/.cache/gtk-3.0
rm -rf ~/.cache/gtk-4.0

# Reiniciar aplicativos GTK se estiverem rodando
echo "Reiniciando aplicativos GTK..."

if pgrep -x "thunar" > /dev/null; then
    echo "  - Reiniciando Thunar..."
    killall thunar
    sleep 0.5
    thunar &
fi

if pgrep -x "nwg-look" > /dev/null; then
    echo "  - Reiniciando nwg-look..."
    killall nwg-look
fi

echo ""
echo "✓ Tema GTK aplicado com sucesso!"
echo ""
echo "Se o Thunar ainda não mudou:"
echo "  1. Feche completamente o Thunar"
echo "  2. Execute: thunar"
echo "  3. Ou reinicie o Hyprland (Super+Shift+R)"
