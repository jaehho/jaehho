# Phase 2: Bats Test Suite - Research

**Researched:** 2026-03-09
**Domain:** Bats shell testing framework, bash script test isolation, Makefile PATH
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**GPU absent test:**
- For the absent test: set `PATH="$MOCK_BIN"` only (no system dirs). `command -v nvidia-smi` fails → script outputs "N/A" and exits before reaching awk. Works because the absent codepath never calls any system binary.
- For the present test: set `PATH="$MOCK_BIN:/usr/bin:/bin"` with a working mock nvidia-smi in MOCK_BIN — real nvidia-smi is shadowed.
- For the driver-failure test: same as present but mock exits 1 with error on stderr — existing test unchanged.
- All three tests use consistent restricted PATH (MOCK_BIN always first, system dirs only where needed).

**Blocking sleep in netspeed:**
- Add `SLEEP_INTERVAL="${SLEEP_INTERVAL:-1}"` to the netspeed script; replace `sleep 1` with `sleep "$SLEEP_INTERVAL"`
- Same pattern as `CPU_SAMPLE_INTERVAL` already used in the cpu script (Phase 1 decision)
- Add `PROC_NET_DEV_1` / `PROC_NET_DEV_2` env var support to netspeed for two-file fixture injection (same pattern as PROC_STAT_1/2 in cpu)
- Tests set `SLEEP_INTERVAL=0 PROC_NET_DEV_1=fixture1 PROC_NET_DEV_2=fixture2` to run instantly and assert real delta values

**make test portability:**
- Add `PATH := $(HOME)/.local/bin:$(PATH)` at top of Makefile so bats is found without manual PATH export
- Add explicit bats check before running: if bats not found, print clear install instructions and exit 1
- Install hint: `~/.local/bin/bats not found — install with: git clone ... && ./install.sh ~/.local`

### Claude's Discretion
- Exact wording of the bats-not-found error message
- Whether to keep the existing `cpu.bats` tests as-is (they work fine) or consolidate style

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TEST-01 | Bats test suite installed and runnable via `make test` | Makefile PATH fix + bats check guard enables this |
| TEST-02 | `cpu` tests mock mpstat for both Ubuntu (dot) and Fedora (comma) locale formats and assert integer output | cpu.bats already has 3 GREEN tests covering both formats — no changes needed |
| TEST-03 | `gpu` tests mock nvidia-smi present/absent and assert correct output in both cases | gpu.bats absent test FAILING; fix via restricted PATH="$MOCK_BIN" only |
| TEST-04 | `ram` tests mock `free` output and assert integer output | ram.bats has 2 GREEN tests — no changes needed |
| TEST-05 | `disk` tests mock `df` output and assert percentage string output | disk.bats has 2 GREEN tests — no changes needed |
| TEST-06 | `netspeed` tests mock `/proc/net/dev` and assert KB/s format output | netspeed.bats needs new test with PROC_NET_DEV_1/2 and real delta assertion |
| TEST-07 | All tests pass without real hardware | GPU absent fix + existing mocks satisfy this when gpu.bats is fixed |
| TEST-08 | All tests complete without blocking sleeps (CI-safe) | SLEEP_INTERVAL env var in netspeed script + test sets SLEEP_INTERVAL=0 |
</phase_requirements>

## Summary

Phase 2 is a targeted repair and completion phase. Three concrete gaps exist in the test suite built during Phase 1. The bats framework (v1.13.0) is already installed at `~/.local/bin/bats` but the Makefile does not include that directory in PATH, so `make test` fails unless the user manually exports PATH. The GPU absent test fails because the real `/usr/bin/nvidia-smi` is present on this machine and the current PATH mask (`$MOCK_BIN:$PATH`) leaves `/usr/bin` reachable. The netspeed test completes in ~1 second due to a blocking `sleep 1` and can only assert format (delta=0), not correctness.

All three gaps have confirmed fixes that follow patterns already established in Phase 1. The solution set is small (3 files modified, 1 test rewritten, 1 test added) with no new dependencies.

