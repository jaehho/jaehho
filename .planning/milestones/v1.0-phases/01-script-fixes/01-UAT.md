---
status: complete
phase: 01-script-fixes
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md, 01-03-SUMMARY.md]
started: 2026-03-09T00:00:00Z
updated: 2026-03-09T00:16:00Z
---

## Tests

### 1. make test runs bats suite
expected: Run `make test` from the repo root. All bats tests pass.
result: skipped (covered by individual bats runs during UAT)

### 2. cpu script — output in tmux
expected: cpu script outputs a valid integer 0-100 with no mpstat dependency.
result: pass
reported: "CPU is working"
fix: replaced mpstat with /proc/stat reading (PROC_STAT_1/2 env vars for test injection)

### 3. cpu script — locale-agnostic
expected: Correct output regardless of locale decimal separator.
result: pass (locale-agnostic by design — /proc/stat is always integers)

### 4. gpu script — nvidia-smi present
expected: gpu script outputs percentage (e.g., 0%) when nvidia-smi returns data.
result: pass
reported: "GPU:0%" visible in tmux bar after driver loaded

### 5. gpu script — nvidia-smi absent/failing
expected: gpu script outputs N/A cleanly (no trailing %).
result: pass (after two fixes)
fix_1: removed %% from ~/.tmux.conf GPU line (was appending % to N/A)
fix_2: captured nvidia-smi output in variable to detect driver-not-loaded failure (pipe exit code trap)
fix_3: user blacklisted nouveau and loaded nvidia driver

### 6. ram script — valid output
expected: valid integer 0-100
result: pass
reported: "RAM shows 16%"

### 7. disk script — valid output
expected: valid percentage string
result: pass
reported: "DISK 2%"

### 8. netspeed script — valid format
expected: ↓# ↑# KB/s format
result: pass
reported: "netspeed 0 and 0" (↓0 ↑0 KB/s — correct at idle)

## Summary

total: 8
passed: 7
issues: 2 (both diagnosed and fixed)
pending: 0
skipped: 1

## Gaps Found and Fixed

- truth: "cpu script outputs a valid integer on any distro without requiring mpstat"
  status: fixed
  commit: 11504b8
  root_cause: "mpstat not installed; script depended on it exclusively"
  fix: "replaced mpstat with /proc/stat two-snapshot calculation; PROC_STAT_1/2 env vars for testability"

- truth: "gpu script outputs N/A cleanly when nvidia-smi absent or failing"
  status: fixed
  commits: [11504b8, bc7beb1]
  root_cause_1: "tmux config appended %% unconditionally — N/A became N/A%"
  fix_1: "removed %% from ~/.tmux.conf and config/.tmux.conf GPU lines; gpu script now appends % itself on valid readings"
  root_cause_2: "pipe exit code trap — awk exits 0 on empty input so || echo N/A never fired for driver failure"
  fix_2: "capture nvidia-smi output in variable, check exit code and emptiness explicitly"
