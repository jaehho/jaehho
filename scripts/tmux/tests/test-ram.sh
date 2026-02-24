#!/bin/bash
# Stress-tests RAM and shows the ram status script output in real time.
# Allocates a large Python array and holds it for the duration.
# Usage: ./test-ram.sh [duration_seconds] [alloc_mb]  (defaults: 30s, 1024 MB)

DURATION=${1:-30}
ALLOC_MB=${2:-1024}
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== RAM Stress Test (${DURATION}s, allocating ${ALLOC_MB} MB) ==="
echo "Press Ctrl+C to stop early."
echo ""

# Allocate memory via Python and keep it alive for DURATION seconds
python3 -c "
import time, sys
mb = int(sys.argv[1])
secs = int(sys.argv[2])
buf = bytearray(mb * 1024 * 1024)
time.sleep(secs)
" "$ALLOC_MB" "$DURATION" &
PY_PID=$!

cleanup() {
    echo -e "\nFreeing memory..."
    kill "$PY_PID" 2>/dev/null
    wait "$PY_PID" 2>/dev/null
    echo "Done."
    exit
}
trap cleanup INT TERM EXIT

END=$((SECONDS + DURATION))
while [[ $SECONDS -lt $END ]] && kill -0 "$PY_PID" 2>/dev/null; do
    USAGE=$("$SCRIPT_DIR/ram")
    printf "\rRAM: %3s%%   remaining: %ds   " "$USAGE" $((END - SECONDS))
    sleep 1
done
echo ""