**Primary recommendation:** Fix all three gaps in a single wave. The changes are independent and can be executed in any order. Start with the Makefile fix so `make test` becomes the verification command throughout.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bats-core | 1.13.0 | Shell script test framework | Already installed at `~/.local/bin/bats`; used in Phase 1 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| mktemp | system | Isolated temp directories for MOCK_BIN and fixture dirs | All tests — prevents cross-test pollution |

### Alternatives Considered
None — bats is the locked decision from Phase 1. No alternatives to research.

**No additional installation required.** bats is already at `~/.local/bin/bats`.

## Architecture Patterns

### Existing Pattern: PATH-Override MOCK_BIN
All 5 test files already use this pattern. MOCK_BIN is a `mktemp -d` directory prepended to PATH. Mock executables are written into it during `setup()` and the directory is removed in `teardown()`.

```bash
# Pattern in use across all .bats files
setup() {
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"   # standard: MOCK_BIN first, system second
  SCRIPT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/gpu"
}
teardown() {
  rm -rf "$MOCK_BIN"
}
```

### Pattern: Restricted PATH for "absent" Test
The locked decision for the GPU absent test is a variation: set `PATH="$MOCK_BIN"` (no system dirs at all). This makes `command -v nvidia-smi` return false regardless of what exists in `/usr/bin`.

```bash
@test "gpu outputs N/A when nvidia-smi is absent" {
  # Override the PATH set in setup() — strip all system dirs
  export PATH="$MOCK_BIN"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "N/A" ]
}
```

Safety: the gpu script exits immediately after the `command -v` check when nvidia-smi is absent. It never calls `awk`, `echo` with external deps, or any other system binary beyond the shell built-ins. Restricting PATH to an empty MOCK_BIN is safe for this codepath.

The present and driver-failure tests need `awk` (called by the gpu script). They must retain system dirs:
```bash
export PATH="$MOCK_BIN:/usr/bin:/bin"
```

### Pattern: Dual-File Fixture Injection for netspeed
The cpu script established PROC_STAT_1/PROC_STAT_2 for two-read fixture injection. The same pattern applies to netspeed with PROC_NET_DEV_1 and PROC_NET_DEV_2.

**Script change required** (netspeed):
```bash
# Replace the current single-file approach:
PROC_NET_DEV="${PROC_NET_DEV:-/proc/net/dev}"

# With a two-file approach:
PROC_NET_DEV_1="${PROC_NET_DEV_1:-${PROC_NET_DEV:-/proc/net/dev}}"
PROC_NET_DEV_2="${PROC_NET_DEV_2:-${PROC_NET_DEV:-/proc/net/dev}}"
SLEEP_INTERVAL="${SLEEP_INTERVAL:-1}"

R1=$(awk -v i="$IFACE:" '$1==i {print $2}' "$PROC_NET_DEV_1")
T1=$(awk -v i="$IFACE:" '$1==i {print $10}' "$PROC_NET_DEV_1")
sleep "$SLEEP_INTERVAL"
R2=$(awk -v i="$IFACE:" '$1==i {print $2}' "$PROC_NET_DEV_2")
T2=$(awk -v i="$IFACE:" '$1==i {print $10}' "$PROC_NET_DEV_2")
```

Backward compatibility: when PROC_NET_DEV_1/2 are unset, both default to PROC_NET_DEV (which defaults to `/proc/net/dev`). Real-world behavior is unchanged.

### Pattern: Known-Delta netspeed Test
With PROC_NET_DEV_1 and PROC_NET_DEV_2 pointing to different fixture files, we can assert exact output:

- Fixture 1: eth0 rx=0, tx=0
- Fixture 2: eth0 rx=1048576 (1 MiB), tx=0
- SLEEP_INTERVAL=0 so no blocking
- Expected output: `↓1024 ↑0 KB/s` (1048576 / 1024 = 1024 KB)

Or simpler: rx delta = 1024 bytes → output `↓1 ↑0 KB/s`.

### Pattern: Makefile PATH Extension
GNU Make syntax to prepend to PATH for the test target's shell:

```makefile
# At top of Makefile, before any targets:
export PATH := $(HOME)/.local/bin:$(PATH)
```

Using `export` ensures child processes (bats) inherit the updated PATH. The `:=` (simply-expanded) assignment evaluates `$(PATH)` at parse time, which is the correct Makefile idiom for PATH prepending.

