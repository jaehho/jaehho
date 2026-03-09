# Testing Patterns

**Analysis Date:** 2026-03-08

## Overview

This repository uses manual integration/stress tests written as Bash scripts. There is no automated unit test framework (no pytest, bats, shunit2, jest, etc.). Tests exist exclusively for the tmux status bar scripts and are designed to be run interactively to visually verify that scripts report correct values under load.

## Test Framework

**Runner:** None (manual execution)

**Assertion Library:** None — tests assert by visual inspection of terminal output

**Run Commands:**
```bash
# Run a specific test directly
./scripts/tmux/tests/test-cpu.sh [duration_seconds]
./scripts/tmux/tests/test-disk.sh [file_size_mb]
./scripts/tmux/tests/test-gpu.sh [duration_seconds]
./scripts/tmux/tests/test-netspeed.sh [duration_seconds] [down_workers] [up_workers]
./scripts/tmux/tests/test-ram.sh [duration_seconds] [alloc_mb]
```

There is no Makefile target to run tests. Tests must be executed directly from a shell.

## Test File Organization

**Location:** `scripts/tmux/tests/`

**Naming:** `test-<script-name>.sh` — one test file per tmux status script

**Structure:**
```
scripts/
└── tmux/
    ├── cpu
    ├── disk
    ├── gpu
    ├── netspeed
    ├── ram
    ├── yank
    └── tests/
        ├── test-cpu.sh
        ├── test-disk.sh
        ├── test-gpu.sh
        ├── test-netspeed.sh
        └── test-ram.sh
```

Each test file corresponds 1:1 to a status script in the parent directory.

## Test Structure

**Pattern:** Each test script follows this structure:

1. Parse optional arguments with defaults
2. Locate sibling scripts via `SCRIPT_DIR`
3. Print a banner (`=== Script Name (params) ===`)
4. Set up prerequisites / validate environment
5. Spawn a background stressor process
6. Register a `cleanup` trap for `INT TERM EXIT`
7. Poll the target status script in a real-time loop, printing to the same terminal line
8. Exit cleanly when the timer expires

```bash
#!/bin/bash
# Stress-tests CPU and shows the cpu status script output in real time.
# Usage: ./test-cpu.sh [duration_seconds]  (default: 30)

DURATION=${1:-30}
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NCPU=$(nproc 2>/dev/null || echo 4)

echo "=== CPU Stress Test (${DURATION}s, ${NCPU} cores) ==="
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
```

## Stressor Techniques

**CPU (`test-cpu.sh`):**
- Spawns one `yes > /dev/null` busy-loop per core using `nproc`
- All PIDs tracked in an array for cleanup

**Disk (`test-disk.sh`):**
- Writes a large temp file with `dd if=/dev/zero` to `/tmp`
- Holds for 10 seconds then deletes via `cleanup` trap
- Prints disk usage before and after write

**GPU (`test-gpu.sh`):**
- Validates `nvidia-smi` and PyTorch CUDA availability before starting
- Spawns a background Python process running repeated 4096x4096 CUDA matrix multiplications
- Provides corrective error message with install command if CUDA unavailable:
  ```bash
  echo "  uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu130"
  ```

**Network (`test-netspeed.sh`):**
- Spawns configurable parallel `curl` download workers against Cloudflare speed test endpoints
- Spawns upload workers streaming `/dev/zero` via `dd | curl -T -`
- Automatically restarts any worker that finishes early (connection closed or 100 MB limit hit)
- Uses `declare -A DOWN_PIDS UP_PIDS` associative arrays for worker PID tracking

**RAM (`test-ram.sh`):**
- Spawns a background `python3 -c` process that allocates a `bytearray` of configurable size
- Monitors that the Python PID is still alive (`kill -0 "$PY_PID"`) as part of the loop condition

## Cleanup Pattern

All tests register a cleanup function that:
1. Kills all background stressor PIDs
2. Waits for them to exit
3. Removes any temp files
4. Calls `exit`

Trap always covers `INT`, `TERM`, and `EXIT`:
```bash
trap cleanup INT TERM EXIT
```

## Mocking

Not applicable — tests exercise real hardware/system resources directly. No mocking framework is used.

## Fixtures and Factories

Not applicable — test data is generated on-the-fly (random temp files, `/dev/zero`, PyTorch random tensors, `yes` busy-loops).

## Coverage

**Requirements:** None enforced. No coverage tooling configured.

**Covered:**
- `scripts/tmux/cpu` — `test-cpu.sh`
- `scripts/tmux/disk` — `test-disk.sh`
- `scripts/tmux/gpu` — `test-gpu.sh`
- `scripts/tmux/netspeed` — `test-netspeed.sh`
- `scripts/tmux/ram` — `test-ram.sh`

**Not covered by tests:**
- `scripts/tmux/yank` — no test; clipboard behavior is platform-dependent
- `scripts/ice/mount.sh` — no test; requires live ICE server credentials
- `scripts/ice/ssh.exp` — no test; requires live ICE server
- `scripts/zotero/sync.sh` — no test; requires WSL environment and mounted Windows path
- `scripts/fix-cv2-fonts.sh` — no test; requires active Python venv with cv2 installed
- All Makefile targets — no automated verification of systemd service management or setup steps

## Test Types

**Unit Tests:** None

**Integration Tests:** None (automated)

**Stress / Smoke Tests:** All 5 test scripts in `scripts/tmux/tests/` are interactive stress tests that produce visual output confirming the monitored metric changes under load.

**E2E Tests:** Not used

## Adding New Tests

When adding a new tmux status script, follow this pattern:

1. Create `scripts/tmux/tests/test-<scriptname>.sh`
2. Include a usage comment at the top with all accepted arguments and defaults
3. Set `SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"` for portable sibling invocation
4. Accept `DURATION` (or equivalent) as `${1:-30}` with a sensible default
5. Print a `=== Banner ===` header
6. Validate dependencies with `command -v <tool>` before starting
7. Spawn a background stressor and capture its PID
8. Register `trap cleanup INT TERM EXIT`
9. Poll `"$SCRIPT_DIR/<scriptname>"` every second with `printf "\r..."` for in-place display

---

*Testing analysis: 2026-03-08*
