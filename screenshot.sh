#!/usr/bin/env bash
# Screenshot dengan slurp (pilih area) + grim, simpan ke ~/Pictures/
mkdir -p "$HOME/Pictures"
REGION=$(slurp 2>/dev/null) || exit 1
grim -g "$REGION" "$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
