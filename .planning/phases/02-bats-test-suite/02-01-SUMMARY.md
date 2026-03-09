---
phase: 02-bats-test-suite
plan: 01
subsystem: testing
tags: [bats, bash, netspeed, gpu, makefile, proc-net-dev, sleep-interval]

# Dependency graph
requires:
  - phase: 01-script-fixes
    provides: all 5 tmux scripts (cpu, disk, gpu, netspeed, ram) with env-var injection hooks
provides:
  - 12 bats tests all GREEN (11 existing + 1 new netspeed delta assertion)
  - make test exits 0 without manual PATH setup
  - netspeed PROC_NET_DEV_1/2 + SLEEP_INTERVAL env var injection
  - gpu absent test isolated via subprocess-scoped PATH using env
affects: [future bats test additions, CI integration]

# Tech tracking
tech-stack:
  added: []
  patterns: [per-test PATH isolation via 'run env PATH=...' instead of 'export PATH', PROC_NET_DEV_1/2 for two-read injection, SLEEP_INTERVAL=0 in setup() for non-blocking test suites]

key-files:
  created: []
  modified:
    - scripts/tmux/netspeed
    - scripts/tmux/tests/gpu.bats
    - scripts/tmux/tests/netspeed.bats
    - Makefile

key-decisions:
  - "Use 'run env PATH=...' to scope PATH restriction to subprocess — prevents stripped PATH from affecting bats teardown and runner cleanup"
  - "Set SLEEP_INTERVAL=0 in setup() so all netspeed tests are non-blocking; PROC_NET_DEV_1/2 env vars enable exact delta assertion"
  - "export PATH := in Makefile at top level so bats at ~/.local/bin is found without manual PATH export"

patterns-established:
  - "Subprocess-scoped PATH restriction: 'run env PATH=MOCK_BIN cmd' isolates PATH without polluting the test process"
  - "Dual-fixture pattern: PROC_NET_DEV_1/2 allows injecting different before/after states for delta calculations"

requirements-completed: [TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06, TEST-07, TEST-08]

# Metrics
duration: 2min
completed: 2026-03-09
---

# Phase 2 Plan 1: Bats Test Suite Gap Closure Summary

**12 bats tests all GREEN via per-test PATH isolation (env scoping), PROC_NET_DEV_1/2 dual-fixture delta injection, and Makefile PATH export — test suite completes in 0.4s**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-09T04:56:16Z
- **Completed:** 2026-03-09T04:58:16Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Fixed gpu absent test (test 7) — was failing because exported PATH still included /usr/bin; fixed by using `run env PATH="$MOCK_BIN"` to scope restriction to subprocess only
- Added netspeed SLEEP_INTERVAL and PROC_NET_DEV_1/2 env var hooks enabling non-blocking tests and exact delta assertions
- Added second netspeed test asserting `↓1 ↑1 KB/s` exact output using two fixture files; suite completes in 0.4s (was 1s blocked on sleep)
- Fixed `make test` PATH by adding `export PATH := $(HOME)/.local/bin:$(PATH)` at Makefile top level with bats install guard

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix netspeed script — add SLEEP_INTERVAL and PROC_NET_DEV_1/2** - `70e7448` (fix)
2. **Task 2: Fix gpu.bats — per-test explicit PATH, absent test uses env scoping** - `bd5d42f` (fix)
3. **Task 3: Add netspeed delta test + Makefile PATH fix + bats guard** - `8461711` (feat)

## Files Created/Modified

- `scripts/tmux/netspeed` — Added PROC_NET_DEV_1/2 defaults chaining through PROC_NET_DEV, SLEEP_INTERVAL default (1s)
- `scripts/tmux/tests/gpu.bats` — Removed global PATH from setup(); added per-test explicit PATH; absent test uses `run env PATH=`
- `scripts/tmux/tests/netspeed.bats` — Added SLEEP_INTERVAL=0 to setup(); added delta test with two fixture files
- `Makefile` — Added `export PATH := $(HOME)/.local/bin:$(PATH)` at top level; added bats guard with install instructions

## Decisions Made

- **env scoping for PATH isolation:** Using `run env PATH="$MOCK_BIN" "$SCRIPT"` instead of `export PATH="$MOCK_BIN"` before `run`. The export approach stripped `/bin` from PATH globally in the test process, causing bats teardown's `rm` command and bats-exec-test's internal cleanup to fail with "command not found". The `run env` approach scopes PATH to only the subprocess being tested.
- **SLEEP_INTERVAL=0 in setup():** Added to setup() rather than only in the delta test so the existing format test is also non-blocking. Both tests complete in ~0ms, giving a 0.4s total suite time.
- **Dual-fixture PROC_NET_DEV_1/2 pattern:** Matches the plan's env-var injection design. Test sets both fixtures and SLEEP_INTERVAL=0 inline in the run command: `SLEEP_INTERVAL=0 PROC_NET_DEV_1=... PROC_NET_DEV_2=... run "$SCRIPT"`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed bats teardown failure caused by global PATH stripping in absent test**

- **Found during:** Task 2 (gpu.bats absent test fix)
- **Issue:** Plan specified `export PATH="$MOCK_BIN"` inside the absent test, but this global export stripped `/bin` from PATH for the bats runner process itself. Teardown's `rm` then failed with "command not found", causing exit code 1 despite all 3 tests showing `ok`.
- **Fix:** Changed absent test from `export PATH="$MOCK_BIN"; run "$SCRIPT"` to `run env PATH="$MOCK_BIN" "$SCRIPT"` — subprocess PATH scoping.
- **Files modified:** scripts/tmux/tests/gpu.bats
- **Verification:** `PATH="$HOME/.local/bin:$PATH" bats scripts/tmux/tests/gpu.bats` exits 0, all 3 tests ok
- **Committed in:** `bd5d42f` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** The plan's suggested approach (`export PATH="$MOCK_BIN"`) had a side effect that caused bats itself to fail. The `run env PATH=...` pattern is a strictly better fix — achieves the same isolation goal without polluting the test runner's environment. No scope creep.

## Issues Encountered

None beyond the deviation above.

## Next Phase Readiness

- All 12 bats tests GREEN and committed
- `make test` works without manual PATH setup
- Test suite completes in 0.4s (well under 5s requirement)
- Patterns established for any future test additions: `run env PATH=...` for isolation, dual-fixture for delta calculations
- Phase 2 plan 1 is complete; no blockers for remaining phase 2 plans

## Self-Check: PASSED

- scripts/tmux/netspeed: FOUND
- scripts/tmux/tests/gpu.bats: FOUND
- scripts/tmux/tests/netspeed.bats: FOUND
- Makefile: FOUND
- .planning/phases/02-bats-test-suite/02-01-SUMMARY.md: FOUND
- Commit 70e7448: FOUND
- Commit bd5d42f: FOUND
- Commit 8461711: FOUND

---
*Phase: 02-bats-test-suite*
*Completed: 2026-03-09*
