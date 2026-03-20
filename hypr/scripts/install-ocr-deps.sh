#!/usr/bin/env bash

echo "=== Installing OCR Dependencies (EasyOCR) ==="
echo ""

# Install Python and venv
sudo pacman -S --needed python python-pip python-virtualenv

# Create virtualenv directory
VENV_DIR="$HOME/.local/share/ocr-venv"

if [ -d "$VENV_DIR" ]; then
    echo "Removing old virtualenv..."
    rm -rf "$VENV_DIR"
fi

echo "Creating virtualenv..."
python -m venv "$VENV_DIR"

echo "Installing EasyOCR in virtualenv (this may take a few minutes)..."
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install easyocr

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Virtualenv location: $VENV_DIR"
echo "Usage: Super + Shift + O"
echo ""
echo "Note: First run will download language models (~100MB)"
echo "EasyOCR is more accurate but slower than Tesseract"
