#!/usr/bin/env bash
if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
    hyprctl reload 2>&1 || true
fi
