# Tmux Status Bar Cross-Distro Fix

## What This Is

A targeted fix for the 5 tmux status bar scripts (`cpu`, `gpu`, `ram`, `disk`, `netspeed`) that broke when migrating from Ubuntu to Fedora — showing only `%` with no numbers. The goal is to make all scripts output correctly on both distros and add bats-based unit tests with mocking to prevent regressions.

## Core Value

Every tmux status bar widget prints a valid value on any supported Linux distro, verified by automated tests that run without real hardware.

## Requirements

### Validated

- ✓ All 5 status scripts exist and are called from `.tmux.conf` — existing

### Active

- [ ] CPU script outputs a valid integer (0–100) on both Ubuntu and Fedora
- [ ] GPU script outputs a valid integer (0–100) or a fallback string when nvidia-smi is unavailable
- [ ] RAM, disk, netspeed scripts verified to produce correct output on both distros
- [ ] Bats unit tests with mocked system commands for all 5 scripts
- [ ] Tests assert output format (not just that the script runs)
- [ ] Tests are CI-safe (no real hardware, no blocking sleep)
- [ ] `make test` target runs the full test suite

### Out of Scope

- Fixing the hard-coded absolute paths in `.tmux.conf` — separate concern
- Fixing other script issues (ssh.exp, mount.sh, zotero) — out of scope for this milestone
- Performance improvements (eliminating the 1-second blocking sleep) — separate concern

## Context

- The `cpu` script uses `mpstat 1 1 | awk '/Average:/{printf "%d", 100-$NF}'` — on Fedora, `mpstat` may use locale-based decimal separators (e.g., `96,50` instead of `96.50`), causing awk arithmetic to silently produce `100` or `0` and then the `printf "%d"` formats empty/broken output as nothing
- The `gpu` script uses `nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits` — may fail silently if nvidia-smi is missing or the driver stack differs on Fedora
- Existing `tests/test-*.sh` are manual stress runners that display output but make no assertions — they will be replaced by bats test suites
- Both Ubuntu and Fedora are first-class targets; scripts should auto-detect the environment

## Constraints

- **Tech Stack**: Bash only for scripts; bats for testing framework
- **Compatibility**: Must work on Ubuntu (apt/sysstat) and Fedora (dnf/sysstat)
- **No GPU assumption**: GPU script must degrade gracefully when nvidia-smi is absent

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use bats for unit tests | Structured bash testing with TAP output, mocking support, CI-friendly | — Pending |
| Fix all 5 scripts, not just cpu+gpu | Prevent future cross-distro surprises across all widgets | — Pending |
| Mock system commands in tests | Allows tests to run without real hardware (nvidia-smi, mpstat, etc.) | — Pending |

---
*Last updated: 2026-03-08 after initialization*
