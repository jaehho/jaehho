#!/usr/bin/env bash
if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
    tmux source-file ~/.tmux.conf
fi