The bats check in the test target:
```makefile
test: ## Run bats test suite for tmux status scripts
	@if ! command -v bats &>/dev/null; then \
		echo "bats not found — install with:"; \
		echo "  git clone https://github.com/bats-core/bats-core.git /tmp/bats-core"; \
		echo "  /tmp/bats-core/install.sh ~/.local"; \
		exit 1; \
	fi
	bats scripts/tmux/tests/
```

### Anti-Patterns to Avoid
- **Do not use `export PATH="$MOCK_BIN:$PATH"` for the absent test:** `$PATH` still contains `/usr/bin` where the real nvidia-smi lives. The whole point is to exclude system dirs entirely for the absent case.
- **Do not use a single PROC_NET_DEV fixture for delta testing:** Both reads see the same bytes; delta is always 0. This tests format but not correctness.
- **Do not use `override PATH` in Makefile instead of `export PATH :=`:** The `override` directive prevents sub-make from using a different PATH, which is overly restrictive. `export PATH :=` is sufficient.
- **Do not put PATH change inside the `test` target recipe:** PATH changes in recipes only affect that recipe's shell, not child processes launched by make. Put the `export PATH :=` at the top level.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Command mocking | Custom shim scripts per test | MOCK_BIN pattern (already in use) | Already proven in all 5 test files |
| Test isolation | Manual cleanup code | `mktemp -d` + teardown | Bats teardown runs even on test failure |
| Fixture variation | Single fixture with inline logic | Two separate fixture files (PROC_NET_DEV_1/2) | Same pattern as PROC_STAT_1/2 already in cpu |

**Key insight:** Every mechanism needed for Phase 2 already exists in the codebase. This phase is connecting existing patterns to the two remaining gaps, not inventing new infrastructure.

## Common Pitfalls

### Pitfall 1: PATH Scope in GPU Absent Test
**What goes wrong:** Test sets `export PATH="$MOCK_BIN:$PATH"` in setup(), then the absent test expects nvidia-smi to be unfindable. But `/usr/bin/nvidia-smi` exists, so the test fails (current state: test 7 fails).
**Why it happens:** The MOCK_BIN prefix only shadows commands that exist in MOCK_BIN. An empty MOCK_BIN does nothing — subsequent PATH entries still resolve.
**How to avoid:** Inside the absent test body, re-export `PATH="$MOCK_BIN"` (no system dirs). This overrides the setup() export for that specific test.
**Warning signs:** Test output shows a GPU percentage instead of "N/A".

### Pitfall 2: gpu Script Calls awk — Restricted PATH Must Include awk for Other Tests
**What goes wrong:** If PATH is restricted for the *present* test too, awk is not found and the script fails silently.
**Why it happens:** The gpu script calls `echo "$output" | awk '{printf "%d%%", $1}'`. awk lives in `/usr/bin/awk` or `/bin/awk`.
**How to avoid:** Only the *absent* test uses `PATH="$MOCK_BIN"`. Present and driver-failure tests use `PATH="$MOCK_BIN:/usr/bin:/bin"`.

### Pitfall 3: Makefile PATH Change Scope
**What goes wrong:** `PATH := $(HOME)/.local/bin:$(PATH)` placed inside a recipe instead of at the top level only affects that recipe's shell invocation, not bats as a child process.
**Why it happens:** Make recipe lines run in separate subshells. Variable assignments in recipes don't propagate to child processes.
**How to avoid:** Use `export PATH :=` at the top level of Makefile (before any target definitions). The `export` keyword makes it available to all child processes.

### Pitfall 4: Backward Compatibility of PROC_NET_DEV_1/2
**What goes wrong:** Adding PROC_NET_DEV_1/2 breaks the real script if neither is set but PROC_NET_DEV is.
**Why it happens:** If the fallback chain is `PROC_NET_DEV_1="${PROC_NET_DEV_1:-/proc/net/dev}"` (not including the existing PROC_NET_DEV var), the Phase 1 PROC_NET_DEV injection in netspeed.bats setup() stops working.
**How to avoid:** Chain the fallback: `PROC_NET_DEV_1="${PROC_NET_DEV_1:-${PROC_NET_DEV:-/proc/net/dev}}"`. This preserves all three levels: explicit PROC_NET_DEV_1, fallback to PROC_NET_DEV, final fallback to the real file.

