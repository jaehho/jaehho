#!/bin/bash
# Stress-tests CPU and shows the cpu status script output in real time.
# Usage: ./test-cpu.sh [duration_seconds]  (default: 30)

DURATION=${1:-30}
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NCPU=$(nproc 2>/dev/null || echo 4)

echo "=== CPU Stress Test (${DURATION}s, ${NCPU} cores) ==="
echo "Spawning busy-loop on every core. Press Ctrl+C to stop early."
echo ""

PIDS=()
for _ in $(seq 1 "$NCPU"); do
    yes > /dev/null &
    PIDS+=($!)
done

cleanup() {
    echo -e "\nStopping stressors..."
    kill "${PIDS[@]}" 2>/dev/null
    wait "${PIDS[@]}" 2>/dev/null
    echo "Done."
    exit
}
trap cleanup INT TERM EXIT

END=$((SECONDS + DURATION))
while [[ $SECONDS -lt $END ]]; do
    USAGE=$("$SCRIPT_DIR/cpu")
    printf "\rCPU: %3s%%   remaining: %ds   " "$USAGE" $((END - SECONDS))
    sleep 1
done
echo ""
