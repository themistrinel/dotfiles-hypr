#!/usr/bin/env bash

echo "=== Installing Screen Recording Dependencies ==="
echo ""

sudo pacman -S --needed wf-recorder pipewire pipewire-pulse

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Usage:"
echo "  Super + Shift + R - Start/Stop recording"
echo ""
echo "Recordings saved to: ~/Videos/Recordings/"
echo "Format: MP4 with audio from default microphone"
