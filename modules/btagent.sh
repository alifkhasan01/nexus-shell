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

for cmd in "power on" "agent on" "default-agent"; do
  echo "$cmd" >&9
  sleep 0.4
done

tail -n +1 -f "$LOG" | while read -r line; do
  case "$line" in
    *"[agent] Confirm"*|*"yes/no):"*) echo "yes" >&9 ;;
  esac
done