### Pitfall 5: netspeed Test Interface Detection with Empty PROC_NET_DEV_1
**What goes wrong:** The netspeed script uses PROC_NET_DEV for the interface fallback detection (the `[[ -z "$IFACE" ]]` block). After splitting into PROC_NET_DEV_1/2, the fallback must still work.
**Why it happens:** The interface detection at the top of the script reads from PROC_NET_DEV. If we rename it but don't update the detection line, IFACE stays empty.
**How to avoid:** Keep the interface fallback reading from PROC_NET_DEV_1 (or keep a separate PROC_NET_DEV variable for the detection line). The test mock already provides ip route, so IFACE is set before the fallback is needed in tests.

### Pitfall 6: bats Not Found vs Wrong Version
**What goes wrong:** Makefile PATH fix puts `~/.local/bin` first. If a system-installed bats is older, the check passes but behavior differs.
**Why it happens:** Some distros have bats in system packages (older versions with different behavior).
**How to avoid:** The bats check in the Makefile just needs `command -v bats` — version checking is unnecessary since v1.13.0 is already installed and the features used (basic `run`, `@test`) exist in all versions ≥ 1.0.

## Code Examples

Verified patterns from existing codebase:

### GPU Test: Correct PATH for Each Scenario
```bash
# Source: scripts/tmux/tests/gpu.bats (current file — to be modified)

setup() {
  MOCK_BIN="$(mktemp -d)"
  # Note: do NOT set PATH here globally — each test sets its own PATH
  SCRIPT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/gpu"
}

teardown() {
  rm -rf "$MOCK_BIN"
}

@test "gpu outputs percentage when nvidia-smi is present" {
  cat > "$MOCK_BIN/nvidia-smi" << 'EOF'
#!/bin/bash
echo "45"
EOF
  chmod +x "$MOCK_BIN/nvidia-smi"
  export PATH="$MOCK_BIN:/usr/bin:/bin"   # include system dirs — awk needed
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+%$ ]]
}

@test "gpu outputs N/A when nvidia-smi is absent" {
  export PATH="$MOCK_BIN"                 # no system dirs — nvidia-smi unfindable
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "N/A" ]
}

@test "gpu outputs N/A when nvidia-smi fails (driver not loaded)" {
  cat > "$MOCK_BIN/nvidia-smi" << 'EOF'
#!/bin/bash
echo "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver." >&2
exit 1
EOF
  chmod +x "$MOCK_BIN/nvidia-smi"
  export PATH="$MOCK_BIN:/usr/bin:/bin"   # include system dirs — awk needed
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "N/A" ]
}
```

### netspeed Test: Known Delta Assertion
```bash
# Source: scripts/tmux/tests/netspeed.bats (new test to add)

@test "netspeed outputs exact delta when bytes change between reads" {
  local fixture1="$FIXTURE_DIR/proc_net_dev_1"
  local fixture2="$FIXTURE_DIR/proc_net_dev_2"

  # eth0 rx=0, tx=0 at t=0
  cat > "$fixture1" << 'EOF'
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
  eth0:    1024       1    0    0    0     0          0         0        0       0    0    0    0     0       0          0
EOF

  # eth0 rx=2048, tx=1024 at t=1 → delta rx=1024, tx=1024 → ↓1 ↑1 KB/s
  cat > "$fixture2" << 'EOF'
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
  eth0:    2048       2    0    0    0     0          0         0     1024       1    0    0    0     0       0          0
EOF

  SLEEP_INTERVAL=0 PROC_NET_DEV_1="$fixture1" PROC_NET_DEV_2="$fixture2" run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "↓1 ↑1 KB/s" ]
}
```

