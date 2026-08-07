#!/usr/bin/env bash
# record.sh — wf-recorder dengan audio desktop dan/atau mic
#
# Argumen: record.sh [both|desktop-only(default)]
#   desktop-only  = hanya suara desktop (default, left click)
#   both          = desktop + mic (right click)
#
# Stop recording: jalankan script ini lagi, otomatis stop & cleanup.

MODE="${1:-desktop-only}"
OUTDIR="$HOME/Videos/Recordings"
mkdir -p "$OUTDIR"

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export PULSE_RUNTIME_PATH="$XDG_RUNTIME_DIR/pulse"

LOG="$XDG_RUNTIME_DIR/qs_rec.log"

# ── Jika wf-recorder sudah jalan, stop dan cleanup ──────────────────────
if pgrep -x wf-recorder > /dev/null; then
    pkill -INT wf-recorder
    sleep 0.5
    TMPFILE="$XDG_RUNTIME_DIR/qs_rec_modules"
    if [[ -f "$TMPFILE" ]]; then
        while IFS= read -r mod_id; do
            pactl unload-module "$mod_id" 2>/dev/null
        done < "$TMPFILE"
        rm -f "$TMPFILE"
    fi
    exit 0
fi

# ── Resolve device names ─────────────────────────────────────────────────
# Ambil default sink dari pactl, fallback ke nama yang diketahui
DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
[[ -z "$DEFAULT_SINK" ]] && DEFAULT_SINK="alsa_output.pci-0000_03_00.6.HiFi__Speaker__sink"
DESKTOP_MONITOR="${DEFAULT_SINK}.monitor"

# Mic: cari source yang sedang RUNNING, fallback ke Mic1
MIC_SOURCE=$(pactl list short sources 2>/dev/null \
    | grep -v '\.monitor' \
    | grep 'RUNNING' \
    | awk '{print $2}' \
    | head -1)
[[ -z "$MIC_SOURCE" ]] && MIC_SOURCE=$(pactl list short sources 2>/dev/null \
    | grep -v '\.monitor' \
    | awk '{print $2}' \
    | head -1)
[[ -z "$MIC_SOURCE" ]] && MIC_SOURCE="alsa_input.pci-0000_03_00.6.HiFi__Mic1__source"

OUTFILE="$OUTDIR/$(date +%Y%m%d_%H%M%S).mp4"
SINK_NAME="qs_rec_mix"
TMPFILE="$XDG_RUNTIME_DIR/qs_rec_modules"
> "$TMPFILE"

echo "[record.sh] MODE=$MODE" > "$LOG"
echo "[record.sh] DESKTOP_MONITOR=$DESKTOP_MONITOR" >> "$LOG"
echo "[record.sh] MIC_SOURCE=$MIC_SOURCE" >> "$LOG"
echo "[record.sh] OUTFILE=$OUTFILE" >> "$LOG"

# ── Start recording ──────────────────────────────────────────────────────
if [[ "$MODE" == "desktop-only" ]]; then
    setsid -f wf-recorder \
        --audio-backend=pipewire \
        -a "$DESKTOP_MONITOR" \
        -c h264 \
        -f "$OUTFILE" \
        >>"$LOG" 2>&1 &

else
    # ── Both: null-sink untuk mix desktop + mic ──────────────────────────
    NULL_MOD=$(pactl load-module module-null-sink \
        sink_name="$SINK_NAME" \
        sink_properties="device.description='QS\ Rec\ Mix'" \
        2>/dev/null)

    if [[ -z "$NULL_MOD" ]]; then
        echo "[record.sh] WARN: null-sink gagal, fallback desktop-only" >> "$LOG"
        setsid -f wf-recorder \
            --audio-backend=pipewire \
            -a "$DESKTOP_MONITOR" \
            -c h264 \
            -f "$OUTFILE" \
            >>"$LOG" 2>&1 &
        exit 0
    fi
    echo "$NULL_MOD" >> "$TMPFILE"

    LB_DESK=$(pactl load-module module-loopback \
        source="$DESKTOP_MONITOR" \
        sink="$SINK_NAME" latency_msec=1 2>/dev/null)
    [[ -n "$LB_DESK" ]] && echo "$LB_DESK" >> "$TMPFILE"

    LB_MIC=$(pactl load-module module-loopback \
        source="$MIC_SOURCE" \
        sink="$SINK_NAME" latency_msec=1 2>/dev/null)
    [[ -n "$LB_MIC" ]] && echo "$LB_MIC" >> "$TMPFILE"

    echo "[record.sh] NULL_MOD=$NULL_MOD LB_DESK=$LB_DESK LB_MIC=$LB_MIC" >> "$LOG"

    setsid -f wf-recorder \
        --audio-backend=pipewire \
        -a "${SINK_NAME}.monitor" \
        -c h264 \
        -f "$OUTFILE" \
        >>"$LOG" 2>&1 &
fi
