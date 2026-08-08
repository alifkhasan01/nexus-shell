#!/usr/bin/env bash
#
# screenshot.sh - wrapper grimblast untuk screenshot select & full
#
# Dependencies: grimblast, wl-clipboard (opsional, buat copy), libnotify (opsional, buat notif)
#
# Usage:
#   ./screenshot.sh select   # screenshot area/window yang diselect
#   ./screenshot.sh full     # screenshot seluruh output aktif
#   ./screenshot.sh output   # screenshot output tertentu (dipilih)
#
# Bisa juga langsung bind ke keybind Hyprland, contoh di hyprland.conf:
#   bind = , Print, exec, ~/.config/scripts/screenshot.sh full
#   bind = SHIFT, Print, exec, ~/.config/scripts/screenshot.sh select

set -euo pipefail

MODE="${1:-select}"
SAVE_DIR="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
FILENAME="screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
FILEPATH="$SAVE_DIR/$FILENAME"

mkdir -p "$SAVE_DIR"

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send "Screenshot" "$1" -i "$FILEPATH" 2>/dev/null || true
}

if ! command -v grimblast >/dev/null 2>&1; then
    echo "grimblast tidak ditemukan. Install dulu, misal:"
    echo "  yay -S grimblast-git"
    exit 1
fi

case "$MODE" in
    select)
        # copy ke clipboard + save ke file
        grimblast --notify copysave area "$FILEPATH"
        ;;
    full)
        grimblast --notify copysave screen "$FILEPATH"
        ;;
    output)
        grimblast --notify copysave output "$FILEPATH"
        ;;
    active)
        # screenshot window yang lagi fokus
        grimblast --notify copysave active "$FILEPATH"
        ;;
    *)
        echo "Mode tidak dikenal: $MODE"
        echo "Gunakan: select | full | output | active"
        exit 1
        ;;
esac

if [ -f "$FILEPATH" ]; then
    notify "Tersimpan di $FILEPATH dan disalin ke clipboard"
    echo "Screenshot tersimpan: $FILEPATH"
else
    notify "Screenshot dibatalkan"
fi
