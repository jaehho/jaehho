#!/usr/bin/env bash
# Brightness control with OSD notification (Mako progress bar)
# Usage: brightnesscontrol.sh {up|down}
# Smart stepping: 1% below 10%, 5% above

set -euo pipefail

get_brightness() {
    brightnessctl -m | cut -d, -f4 | tr -d '%'
}

send_notification() {
    local val icon
    val=$(get_brightness)

    if [ "$val" -ge 70 ]; then
        icon="display-brightness-high"
    elif [ "$val" -ge 30 ]; then
        icon="display-brightness-medium"
    else
        icon="display-brightness-low"
    fi

    notify-send -a "Brightness" -h string:x-canonical-private-synchronous:brightness \
        -h int:value:"$val" -i "$icon" "Brightness" "${val}%"
}

case "${1:-}" in
    up)
        current=$(get_brightness)
        if [ "$current" -lt 10 ]; then
            brightnessctl -e4 -n2 set 1%+
        else
            brightnessctl -e4 -n2 set 5%+
        fi
        ;;
    down)
        current=$(get_brightness)
        if [ "$current" -le 10 ]; then
            brightnessctl -e4 -n2 set 1%-
        else
            brightnessctl -e4 -n2 set 5%-
        fi
        ;;
    *)
        echo "Usage: $(basename "$0") {up|down}" >&2
        exit 1
        ;;
esac

send_notification
