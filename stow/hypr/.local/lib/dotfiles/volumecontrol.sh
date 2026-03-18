#!/usr/bin/env bash
# Volume control with OSD notification (Mako progress bar)
# Usage: volumecontrol.sh {up|down|mute}
# Inspired by HyDE's volumecontrol.sh, simplified for wpctl-only

set -euo pipefail

STEP=5
MAX_VOL=100

get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f", $2 * 100}'
}

is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED
}

send_notification() {
    local vol icon
    vol=$(get_volume)

    if is_muted; then
        icon="audio-volume-muted"
        notify-send -a "Volume" -h string:x-canonical-private-synchronous:volume \
            -h int:value:0 -i "$icon" "Volume" "Muted"
    else
        if [ "$vol" -ge 70 ]; then
            icon="audio-volume-high"
        elif [ "$vol" -ge 30 ]; then
            icon="audio-volume-medium"
        else
            icon="audio-volume-low"
        fi
        notify-send -a "Volume" -h string:x-canonical-private-synchronous:volume \
            -h int:value:"$vol" -i "$icon" "Volume" "${vol}%"
    fi
}

case "${1:-}" in
    up)
        # Unmute if muted, then raise
        if is_muted; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
        fi
        wpctl set-volume -l "$(awk "BEGIN{printf \"%.2f\", $MAX_VOL/100}")" @DEFAULT_AUDIO_SINK@ "${STEP}%+"
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${STEP}%-"
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *)
        echo "Usage: $(basename "$0") {up|down|mute}" >&2
        exit 1
        ;;
esac

send_notification
