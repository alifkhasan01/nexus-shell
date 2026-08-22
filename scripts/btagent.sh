#!/usr/bin/env bash
# Persistent BlueZ agent: auto-enables the default agent and answers
# confirmation prompts (numeric passkey / authorize service) with "yes",
# so bluetooth devices pair & connect without manual terminal input.
#
# Idempotent: uses flock so only one instance runs.
set -u

exec 9>/tmp/qs-bt-agent.lock
flock -n 9 || exit 0

DIR="${XDG_RUNTIME_DIR:-/tmp}"
FIFO="$DIR/qs-bt-in.fifo"
LOG="$DIR/qs-bt.log"

[ -p "$FIFO" ] || mkfifo "$FIFO"

bluetoothctl < "$FIFO" > "$LOG" 2>&1 &
BT_PID=$!

exec 9<>"$FIFO"
rm -f "$FIFO"

# NOTE: no "power on" here — adapter stays off at startup.
# User can enable it via Connect Panel / BluetoothStatus toggle.
for cmd in "agent on" "default-agent"; do
  echo "$cmd" >&9
  sleep 0.4
done

# Auto-connect perangkat yang sudah pernah dipairing (sound, dll)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/btautoconnect.sh" &
AC_PID=$!
trap 'kill "$AC_PID" 2>/dev/null; exit' INT TERM

tail -n +1 -f "$LOG" | while read -r line; do
  case "$line" in
    *"[agent] Confirm"*|*"yes/no):"*) echo "yes" >&9 ;;
  esac
done
