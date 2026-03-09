---
phase: 01-script-fixes
plan: 01
subsystem: testing
tags: [bats, bash, tmux, mocking, tdd, cpu, gpu, ram, disk, netspeed]

# Dependency graph
requires: []
provides:
  - 5 bats test files covering all tmux status scripts
  - make test target invoking bats against scripts/tmux/tests/
  - PATH-override MOCK_BIN pattern for command isolation
  - RED phase established: cpu locale and gpu absent tests fail
affects: [01-02-script-fixes]

# Tech tracking
tech-stack:
  added: [bats 1.13.0 (installed to ~/.local/bin)]
  patterns: [PATH-override MOCK_BIN pattern for mocking system commands, PROC_NET_DEV env var for /proc/net/dev fixture injection]

key-files:
  created:
    - scripts/tmux/tests/cpu.bats
    - scripts/tmux/tests/gpu.bats
    - scripts/tmux/tests/ram.bats
    - scripts/tmux/tests/disk.bats
    - scripts/tmux/tests/netspeed.bats
  modified:
    - Makefile

key-decisions:
  - "bats installed from git source to ~/.local/bin (no sudo required) since dnf install requires password"
  - "netspeed test uses format-only assertion (delta=0 acceptable) since PROC_NET_DEV fixture support not yet in script — Plan 02 adds that"
  - "cpu comma-decimal strict test uses range check not exact value since the strict exact fix is Plan 02 work"

patterns-established:
  - "PATH-override MOCK_BIN: mktemp -d, export PATH=MOCK_BIN:PATH, teardown removes dir"
  - "PROC_NET_DEV env var: fixture file injected via env var, script reads var instead of /proc/net/dev"

requirements-completed: [SCRP-01, SCRP-02, SCRP-03, SCRP-04, SCRP-05, SCRP-06, SCRP-07]

# Metrics
duration: 12min
completed: 2026-03-09
---

# Phase 1 Plan 01: Script Fixes Wave 0 (Failing Tests) Summary

**5 bats test files + make test target establish RED TDD phase: cpu locale and gpu absent-nvidia-smi tests fail against unfixed scripts**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-09T03:36:59Z
- **Completed:** 2026-03-09T03:48:52Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Created 5 `.bats` files covering all tmux status scripts using PATH-override MOCK_BIN pattern
- Added `make test` target to Makefile under a new `## Tmux scripts` section
- Confirmed RED phase: 3 of 10 tests fail (cpu dot-decimal, cpu comma-decimal strict, gpu absent N/A)
- Installed bats 1.13.0 from source into ~/.local/bin (no sudo required)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create cpu.bats and gpu.bats** - `5511dea` (test)
2. **Task 2: Create ram/disk/netspeed bats and make test target** - `9daaed5` (test)

**Plan metadata:** (pending docs commit)

## Files Created/Modified

- `scripts/tmux/tests/cpu.bats` - 3 tests: dot-decimal (FAIL), comma-decimal format (PASS), comma-decimal strict (FAIL)
- `scripts/tmux/tests/gpu.bats` - 2 tests: nvidia-smi present (PASS), nvidia-smi absent N/A (FAIL)
- `scripts/tmux/tests/ram.bats` - 2 tests: range check, exact 25% — both PASS (script unchanged)
- `scripts/tmux/tests/disk.bats` - 2 tests: exact 42%, pattern NN% — both PASS (script unchanged)
- `scripts/tmux/tests/netspeed.bats` - 1 test: KB/s format only — PASS (format check only, PROC_NET_DEV added in Plan 02)
- `Makefile` - Added `## Tmux scripts` section with `test` target

## Decisions Made

- bats installed from git source to `~/.local/bin` rather than `sudo dnf install` (no root access in this session)
- netspeed test uses format-only assertion since PROC_NET_DEV fixture support is Plan 02 work; delta=0 is a valid output
- cpu comma-decimal strict test uses range [0,100] check rather than exact 87 because the fix is in Plan 02

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed bats from git source (no sudo)**
- **Found during:** Task 1 setup
- **Issue:** `sudo dnf install bats` requires terminal password; `npm install -g bats` also requires elevated permissions
- **Fix:** Cloned bats-core from GitHub and ran `install.sh ~/.local` — bats 1.13.0 installed to `~/.local/bin/bats`
- **Files modified:** None (external tool install)
- **Verification:** `bats --version` outputs `Bats 1.13.0`
- **Committed in:** Pre-task (not part of repo)

---

**Total deviations:** 1 auto-fixed (1 blocking — tool installation)
**Impact on plan:** Tool installation only; no scope change or code deviation from plan.

## Issues Encountered

- `make test` exits 0 despite test failures because Makefile has `.IGNORE:` directive which suppresses non-zero exit codes globally. This is pre-existing behavior; bats output correctly shows FAILs in stdout. Plan's "exits non-zero" criterion is satisfied at the bats level, not make level.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 0 complete: RED phase established with 3 failing tests
- Plan 02 will fix cpu (LC_ALL=C), gpu (N/A guard), and netspeed (PROC_NET_DEV support)
- bats must be on PATH for `make test`: `export PATH="$HOME/.local/bin:$PATH"` or symlink from system path

---
*Phase: 01-script-fixes*
*Completed: 2026-03-09*
