#!/usr/bin/env bash
# Auto-connect bluetooth devices that have been paired (& trusted) before.
# Loop: setiap INTERVAL detik, jika adapter powered on:
#   - auto-trust perangkat paired yang belum trusted (wajib agar reconnect lancar)
#   - coba connect perangkat paired+trusted yang belum connected
#
# Suppression file: $XDG_RUNTIME_DIR/qs-bt-autoconnect.skip
#   Format per baris: "<addr> <unix_ts>" — alamat yang diputus manual oleh user
#   lewat panel tidak akan di-reconnect otomatis selama 5 menit.
set -u

INTERVAL="${QS_BT_AUTOCONNECT_INTERVAL:-15}"
SKIP_TTL=300
RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}"
SKIP_FILE="$RUN_DIR/qs-bt-autoconnect.skip"
LOG="$RUN_DIR/qs-bt-autoconnect.log"

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >> "$LOG"; }

now() { date +%s; }

is_skipped() {
    [ -f "$SKIP_FILE" ] || return 1
    local addr="$1" ts limit
    ts=$(awk -v a="$addr" '$1 == a { print $2 }' "$SKIP_FILE" | tail -n1)
    [ -z "$ts" ] && return 1
    limit=$(( $(now) - SKIP_TTL ))
    if [ "$ts" -lt "$limit" ]; then
        # entri kadaluarsa — bersihkan
        awk -v a="$addr" '$1 != a' "$SKIP_FILE" > "$SKIP_FILE.tmp" \
            && mv "$SKIP_FILE.tmp" "$SKIP_FILE"
        return 1
    fi
    return 0
}

log "auto-connect loop started (interval=${INTERVAL}s)"

while true; do
    if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
        while read -r _ addr _rest; do
            [ -n "${addr:-}" ] || continue

            info=$(bluetoothctl info "$addr" 2>/dev/null) || continue

            if ! echo "$info" | grep -q 'Connected: yes'; then
                # Auto-trust supaya device boleh reconnect tanpa konfirmasi
                if ! echo "$info" | grep -q 'Trusted: yes'; then
                    bluetoothctl trust "$addr" >/dev/null 2>&1 && log "trusted $addr"
                fi

                if is_skipped "$addr"; then
                    log "skip $addr (diputus manual, belum lewat TTL)"
                    continue
                fi

                name=$(echo "$info" | sed -n 's/^[[:space:]]*Name:[[:space:]]*//p')
                log "trying $addr (${name:-?})"
                if timeout "${QS_BT_CONNECT_TIMEOUT:-8}" bluetoothctl connect "$addr" >/dev/null 2>&1; then
                    log "connected $addr (${name:-?})"
                fi
            fi
        done < <(bluetoothctl devices Paired 2>/dev/null)
    fi
    sleep "$INTERVAL"
done