### netspeed Script: SLEEP_INTERVAL + Two-File Change
```bash
# Source: scripts/tmux/netspeed (current file — to be modified)
# Current state (lines 5-14):
PROC_NET_DEV="${PROC_NET_DEV:-/proc/net/dev}"
...
R1=$(awk ... "$PROC_NET_DEV")
T1=$(awk ... "$PROC_NET_DEV")
sleep 1
R2=$(awk ... "$PROC_NET_DEV")
T2=$(awk ... "$PROC_NET_DEV")

# After change:
PROC_NET_DEV="${PROC_NET_DEV:-/proc/net/dev}"
PROC_NET_DEV_1="${PROC_NET_DEV_1:-$PROC_NET_DEV}"
PROC_NET_DEV_2="${PROC_NET_DEV_2:-$PROC_NET_DEV}"
SLEEP_INTERVAL="${SLEEP_INTERVAL:-1}"
...
R1=$(awk ... "$PROC_NET_DEV_1")
T1=$(awk ... "$PROC_NET_DEV_1")
sleep "$SLEEP_INTERVAL"
R2=$(awk ... "$PROC_NET_DEV_2")
T2=$(awk ... "$PROC_NET_DEV_2")
```

### Makefile: PATH and Bats Check
```makefile
# Add at top of Makefile (before any targets):
export PATH := $(HOME)/.local/bin:$(PATH)

# Replace the test target:
test: ## Run bats test suite for tmux status scripts
	@if ! command -v bats &>/dev/null; then \
		echo "bats not found — install with:"; \
		echo "  git clone https://github.com/bats-core/bats-core.git /tmp/bats-core"; \
		echo "  /tmp/bats-core/install.sh ~/.local"; \
		exit 1; \
	fi
	bats scripts/tmux/tests/
```

## Current Test Status (Verified 2026-03-09)

Running `PATH="$HOME/.local/bin:$PATH" bats scripts/tmux/tests/` produces:

```
1..11
ok 1 cpu outputs integer 87 when mpstat idle is 12.5 (Ubuntu C locale)
ok 2 cpu outputs integer when mpstat idle uses comma decimal (Fedora fr locale)
ok 3 cpu outputs correct integer 87 when mpstat idle is comma-decimal 12,5 (Fedora locale strict)
ok 4 disk outputs percentage string from mocked df output
ok 5 disk outputs percentage string matching pattern NN%
ok 6 gpu outputs percentage when nvidia-smi is present
not ok 7 gpu outputs N/A when nvidia-smi is absent   ← FAILS (real nvidia-smi at /usr/bin)
ok 8 gpu outputs N/A when nvidia-smi fails (driver not loaded)
ok 9 netspeed outputs KB/s format string              ← GREEN but blocking sleep 1
ok 10 ram outputs integer 0-100 from mocked free output
ok 11 ram outputs 25 when used is 25 percent of total
```

10 of 11 tests GREEN. 1 failing. 1 additional test needed (TEST-08 delta assertion).

After Phase 2: expected 12 tests (11 existing + 1 new delta test), all GREEN.

## Don't Hand-Roll (Reinforced)

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Binary absence simulation | Unmounting /usr/bin or using chroot | PATH="$MOCK_BIN" (empty, no system dirs) | Non-destructive; bats teardown restores PATH automatically |
| Sleep skipping | Patching sleep binary | SLEEP_INTERVAL env var | Same pattern as CPU_SAMPLE_INTERVAL — already proven |
| Delta simulation | Writing to /proc/net/dev | PROC_NET_DEV_1/2 fixture files | Same pattern as PROC_STAT_1/2 in cpu script |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `export PATH="$MOCK_BIN:$PATH"` for all gpu tests | `PATH="$MOCK_BIN"` for absent test only | Phase 2 | Fixes test 7 failure on machines with real nvidia-smi |
| `sleep 1` in netspeed | `sleep "$SLEEP_INTERVAL"` | Phase 2 | Makes test suite run in <1s total |
| `bats scripts/tmux/tests/` in Makefile (no PATH) | `export PATH := $(HOME)/.local/bin:$(PATH)` + bats check | Phase 2 | `make test` works without manual PATH export |

## Open Questions

1. **netspeed interface detection line with PROC_NET_DEV_1**
   - What we know: Line 6 of netspeed uses `$PROC_NET_DEV` for the IFACE fallback detection. After adding PROC_NET_DEV_1/2, this line still reads PROC_NET_DEV.
   - What's unclear: Should the interface fallback also read from PROC_NET_DEV_1? Or keep it reading from PROC_NET_DEV since the test mock provides `ip route` and the fallback is never triggered in tests?
   - Recommendation: Keep interface fallback reading from PROC_NET_DEV (unchanged). Tests mock `ip route` so IFACE is always set. Only the R1/T1/R2/T2 reads need PROC_NET_DEV_1/2.

