#!/usr/bin/env bash
# record.sh — wf-recorder dengan audio gabungan: desktop (monitor) + mic
#
# Cara kerja:
#   1. Buat PipeWire null-sink bernama "qs_rec_mix"
#   2. Loopback default sink monitor  → null-sink (dapat audio desktop)
#   3. Loopback default mic source    → null-sink (dapat audio mic)
#   4. wf-recorder dari monitor null-sink (dapat keduanya sekaligus)
#   5. Saat stop: cleanup semua modul yang dibuat
#
# Argumen: record.sh [desktop-only|mic-only|both(default)]
#   desktop-only  = hanya suara desktop, tanpa mic
#   mic-only      = hanya mic, tanpa desktop
#   both          = gabungan (default)
#
# Stop recording (saat sudah jalan): jalankan script ini lagi, akan
# otomatis kill wf-recorder dan cleanup.

MODE="${1:-both}"
OUTDIR="$HOME/Videos/Recordings"
mkdir -p "$OUTDIR"

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export PULSE_RUNTIME_PATH="$XDG_RUNTIME_DIR/pulse"

# ── Jika wf-recorder sudah jalan, stop dan cleanup ──────────────────────
if pgrep -x wf-recorder > /dev/null; then
    pkill -INT wf-recorder
    sleep 0.5
    # Cleanup modul yang tersimpan di tmpfile
    TMPFILE="$XDG_RUNTIME_DIR/qs_rec_modules"
    if [[ -f "$TMPFILE" ]]; then
        while IFS= read -r mod_id; do
            pactl unload-module "$mod_id" 2>/dev/null
        done < "$TMPFILE"
        rm -f "$TMPFILE"
    fi
    exit 0
fi

# ── Start recording ──────────────────────────────────────────────────────
TMPFILE="$XDG_RUNTIME_DIR/qs_rec_modules"
> "$TMPFILE"   # reset

SINK_NAME="qs_rec_mix"

# Ambil default sink & source saat ini
DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
DEFAULT_SOURCE=$(pactl get-default-source 2>/dev/null)

if [[ -z "$DEFAULT_SINK" ]]; then
    DEFAULT_SINK="@DEFAULT_SINK@"
fi
if [[ -z "$DEFAULT_SOURCE" ]]; then
    DEFAULT_SOURCE="@DEFAULT_SOURCE@"
fi

if [[ "$MODE" == "desktop-only" ]]; then
    # ── Desktop only: langsung pakai monitor dari default sink ───────────
    AUDIO_DEVICE="${DEFAULT_SINK}.monitor"

elif [[ "$MODE" == "mic-only" ]]; then
    # ── Mic only: langsung dari default source ───────────────────────────
    AUDIO_DEVICE="$DEFAULT_SOURCE"

else
    # ── Both: buat null-sink, loopback desktop + mic ke dalamnya ─────────

    # Buat null sink (virtual mixer)
    NULL_MOD=$(pactl load-module module-null-sink \
        sink_name="$SINK_NAME" \
        sink_properties="device.description='QS\ Rec\ Mix'" \
        2>/dev/null)
    if [[ -z "$NULL_MOD" ]]; then
        # Fallback kalau null-sink gagal — pakai monitor saja
        AUDIO_DEVICE="${DEFAULT_SINK}.monitor"
        setsid -f wf-recorder \
            --audio-backend=pipewire \
            --audio="$AUDIO_DEVICE" \
            -C libopus -R 48000 \
            -f "$OUTDIR/$(date +%Y%m%d_%H%M%S).mkv" \
            </dev/null >/dev/null 2>&1 &
        exit 0
    fi
    echo "$NULL_MOD" >> "$TMPFILE"

    # Loopback: desktop monitor → null sink
    LB_DESK=$(pactl load-module module-loopback \
        source="${DEFAULT_SINK}.monitor" \
        sink="$SINK_NAME" \
        latency_msec=1 \
        2>/dev/null)
    [[ -n "$LB_DESK" ]] && echo "$LB_DESK" >> "$TMPFILE"

    # Loopback: mic → null sink
    LB_MIC=$(pactl load-module module-loopback \
        source="$DEFAULT_SOURCE" \
        sink="$SINK_NAME" \
        latency_msec=1 \
        2>/dev/null)
    [[ -n "$LB_MIC" ]] && echo "$LB_MIC" >> "$TMPFILE"

    # Record dari monitor null-sink (berisi desktop + mic)
    AUDIO_DEVICE="${SINK_NAME}.monitor"
fi

setsid -f wf-recorder \
    --audio-backend=pipewire \
    --audio="$AUDIO_DEVICE" \
    -C libopus -R 48000 \
    -f "$OUTDIR/$(date +%Y%m%d_%H%M%S).mkv" \
    </dev/null >/dev/null 2>&1 &
