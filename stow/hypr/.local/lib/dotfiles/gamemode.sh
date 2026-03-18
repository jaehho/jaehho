#!/usr/bin/env bash
# Toggle game mode — disable animations, reduce eye candy for performance
# Inspired by HyDE's gamemode.sh

set -euo pipefail

GAME_STATE="${HOME}/.local/state/dotfiles/gamemode"
mkdir -p "$(dirname "$GAME_STATE")"

if [ -f "$GAME_STATE" ]; then
    # Restore normal mode
    hyprctl --batch "\
        keyword animations:enabled true;\
        keyword decoration:blur:enabled true;\
        keyword decoration:shadow:enabled true;\
        keyword general:gaps_in 5;\
        keyword general:gaps_out 20;\
        keyword general:border_size 2;\
        keyword decoration:rounding 10"
    rm "$GAME_STATE"
    notify-send -a "Gamemode" "Game Mode" "Disabled — animations restored"
else
    # Enable game mode
    hyprctl --batch "\
        keyword animations:enabled false;\
        keyword decoration:blur:enabled false;\
        keyword decoration:shadow:enabled false;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
    touch "$GAME_STATE"
    notify-send -a "Gamemode" "Game Mode" "Enabled — performance mode"
fi
