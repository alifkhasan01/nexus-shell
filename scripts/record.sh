#!/usr/bin/env bash
# record.sh — gpu-screen-recorder dengan audio desktop dan/atau mic
#
# Argumen: record.sh [both|desktop-only(default)]
#   desktop-only  = hanya suara desktop (default, left click)
#   both          = desktop + mic (right click)
#
# Deteksi stop dilakukan via pidfile — QML poll tiap 3 detik.

MODE="${1:-desktop-only}"
OUTDIR="$HOME/Videos/Recordings"
mkdir -p "$OUTDIR"

export XDG_RUNTIME_DIR="/run/user/$(id -u)"

PIDFILE="$XDG_RUNTIME_DIR/qs_gsr.pid"
LOG="$XDG_RUNTIME_DIR/qs_gsr.log"

# ── Jika sudah ada pidfile dan prosesnya masih hidup → stop ─────────────
if [[ -f "$PIDFILE" ]]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill -INT "$PID"
        # Tunggu proses benar-benar berhenti (maks 3 detik)
        for i in $(seq 1 6); do
            kill -0 "$PID" 2>/dev/null || break
            sleep 0.5
        done
        rm -f "$PIDFILE"
        echo "[record.sh] stopped PID=$PID" >> "$LOG"
        exit 0
    fi
    # PID tidak valid — pidfile stale, hapus
    rm -f "$PIDFILE"
fi

# Fallback: proses masih ada tapi pidfile hilang
if pgrep -x gpu-screen-recorder > /dev/null; then
    pkill -INT gpu-screen-recorder
    sleep 1
    rm -f "$PIDFILE"
    exit 0
fi

# ── Tentukan output file ─────────────────────────────────────────────────
OUTFILE="$OUTDIR/$(date +%Y%m%d_%H%M%S).mp4"

echo "[record.sh] MODE=$MODE" > "$LOG"
echo "[record.sh] OUTFILE=$OUTFILE" >> "$LOG"

# ── Bangun argumen audio ─────────────────────────────────────────────────
if [[ "$MODE" == "both" ]]; then
    AUDIO_ARGS=(-a "default_output|default_input")
else
    AUDIO_ARGS=(-a "default_output")
fi

echo "[record.sh] AUDIO_ARGS=${AUDIO_ARGS[*]}" >> "$LOG"

# ── Mulai recording ──────────────────────────────────────────────────────
setsid -f gpu-screen-recorder \
    -w screen \
    -f 60 \
    -k h264 \
    -q very_high \
    -c mp4 \
    "${AUDIO_ARGS[@]}" \
    -o "$OUTFILE" \
    >>"$LOG" 2>&1 &

GSR_PID=$!
echo "$GSR_PID" > "$PIDFILE"
echo "[record.sh] PID=$GSR_PID started" >> "$LOG"
