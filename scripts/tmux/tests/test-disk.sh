#!/bin/bash
# Stress-tests disk by writing then deleting a large temp file,
# letting you watch the used% in the disk status script change.
# Usage: ./test-disk.sh [file_size_mb]  (default: 2048 MB)

SIZE_MB=${1:-2048}
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMPFILE=/tmp/disk_stress_test.tmp

echo "=== Disk Stress Test (writing ${SIZE_MB} MB to /tmp) ==="
echo "Press Ctrl+C to abort."
echo ""

cleanup() {
    echo -e "\nCleaning up..."
    rm -f "$TMPFILE"
    USAGE=$("$SCRIPT_DIR/disk")
    echo "Disk after cleanup: $USAGE"
    echo "Done."
    exit
}
trap cleanup INT TERM EXIT

BEFORE=$("$SCRIPT_DIR/disk")
echo "Disk before: $BEFORE"
echo ""

echo "Writing ${SIZE_MB} MB..."
dd if=/dev/zero of="$TMPFILE" bs=1M count="$SIZE_MB" status=progress 2>&1
echo ""

AFTER=$("$SCRIPT_DIR/disk")
echo "Disk after write: $AFTER"
echo ""

echo "Holding file for 10s so you can observe the status bar..."
for i in $(seq 10 -1 1); do
    USAGE=$("$SCRIPT_DIR/disk")
    printf "\rDisk: %-8s  deleting in %ds   " "$USAGE" "$i"
    sleep 1
done
echo ""
