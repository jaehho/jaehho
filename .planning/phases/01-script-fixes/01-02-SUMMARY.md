---
phase: 01-script-fixes
plan: 02
subsystem: testing
tags: [bash, bats, mpstat, nvidia-smi, locale, LC_ALL]

# Dependency graph
requires:
  - phase: 01-script-fixes
    provides: failing bats tests for cpu and gpu (Wave 0 RED baseline)
provides:
  - locale-agnostic CPU usage script using LC_ALL=C mpstat with all-row awk filter
  - GPU usage script with command -v guard and N/A fallback for absent/failing nvidia-smi
affects: [01-script-fixes, any future phase using tmux status bar scripts]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "LC_ALL=C prefix on locale-sensitive commands before awk numeric parsing"
    - "command -v guard for optional hardware binaries with graceful N/A fallback"
    - "awk /Average:.*all/ pattern to skip header rows when mock outputs both header+data"

key-files:
  created: []
  modified:
    - scripts/tmux/cpu
    - scripts/tmux/gpu

key-decisions:
  - "Used /Average:.*all/ awk filter (not /Average:/) to handle mocks that emit both header and data rows starting with Average:"
  - "Kept LC_ALL=C prefix approach (not /proc/stat alternative) per plan — minimal diff, matches research recommendation"
  - "Used command -v (not which) for nvidia-smi guard — POSIX built-in, consistent with research anti-patterns"

patterns-established:
  - "Pattern: LC_ALL=C prefix on locale-sensitive commands prevents decimal separator issues in awk arithmetic"
  - "Pattern: awk row-specific pattern matching (/Average:.*all/) is more robust than generic header-matching"
  - "Pattern: command -v guard + || echo fallback covers both absent binary and non-zero exit for optional hardware tools"

requirements-completed: [SCRP-01, SCRP-02, SCRP-03, SCRP-04]

# Metrics
duration: 2min
completed: 2026-03-08
---

# Phase 1 Plan 02: Script Fixes (cpu + gpu) Summary

**LC_ALL=C mpstat fix with all-row awk filter and command -v nvidia-smi guard turning all 5 bats tests GREEN**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-08T08:01:13Z
- **Completed:** 2026-03-08T08:03:16Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- cpu script now emits correct integer on Fedora comma-locale (12,5 idle → 87 output) and Ubuntu dot-locale (12.5 idle → 87 output)
- gpu script now outputs integer when nvidia-smi present and exactly "N/A" when absent or failing
- All 5 bats tests GREEN: 3 cpu.bats + 2 gpu.bats

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix cpu script** - `ada68cc` (feat)
2. **Task 2: Fix gpu script** - `6485dff` (feat)

## Files Created/Modified
- `scripts/tmux/cpu` - Added LC_ALL=C prefix and narrowed awk pattern to /Average:.*all/
- `scripts/tmux/gpu` - Added command -v guard, N/A exit on absence, || echo "N/A" on failure

## Decisions Made
- Used `/Average:.*all/` awk filter instead of `/Average:/` — the test mock emits two lines both starting with "Average:" (header and data), so the generic pattern matched both, causing output concatenation ("10087" instead of "87"). Narrowing to "all" matches only the data row, which is correct for real mpstat output too.
- Kept LC_ALL=C (not /proc/stat) as fix per plan and research recommendation — one-word change, minimal diff.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Narrowed awk filter from /Average:/ to /Average:.*all/ to fix double-output**
- **Found during:** Task 1 (Fix cpu script)
- **Issue:** Plan said "exactly one character change — add LC_ALL=C". However, the test mock generates two lines both starting with "Average:" (header and data row). The awk pattern `/Average:/` matched both, calling `printf "%d"` twice and concatenating output as "10087" instead of "87".
- **Fix:** Changed awk pattern from `/Average:/` to `/Average:.*all/` so only the data row is processed.
- **Files modified:** scripts/tmux/cpu
- **Verification:** `bats scripts/tmux/tests/cpu.bats` — all 3 tests pass
- **Committed in:** ada68cc (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — Bug)
**Impact on plan:** Fix was essential for correctness. The awk filter change is a minimal addition that also improves robustness against mpstat header variations. No scope creep.

## Issues Encountered
- Initial cpu fix (LC_ALL=C only) still failed tests because the awk pattern matched both "Average:" lines in the mock. Diagnosed by running the mock manually and checking awk field counts and printf calls.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SCRP-01, SCRP-02, SCRP-03, SCRP-04 verified GREEN
- Wave 1 (Plan 02) complete — scripts fixed and tested
- Phase 1 Plan 03 can proceed (ram, disk, netspeed tests + Makefile target)

## Self-Check: PASSED

- scripts/tmux/cpu: FOUND
- scripts/tmux/gpu: FOUND
- .planning/phases/01-script-fixes/01-02-SUMMARY.md: FOUND
- Commit ada68cc: FOUND
- Commit 6485dff: FOUND

---
*Phase: 01-script-fixes*
*Completed: 2026-03-08*
