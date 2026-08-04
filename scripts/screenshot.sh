#!/usr/bin/env bash
# Screenshot dengan slurp (pilih area) + grim, simpan ke ~/Pictures/
mkdir -p "$HOME/Pictures"
REGION=$(slurp 2>/dev/null) || exit 1
FILE="$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
grim -g "$REGION" "$FILE" && \
    notify-send -a "Screenshot" -i "camera-photo" "Screenshot tersimpan" "$(basename "$FILE")" -t 3000
