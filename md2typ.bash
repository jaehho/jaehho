md2typ() {
    if [ -t 0 ] && [ -z "$*" ]; then
        echo "Usage: md2typ 'your markdown text'"
        echo "       or use: echo 'text' | md2typ"
        return 1
    fi

    # Create a temporary file
    tmpfile=$(mktemp)

    # If text is piped, read from stdin; otherwise, use the argument safely
    if [ -t 0 ]; then
        # Use printf instead of echo to preserve all characters including '$'
        printf "%s" "$*" > "$tmpfile"
    else
        cat > "$tmpfile"
    fi

    # Perform bracket replacements before conversion
    sed -E 's/\\\( /$ /g; s/ \\\)/ $/g; s/\\\(|\\\)/$/g; s/\\\[|\\\]/$$/g' "$tmpfile" > "$tmpfile.tmp"
    mv "$tmpfile.tmp" "$tmpfile"

    # # Echo the modified Markdown
    # echo "Modified Markdown:" 
    # echo "------------------------"
    # cat "$tmpfile"
    # echo ""
    # echo "------------------------"

    # Convert Markdown to Typst
    output=$(pandoc "$tmpfile" -f markdown -t typst)

    # Display the converted output
    echo "Converted Typst Output:"
    echo "------------------------"
    echo "$output"
    echo "------------------------"

    # Copy to clipboard
    echo "$output" | xclip -selection clipboard

    # Cleanup temporary file
    rm "$tmpfile"

    echo -e "\U2705 Copied to clipboard!"
}
