#!/usr/bin/env bash
# Clipboard manager via rofi + cliphist
# Usage: clipboard.sh [wipe]
#   (no args) — show history, paste selection
#   wipe      — clear all clipboard history

set -euo pipefail

case "${1:-}" in
    wipe)
        cliphist wipe
        notify-send -a "Clipboard" "Clipboard" "History cleared"
        ;;
    *)
        selected=$(cliphist list | rofi -dmenu -p "Clipboard" -display-columns 2)
        [ -z "$selected" ] && exit 0
        echo "$selected" | cliphist decode | wl-copy
        ;;
esac
