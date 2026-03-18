#!/usr/bin/env bash
# Power menu via rofi
# Options: Lock, Suspend, Reboot, Shutdown

set -euo pipefail

choice=$(printf "Lock\nSuspend\nReboot\nShutdown" | rofi -dmenu -p "Power")

case "$choice" in
    Lock)     loginctl lock-session ;;
    Suspend)  systemctl suspend ;;
    Reboot)   systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
