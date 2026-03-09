---
phase: 01-script-fixes
plan: 03
subsystem: testing
tags: [bats, bash, proc-net-dev, tmux, netspeed]

# Dependency graph
requires:
  - phase: 01-script-fixes plan 01
    provides: bats test files for ram, disk, netspeed scripts

provides:
  - PROC_NET_DEV env var injection in netspeed script
  - All 3 bats test files (ram, disk, netspeed) passing GREEN
  - SCRP-05, SCRP-06, SCRP-07 verified

affects:
  - 01-script-fixes (cpu and gpu plans if make test is run together)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Environment variable injection for testability: PROC_NET_DEV=${PROC_NET_DEV:-/proc/net/dev}"
    - "bats tests use fixture files via env var to mock kernel proc files"

key-files:
  created: []
  modified:
    - scripts/tmux/netspeed

key-decisions:
  - "netspeed test verifies format only (delta=0 is acceptable since fixture file is read twice with same data)"
  - "PROC_NET_DEV env var uses bash default-value expansion pattern: var=${var:-default}"
  - "sleep 1 preserved in netspeed per plan — EXT-03 defers that optimization"

patterns-established:
  - "Kernel proc file injection: use PROC_VAR=${PROC_VAR:-/proc/path} and quote all uses as \"$PROC_VAR\""

requirements-completed: [SCRP-05, SCRP-06, SCRP-07]

# Metrics
duration: 1min
completed: 2026-03-09
---

# Phase 1 Plan 03: Script Fixes - RAM/Disk/Netspeed Bats Tests GREEN Summary

**PROC_NET_DEV env var added to netspeed for fixture injection; ram.bats (2 tests) and disk.bats (2 tests) pass unchanged; all 5 bats tests GREEN**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-09T03:41:16Z
- **Completed:** 2026-03-09T03:42:09Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Verified ram and disk scripts correct on Fedora 43 without any changes — both bats test files (4 tests total) exit 0
- Added `PROC_NET_DEV="${PROC_NET_DEV:-/proc/net/dev}"` declaration and substituted all 4 `/proc/net/dev` literals in netspeed with `"$PROC_NET_DEV"`
- All 5 bats tests (ram x2, disk x2, netspeed x1) now exit 0 — SCRP-05, SCRP-06, SCRP-07 GREEN

## Task Commits

Each task was committed atomically:

1. **Task 1: Verify ram and disk bats tests pass without script changes** - no commit (verification only, no files modified)
2. **Task 2: Add PROC_NET_DEV env var support to netspeed script** - `9e4c212` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `scripts/tmux/netspeed` - Added PROC_NET_DEV env var support; all 4 /proc/net/dev reads now use injectable path

## Decisions Made

- netspeed test verifies format only (delta=0) — fixture file is read twice with identical data, so `↓0 ↑0 KB/s` is valid output
- PROC_NET_DEV uses bash default-value expansion so no behavior change when env var is unset
- sleep 1 preserved — EXT-03 defers that optimization to a later phase

## Deviations from Plan

None — plan executed exactly as written. The TDD RED phase was noted as already passing (test passed by reading real /proc/net/dev), but the GREEN implementation was still applied as required.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- SCRP-05 (ram), SCRP-06 (disk), SCRP-07 (netspeed) all verified GREEN
- Running `bats scripts/tmux/tests/ram.bats scripts/tmux/tests/disk.bats scripts/tmux/tests/netspeed.bats` exits 0
- Phase 01 completion now awaits cpu and gpu script fixes (Plans 02 and 04 if applicable)

## Self-Check: PASSED

- FOUND: .planning/phases/01-script-fixes/01-03-SUMMARY.md
- FOUND: scripts/tmux/netspeed (with 6 PROC_NET_DEV references)
- FOUND: commit 9e4c212 (feat: PROC_NET_DEV support)
- FOUND: commit 75fb8f7 (docs: plan metadata)

---
*Phase: 01-script-fixes*
*Completed: 2026-03-09*
