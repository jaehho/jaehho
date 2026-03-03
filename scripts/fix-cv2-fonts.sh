#!/bin/bash
# Automatically finds the cv2 folder in your active venv and links fonts
CV2_PATH=$(python -c "import cv2; import os; print(os.path.dirname(cv2.__file__))")
TARGET_DIR="$CV2_PATH/qt/fonts"

mkdir -p "$TARGET_DIR"
ln -sf /usr/share/fonts/truetype/dejavu/*.ttf "$TARGET_DIR/"
echo "Fonts linked to $TARGET_DIR"