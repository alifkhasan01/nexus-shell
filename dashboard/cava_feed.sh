#!/bin/bash
# Feed cava output ke /tmp/qs-cava.out (1 baris per update) untuk MediaCard visualizer.
# Auto-detect PipeWire atau PulseAudio.

BARS=64
CONF=/tmp/qs-cava.conf
OUT=/tmp/qs-cava.out

# Deteksi audio backend
if pactl info 2>/dev/null | grep -q "PipeWire"; then
    INPUT_METHOD="pipewire"
else
    INPUT_METHOD="pulse"
fi

cat > "$CONF" <<EOF
[general]
bars = $BARS
[input]
method = $INPUT_METHOD
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 255
bar_delimiter = 32
frame_delimiter = 10
EOF

# Tulis 1 baris per frame ke OUT secara atomic (tmp → mv)
# agar QML tidak membaca baris yang belum selesai ditulis (torn frame).
TMP="${OUT}.tmp"
while true; do
    cava -p "$CONF" 2>/dev/null | while IFS= read -r line; do
        if [ -n "$line" ]; then
            printf '%s\n' "$line" > "$TMP" && mv -f "$TMP" "$OUT"
        fi
    done
    sleep 1
done
