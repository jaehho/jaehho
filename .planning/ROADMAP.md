# Roadmap: Tmux Status Bar Cross-Distro Fix

## Overview

Two phases of focused work: first fix all 5 status bar scripts to produce correct output on both Ubuntu and Fedora, then write bats unit tests with mocked system commands to lock in that correctness without requiring real hardware. When both phases are done, every widget works and every regression is caught automatically.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Script Fixes** - Make all 5 status scripts output correctly on Ubuntu and Fedora
- [ ] **Phase 2: Bats Test Suite** - Automated tests with mocked commands verify all scripts without real hardware

## Phase Details

### Phase 1: Script Fixes
**Goal**: Every tmux widget outputs a correctly formatted value on both Ubuntu and Fedora
**Depends on**: Nothing (first phase)
**Requirements**: SCRP-01, SCRP-02, SCRP-03, SCRP-04, SCRP-05, SCRP-06, SCRP-07
**Success Criteria** (what must be TRUE):
  1. The cpu script run in a Fedora locale environment (comma decimal separator) outputs a valid integer between 0 and 100, not empty output
  2. The gpu script outputs a valid integer (0–100) when nvidia-smi is available, and outputs a graceful fallback string (e.g., N/A) when nvidia-smi is absent or fails
  3. The ram script outputs a valid integer (0–100) on both Ubuntu and Fedora
  4. The disk script outputs a valid percentage string (e.g., 42%) on both Ubuntu and Fedora
  5. The netspeed script outputs a valid KB/s string (e.g., ↓12 ↑3 KB/s) on both Ubuntu and Fedora
**Plans**: 3 plans

Plans:
- [ ] 01-01-PLAN.md — Wave 0: create failing bats test stubs for all 5 scripts and add make test target
- [ ] 01-02-PLAN.md — Wave 1a: fix cpu (LC_ALL=C) and gpu (command -v guard + N/A fallback)
- [ ] 01-03-PLAN.md — Wave 1b: add PROC_NET_DEV env var to netspeed; verify ram and disk pass unchanged

### Phase 2: Bats Test Suite
**Goal**: Automated tests verify correct behavior for all 5 scripts without real hardware
**Depends on**: Phase 1
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06, TEST-07, TEST-08
**Success Criteria** (what must be TRUE):
  1. `make test` installs/invokes bats and runs the full test suite, exiting 0 when all tests pass
  2. The cpu test file covers both Ubuntu (dot) and Fedora (comma) mpstat locale formats and asserts an integer output in both cases
  3. The gpu test file covers the nvidia-smi present and absent scenarios and asserts the correct output format in each case
  4. All tests complete without real hardware (no actual nvidia-smi, GPU, or physical network interface) and without blocking sleeps
  5. Introducing a format regression in any script causes at least one bats test to fail
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Script Fixes | 1/3 | In Progress|  |
| 2. Bats Test Suite | 0/TBD | Not started | - |
