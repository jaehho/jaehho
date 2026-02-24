#!/bin/bash
# Stress-tests GPU via PyTorch CUDA and shows the gpu status script output.
# Usage: ./test-gpu.sh [duration_seconds]  (default: 30)

DURATION=${1:-30}
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== GPU Stress Test (${DURATION}s) ==="

if ! command -v nvidia-smi &>/dev/null; then
    echo "ERROR: nvidia-smi not found."
    exit 1
fi

if ! python3 -c "import torch; assert torch.cuda.is_available()" &>/dev/null 2>&1; then
    echo "ERROR: PyTorch CUDA unavailable. Install with:"
    echo "  uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu130"
    exit 1
fi

echo "Stressor: PyTorch CUDA matrix multiply"
echo "Press Ctrl+C to stop early."
echo ""

STRESS_PID=""

python3 - "$DURATION" <<'EOF' &
import sys, time, torch
device = torch.device("cuda")
end = time.time() + int(sys.argv[1])
while time.time() < end:
    a = torch.randn(4096, 4096, device=device)
    b = torch.randn(4096, 4096, device=device)
    torch.mm(a, b); torch.cuda.synchronize()
EOF
STRESS_PID=$!

cleanup() {
    echo -e "\nStopping stressor..."
    [[ -n "$STRESS_PID" ]] && kill "$STRESS_PID" 2>/dev/null && wait "$STRESS_PID" 2>/dev/null
    echo "Done."
    exit
}
trap cleanup INT TERM EXIT

END=$((SECONDS + DURATION))
while [[ $SECONDS -lt $END ]]; do
    USAGE=$("$SCRIPT_DIR/gpu")
    printf "\rGPU: %3s%%   remaining: %ds   " "$USAGE" $((END - SECONDS))
    sleep 1
done
echo ""
