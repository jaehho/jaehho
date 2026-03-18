#!/usr/bin/env bash
if command -v makoctl &>/dev/null && pgrep -x mako &>/dev/null; then
    makoctl reload
fi
