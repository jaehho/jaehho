#!/usr/bin/env bash
if pgrep -x waybar &>/dev/null; then
    pkill -SIGUSR2 waybar
fi
