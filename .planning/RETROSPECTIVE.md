# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — Cross-Distro Fix

**Shipped:** 2026-03-09
**Phases:** 2 | **Plans:** 4 | **Sessions:** 1

### What Was Built
- Fixed all 5 tmux status scripts for Ubuntu/Fedora compatibility (`cpu`, `gpu`, `ram`, `disk`, `netspeed`)
- 12-test bats suite with full mock coverage — runs in 0.42s, CI-safe, no real hardware needed
- `make test` target with bats install guard and top-level PATH export

### What Worked
- TDD-first approach (Wave 0 RED stubs) made verification mechanical — tests failing = confidence what to fix
- GSD executor auto-fixed the GPU absent PATH bug without intervention: correctly identified that global `export PATH` broke bats teardown, used subprocess-scoped `run env PATH=...` instead
- Env var hook pattern (`PROC_NET_DEV_1/2`, `SLEEP_INTERVAL`) is clean and non-invasive — scripts work normally in production, injectable in tests
- Phase 1 UAT caught 2 gaps (nvidia-smi present-but-failing, /proc/stat fallback) before phase 2 started

### What Was Inefficient
- Phase 2 was initially planned as a standalone "bats test suite" phase when it was actually gap closure for Phase 1 tests — slightly redundant framing
- `test-*.sh` manual runners were left alongside bats — could be removed as dead code

### Patterns Established
- **Mock bin pattern**: `MOCK_BIN=$(mktemp -d)` + fake executables + `PATH="$MOCK_BIN:$PATH"` — standard for all future bash test suites
- **Subprocess PATH scoping**: Always use `run env PATH="$MOCK_BIN" "$SCRIPT"` when testing PATH-sensitive behavior, never global export
- **Fixture injection via env vars**: Add `${VARNAME:-default}` hooks to scripts for test fixture injection without branching logic
- **SLEEP_INTERVAL=0**: Any script with a sleep should accept an env var override for CI safety

### Key Lessons
1. **PATH scoping in bats**: Global `export PATH` in `setup()` breaks bats teardown — always scope to the subprocess under test
2. **Locale-agnostic parsing**: Any script parsing floating-point numbers from system tools should prefix `LC_ALL=C` to force dot decimal separators
3. **Two-fixture delta tests**: Testing scripts that diff two reads (like netspeed) needs two fixture env vars (`_1`, `_2`), not one

### Cost Observations
- Model mix: 100% sonnet (balanced profile)
- Sessions: 1 (phases 1–2 completed in one context-cleared chain)
- Notable: Parallel wave execution + executor agents kept orchestrator context at ~15%; each executor got fresh 200k window

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 2 | 4 | First milestone — TDD-first bash scripting pattern established |

### Cumulative Quality

| Milestone | Tests | Coverage | Scripts Fixed |
|-----------|-------|----------|---------------|
| v1.0 | 12 | All 5 scripts | 3 (cpu, gpu, netspeed) |

### Top Lessons (Verified Across Milestones)

1. Subprocess-scoped PATH isolation is the correct pattern for bash mock testing (bats teardown breaks with global export)
2. Env var injection hooks in scripts enable clean fixture testing without production branching
