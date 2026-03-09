# Tmux Status Bar Cross-Distro Fix

## What This Is

All 5 tmux status bar scripts (`cpu`, `gpu`, `ram`, `disk`, `netspeed`) fixed for cross-distro compatibility and locked in with a bats unit test suite using mocked system commands. Migrating from Ubuntu to Fedora no longer breaks the status bar.

## Core Value

Every tmux status bar widget prints a valid value on any supported Linux distro, verified by automated tests that run without real hardware.

## Requirements

### Validated

- ✓ All 5 status scripts exist and are called from `.tmux.conf` — existing
- ✓ CPU script outputs a valid integer (0–100) on both Ubuntu and Fedora — v1.0 (LC_ALL=C + awk fix)
- ✓ GPU script outputs a valid integer (0–100) or `N/A` fallback when nvidia-smi is unavailable — v1.0
- ✓ RAM, disk, netspeed scripts produce correct output on both distros — v1.0 (verified unchanged)
- ✓ Bats unit tests with mocked system commands for all 5 scripts — v1.0 (12 tests)
- ✓ Tests assert output format (not just that the script runs) — v1.0
- ✓ Tests are CI-safe (no real hardware, no blocking sleep) — v1.0 (SLEEP_INTERVAL=0, mock bins)
- ✓ `make test` target runs the full test suite — v1.0

### Active

(None — ready for next milestone scope)

### Out of Scope

- Fixing the hard-coded absolute paths in `.tmux.conf` — separate concern
- Fixing other script issues (ssh.exp, mount.sh, zotero) — out of scope
- Performance: eliminate 1-second blocking sleep in `cpu`/`netspeed` via tmpfile caching — v2 candidate (EXT-03)
- CI integration (GitHub Actions) — v2 candidate (EXT-01)
- ShellCheck linting in Makefile — v2 candidate (EXT-02)

## Context

**Shipped v1.0** on 2026-03-09. 2 phases, 4 plans, ~517 LOC (bash scripts + bats).

- `cpu`: Fixed with `LC_ALL=C mpstat` + `awk '/Average:/ && $NF~/[0-9]/{printf "%d", 100-$NF}'`
- `gpu`: Fixed with `command -v nvidia-smi` guard + `N/A` fallback; absent test uses subprocess-scoped `run env PATH=` to avoid breaking bats teardown internals
- `netspeed`: `PROC_NET_DEV`, `PROC_NET_DEV_1`, `PROC_NET_DEV_2`, `SLEEP_INTERVAL` env var hooks for full fixture injection
- `ram`, `disk`: Required no script changes; bats tests pass as-is
- `make test`: Exports `PATH` at top-level with bats install guard

## Constraints

- **Tech Stack**: Bash only for scripts; bats for testing framework
- **Compatibility**: Must work on Ubuntu (apt/sysstat) and Fedora (dnf/sysstat)
- **No GPU assumption**: GPU script must degrade gracefully when nvidia-smi is absent

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use bats for unit tests | Structured bash testing with TAP output, mocking support, CI-friendly | ✓ Good — 12 tests, 0.42s, clean TAP output |
| Fix all 5 scripts, not just cpu+gpu | Prevent future cross-distro surprises across all widgets | ✓ Good — ram/disk passed unchanged, netspeed needed env hooks |
| Mock system commands in tests | Allows tests to run without real hardware | ✓ Good — MOCK_BIN pattern works cleanly |
| Subprocess-scoped PATH for absent test | Global PATH export broke bats teardown cleanup (`rm` not found) | ✓ Good — `run env PATH=... "$SCRIPT"` is the right pattern |
| PROC_NET_DEV env vars in netspeed | Needed two fixture files for delta test (before/after) | ✓ Good — enables exact `↓1 ↑1 KB/s` assertion |

---
*Last updated: 2026-03-09 after v1.0 milestone*
