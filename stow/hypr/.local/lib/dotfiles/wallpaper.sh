#!/usr/bin/env bash
# Wallpaper manager using swww + optional matugen theme generation
# Usage: wallpaper.sh {select|set <path>|next|prev}
#   select — pick from ~/Pictures/Wallpapers via rofi
#   set    — set a specific wallpaper file
#   next   — next wallpaper alphabetically
#   prev   — previous wallpaper alphabetically

set -euo pipefail

WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"
STATE_FILE="${HOME}/.local/state/dotfiles/current-wallpaper"
mkdir -p "$(dirname "$STATE_FILE")"

apply_wallpaper() {
    local file="$1"
    [ -f "$file" ] || { echo "File not found: $file" >&2; exit 1; }

    # Set wallpaper with animated transition
    swww img "$file" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-duration 1.5 \
        --transition-fps 60

    # Record current wallpaper
    echo "$file" > "$STATE_FILE"

    # Generate theme colors if matugen is available
    if command -v matugen &>/dev/null; then
        matugen image "$file" 2>/dev/null && {
            # Reload apps that read generated color files
            pkill -SIGUSR2 waybar 2>/dev/null || true
            makoctl reload 2>/dev/null || true
            hyprctl reload 2>/dev/null || true
        }
    fi

    notify-send -a "Wallpaper" -i preferences-desktop-wallpaper \
        "Wallpaper" "$(basename "$file")"
}

get_wallpapers() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        | sort
}

case "${1:-}" in
    select)
        wallpapers=$(get_wallpapers)
        [ -z "$wallpapers" ] && { notify-send "Wallpaper" "No wallpapers in $WALLPAPER_DIR"; exit 1; }
        selected=$(echo "$wallpapers" | while read -r f; do basename "$f"; done | rofi -dmenu -p "Wallpaper")
        [ -z "$selected" ] && exit 0
        apply_wallpaper "$WALLPAPER_DIR/$selected"
        ;;
    set)
        [ -z "${2:-}" ] && { echo "Usage: $(basename "$0") set <path>" >&2; exit 1; }
        apply_wallpaper "$2"
        ;;
    next|prev)
        wallpapers=$(get_wallpapers)
        [ -z "$wallpapers" ] && exit 1
        current=$(cat "$STATE_FILE" 2>/dev/null || echo "")
        count=$(echo "$wallpapers" | wc -l)

        if [ -z "$current" ]; then
            next=$(echo "$wallpapers" | head -1)
        else
            idx=$(echo "$wallpapers" | grep -n "^${current}$" | cut -d: -f1 || echo "0")
            if [ "$1" = "next" ]; then
                idx=$(( (idx % count) + 1 ))
            else
                idx=$(( ((idx - 2 + count) % count) + 1 ))
            fi
            next=$(echo "$wallpapers" | sed -n "${idx}p")
        fi
        apply_wallpaper "$next"
        ;;
    *)
        echo "Usage: $(basename "$0") {select|set <path>|next|prev}" >&2
        exit 1
        ;;
esac
