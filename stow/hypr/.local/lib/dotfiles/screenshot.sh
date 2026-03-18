#!/usr/bin/env bash
# Screenshot utility
# Usage: screenshot.sh {full|region|annotate}
#   full     — fullscreen to clipboard
#   region   — select region to clipboard
#   annotate — select region, open in satty for annotation, save + clipboard

set -euo pipefail

SCREENSHOT_DIR="${HOME}/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

timestamp() { date +"%Y%m%d_%H%M%S"; }

case "${1:-}" in
    full)
        grim - | wl-copy
        notify-send -a "Screenshot" -i camera-photo "Screenshot" "Fullscreen copied to clipboard"
        ;;
    region)
        grim -g "$(slurp)" - | wl-copy
        notify-send -a "Screenshot" -i camera-photo "Screenshot" "Region copied to clipboard"
        ;;
    annotate)
        local_file="$SCREENSHOT_DIR/screenshot_$(timestamp).png"
        grim -g "$(slurp)" - | satty -f - --output-filename "$local_file"
        if [ -f "$local_file" ]; then
            wl-copy < "$local_file"
            notify-send -a "Screenshot" -i camera-photo "Screenshot" "Saved to $local_file"
        fi
        ;;
    *)
        echo "Usage: $(basename "$0") {full|region|annotate}" >&2
        exit 1
        ;;
esac