2. **gpu.bats setup(): global PATH or per-test PATH?**
   - What we know: Current setup() sets `export PATH="$MOCK_BIN:$PATH"` globally for all tests. The absent test needs `PATH="$MOCK_BIN"` specifically.
   - What's unclear: Whether to remove the PATH export from setup() and have each test set its own PATH explicitly.
   - Recommendation: Move PATH export out of setup() into each individual test. This makes each test's isolation requirements explicit and eliminates the subtle interaction between setup()'s PATH and the absent test's override.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bats-core 1.13.0 |
| Config file | none — bats discovers `*.bats` files in directory |
| Quick run command | `PATH="$HOME/.local/bin:$PATH" bats scripts/tmux/tests/` |
| Full suite command | `make test` (after Makefile fix) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEST-01 | `make test` runs bats and exits 0 | smoke | `make test` | ✅ Makefile exists, needs PATH fix |
| TEST-02 | cpu tests cover dot and comma mpstat formats | unit | `make test` (cpu.bats tests 1-3) | ✅ cpu.bats GREEN |
| TEST-03 | gpu tests cover present and absent nvidia-smi | unit | `make test` (gpu.bats tests 6-8) | ✅ exists, test 7 FAILING — fix required |
| TEST-04 | ram tests mock `free` and assert integer | unit | `make test` (ram.bats tests 10-11) | ✅ ram.bats GREEN |
| TEST-05 | disk tests mock `df` and assert percentage | unit | `make test` (disk.bats tests 4-5) | ✅ disk.bats GREEN |
| TEST-06 | netspeed tests mock `/proc/net/dev` and assert KB/s | unit | `make test` (netspeed.bats test 9 + new test 12) | ✅ format test exists; delta test needed |
| TEST-07 | All tests pass without real hardware | suite | `make test` exits 0 | ✅ satisfied when TEST-03 fixed |
| TEST-08 | No blocking sleeps in test suite | suite | `make test` completes in <5s | ❌ Wave 0 — netspeed script needs SLEEP_INTERVAL |

### Sampling Rate
- **Per task commit:** `PATH="$HOME/.local/bin:$PATH" bats scripts/tmux/tests/`
- **Per wave merge:** `make test` (validates full Makefile integration)
- **Phase gate:** All 12 tests GREEN + `make test` exits 0 before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `scripts/tmux/netspeed` — needs SLEEP_INTERVAL and PROC_NET_DEV_1/2 variables (TEST-08, TEST-06)
- [ ] `scripts/tmux/tests/gpu.bats` — absent test needs `PATH="$MOCK_BIN"` fix (TEST-03, TEST-07)
- [ ] `scripts/tmux/tests/netspeed.bats` — new delta assertion test needed (TEST-06, TEST-08)
- [ ] `Makefile` — needs `export PATH :=` and bats check in test target (TEST-01)

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `scripts/tmux/tests/gpu.bats`, `netspeed.bats`, `cpu.bats`, `ram.bats`, `disk.bats`
- Direct code inspection: `scripts/tmux/netspeed`, `scripts/tmux/gpu`
- Direct code inspection: `Makefile`
- Live test run: `bats scripts/tmux/tests/` — confirmed 10/11 pass, test 7 fails with exact error
- System inspection: `which nvidia-smi` → `/usr/bin/nvidia-smi` (explains test 7 failure)
- `bats --version` → 1.13.0 at `~/.local/bin/bats`

### Secondary (MEDIUM confidence)
- GNU Make manual: `export VAR :=` propagates to child processes; recipe-level assignments do not

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — bats already installed and working; no new dependencies
- Architecture: HIGH — all patterns are direct copies of existing Phase 1 code in the repo
- Pitfalls: HIGH — GPU absent test failure is directly observed and root-caused; other pitfalls derived from code inspection

**Research date:** 2026-03-09
**Valid until:** Stable (no external dependencies; bats API changes rarely)
