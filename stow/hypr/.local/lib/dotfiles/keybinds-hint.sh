#!/usr/bin/env bash
# Show keybinding hints via rofi
# Parses bindd descriptions from hyprland config

set -euo pipefail

CONF_DIR="${HOME}/.config/hypr/conf.d"

# Parse bindd lines: bindd = MODS, KEY, DESCRIPTION, DISPATCHER, ARGS
# Output: "KEY MODS → DESCRIPTION"
grep -h '^bindd\s*=' "$CONF_DIR"/*.conf 2>/dev/null | \
    sed 's/^bindd\s*=\s*//' | \
    awk -F',' '{
        mods = $1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", mods)
        key  = $2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
        desc = $3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", desc)
        if (mods == "$mainMod")         mods = "Super"
        else if (mods == "$mainMod SHIFT") mods = "Super+Shift"
        else if (mods == "$mainMod ALT")   mods = "Super+Alt"
        else if (mods == "$mainMod CTRL")  mods = "Super+Ctrl"
        gsub(/\$mainMod/, "Super", mods)
        gsub(/ /, "+", mods)
        printf "%-25s  %s\n", mods "+" key, desc
    }' | sort | \
    rofi -dmenu -p "Keybindings" -i -no-custom
