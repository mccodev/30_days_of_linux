#!/bin/bash
# Simulated Data Pipeline for systemd practice
# Handles SIGTERM gracefully and logs structured output

set -euo pipefail

# --- Graceful shutdown handler ---
cleanup() {
    echo "[WARN] Received SIGTERM — shutting down gracefully"
    echo "[INFO] Partial state saved (mock)"
    exit 0
}
trap 'cleanup' TERM

# --- Config ---
CONFIG_FILE="${1:-./pipeline.conf}"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

ENV="${PIPELINE_ENV:-development}"
BATCH_SIZE="${BATCH_SIZE:-100}"
FAIL_CHANCE="${FAIL_CHANCE:-0}"   # 0-100 probability of simulated failure

# --- Start ---
echo "[INFO] Pipeline started"
echo "[INFO] Environment: $ENV"
echo "[INFO] Batch size: $BATCH_SIZE"
echo "[INFO] PID: $$"

# --- Simulate processing ---
for i in $(seq 1 "$BATCH_SIZE"); do
    echo "[INFO] Processing record $i/$BATCH_SIZE"
    sleep 0.05
done

# --- Simulated failure (for testing Restart=on-failure) ---
if (( RANDOM % 100 < FAIL_CHANCE )); then
    echo "[ERROR] Simulated pipeline failure!"
    exit 1
fi

echo "[INFO] Pipeline completed successfully"
exit 0
