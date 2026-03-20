#!/usr/bin/env bash

# OCR Script using EasyOCR - Preserves code structure

TEMP_DIR="/tmp/ocr"
SCREENSHOT="$TEMP_DIR/ocr_screenshot.png"
PYTHON_SCRIPT="/tmp/ocr_easyocr.py"
VENV_DIR="$HOME/.local/share/ocr-venv"
PYTHON_BIN="$VENV_DIR/bin/python"

mkdir -p "$TEMP_DIR"

# Check dependencies
if ! command -v grim &> /dev/null; then
    notify-send "OCR Error" "grim not installed" -u critical
    exit 1
fi

if ! command -v slurp &> /dev/null; then
    notify-send "OCR Error" "slurp not installed" -u critical
    exit 1
fi

if [ ! -f "$PYTHON_BIN" ]; then
    notify-send "OCR Error" "Virtualenv not found\nRun: ~/.config/hypr/scripts/install-ocr-deps.sh" -u critical
    exit 1
fi

if ! command -v wl-copy &> /dev/null; then
    notify-send "OCR Error" "wl-clipboard not installed" -u critical
    exit 1
fi

# Take screenshot
grim -g "$(slurp)" "$SCREENSHOT" 2>/dev/null

if [ ! -f "$SCREENSHOT" ]; then
    exit 1
fi

# Create Python script for EasyOCR with structure preservation
cat > "$PYTHON_SCRIPT" << 'EOF'
import easyocr
import sys

try:
    reader = easyocr.Reader(['pt', 'en'], gpu=False, verbose=False)
    
    # Get detailed results with coordinates
    result = reader.readtext(sys.argv[1], detail=1)
    
    if not result:
        sys.exit(1)
    
    # Sort by Y coordinate (top to bottom), then X coordinate (left to right)
    result_sorted = sorted(result, key=lambda x: (int(x[0][0][1] / 10), x[0][0][0]))
    
    # Group lines by Y coordinate (within threshold)
    lines = []
    current_line = []
    current_y = None
    y_threshold = 15  # pixels
    
    for item in result_sorted:
        text = item[1]
        bbox = item[0]
        y_pos = bbox[0][1]
        
        if current_y is None or abs(y_pos - current_y) < y_threshold:
            current_line.append(text)
            current_y = y_pos if current_y is None else current_y
        else:
            if current_line:
                lines.append(' '.join(current_line))
            current_line = [text]
            current_y = y_pos
    
    # Add last line
    if current_line:
        lines.append(' '.join(current_line))
    
    # Join lines with newlines
    output = '\n'.join(lines)
    print(output)
    
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF

# Extract text with EasyOCR
TEXT=$("$PYTHON_BIN" "$PYTHON_SCRIPT" "$SCREENSHOT" 2>/dev/null)

# Check if text was extracted
if [ -z "$TEXT" ]; then
    notify-send "OCR" "Nenhum texto detectado" -u normal
    rm -f "$SCREENSHOT" "$PYTHON_SCRIPT"
    exit 1
fi

# Copy to clipboard
echo "$TEXT" | wl-copy

# Show notification
LINE_COUNT=$(echo "$TEXT" | wc -l)
PREVIEW=$(echo "$TEXT" | head -c 80)
if [ ${#TEXT} -gt 80 ]; then
    PREVIEW="${PREVIEW}..."
fi

notify-send "OCR" "$LINE_COUNT linhas copiadas:\n\n$PREVIEW" -t 3000

# Clean up
rm -f "$SCREENSHOT" "$PYTHON_SCRIPT"
