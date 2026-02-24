#!/bin/bash
# Stress-tests network (download + upload) and shows the netspeed status script.
# Spawns parallel curl workers against Cloudflare's speed test endpoints.
# Usage: ./test-netspeed.sh [duration_seconds] [down_workers] [up_workers]
#        defaults: 30s, 4 download workers, 2 upload workers

DURATION=${1:-30}
N_DOWN=${2:-4}
N_UP=${3:-2}
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Cloudflare speed test endpoints
DOWN_URL="https://speed.cloudflare.com/__down?bytes=104857600"  # 100 MB chunks
UP_URL="https://speed.cloudflare.com/__up"

echo "=== Network Speed Stress Test (${DURATION}s, ${N_DOWN}↓ + ${N_UP}↑ workers) ==="
echo "Press Ctrl+C to stop early."
echo ""

declare -A DOWN_PIDS UP_PIDS
TMPFILES=()

cleanup() {
    echo -e "\nStopping all workers..."
    kill "${DOWN_PIDS[@]}" "${UP_PIDS[@]}" 2>/dev/null
    wait "${DOWN_PIDS[@]}" "${UP_PIDS[@]}" 2>/dev/null
    rm -f "${TMPFILES[@]}"
    echo "Done."
    exit
}
trap cleanup INT TERM EXIT

start_down() {
    local id=$1
    local tmp
    tmp=$(mktemp /tmp/netspeed_down_${id}.XXXXXX)
    TMPFILES+=("$tmp")
    curl -s --max-time "$((DURATION + 30))" -o "$tmp" "$DOWN_URL" &
    DOWN_PIDS[$id]=$!
}

start_up() {
    local id=$1
    # Stream zeros via PUT; -T - pipes stdin without buffering in memory
    dd if=/dev/zero bs=1M 2>/dev/null | \
        curl -s --max-time "$((DURATION + 30))" \
            -T - -o /dev/null "$UP_URL" &
    UP_PIDS[$id]=$!
}

for i in $(seq 1 "$N_DOWN"); do start_down "$i"; done
for i in $(seq 1 "$N_UP");   do start_up   "$i"; done

END=$((SECONDS + DURATION))
while [[ $SECONDS -lt $END ]]; do
    # Restart any worker that finished (100 MB exhausted or connection closed)
    for i in $(seq 1 "$N_DOWN"); do
        if ! kill -0 "${DOWN_PIDS[$i]}" 2>/dev/null; then start_down "$i"; fi
    done
    for i in $(seq 1 "$N_UP"); do
        if ! kill -0 "${UP_PIDS[$i]}" 2>/dev/null; then start_up "$i"; fi
    done

    SPEED=$("$SCRIPT_DIR/netspeed")
    printf "\rNetwork: %-28s  remaining: %ds   " "$SPEED" $((END - SECONDS))
    sleep 1
done
echo ""
