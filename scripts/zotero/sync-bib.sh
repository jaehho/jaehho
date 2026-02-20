#!/bin/bash
last_source=""
src="/mnt/c/Users/jaeho/wsl_link/Neuroscience.bib"
dst="$HOME/neuro/paper/references.bib"

while true; do
    source_hash=$(md5sum "$src" | cut -d' ' -f1)

    if [ -f "$dst" ]; then
        target_hash=$(md5sum "$dst" | cut -d' ' -f1)
    else
        target_hash=""
    fi

    if [ "$source_hash" != "$last_source" ] || [ "$source_hash" != "$target_hash" ]; then
        cp "$src" "$dst"
        echo "Updated references.bib"
        last_source=$source_hash
    fi
    sleep 5
done