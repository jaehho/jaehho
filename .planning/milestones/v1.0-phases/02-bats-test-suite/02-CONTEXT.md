# Phase 2: Bats Test Suite - Context

**Gathered:** 2026-03-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the existing bats test suite robust, CI-safe, and reliably passing. All 5 test files were created in Phase 1 as a TDD baseline — Phase 2 fixes the three known gaps: broken GPU absent test, blocking sleep in netspeed, and fragile make test invocation.

</domain>

<decisions>
## Implementation Decisions

### GPU absent test
- For the **absent** test: set `PATH="$MOCK_BIN"` only (no system dirs). `command -v nvidia-smi` fails → script outputs "N/A" and exits before reaching awk. Works because the absent codepath never calls any system binary.
- For the **present** test: set `PATH="$MOCK_BIN:/usr/bin:/bin"` with a working mock nvidia-smi in MOCK_BIN — real nvidia-smi is shadowed.
- For the **driver-failure** test: same as present but mock exits 1 with error on stderr — existing test unchanged.
- All three tests use consistent restricted PATH (MOCK_BIN always first, system dirs only where needed).

### Blocking sleep in netspeed
- Add `SLEEP_INTERVAL="${SLEEP_INTERVAL:-1}"` to the netspeed script; replace `sleep 1` with `sleep "$SLEEP_INTERVAL"`
- Same pattern as `CPU_SAMPLE_INTERVAL` already used in the cpu script (Phase 1 decision)
- Add `PROC_NET_DEV_1` / `PROC_NET_DEV_2` env var support to netspeed for two-file fixture injection (same pattern as PROC_STAT_1/2 in cpu)
- Tests set `SLEEP_INTERVAL=0 PROC_NET_DEV_1=fixture1 PROC_NET_DEV_2=fixture2` to run instantly and assert real delta values
- Add a test with known byte deltas asserting exact KB/s output (e.g., 1024 bytes/s = 1 KB/s)

### make test portability
- Add `PATH := $(HOME)/.local/bin:$(PATH)` at top of Makefile so bats is found without manual PATH export
- Add explicit bats check before running: if bats not found, print clear install instructions and exit 1
- Install hint: `~/.local/bin/bats not found — install with: git clone ... && ./install.sh ~/.local`

### Claude's Discretion
- Exact wording of the bats-not-found error message
- Whether to keep the existing `cpu.bats` tests as-is (they work fine) or consolidate style

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CPU_SAMPLE_INTERVAL` pattern in `scripts/tmux/cpu` — env var controls sleep duration, tests set to 0
- `PROC_NET_DEV` env var in `scripts/tmux/netspeed` — injectable proc file path (extend to PROC_NET_DEV_1/2)
- `MOCK_BIN` pattern in all existing bats tests — mktemp dir prepended to PATH, cleaned in teardown

### Established Patterns
- PATH-override MOCK_BIN: all tests use `export PATH="$MOCK_BIN:$PATH"` for command isolation
- Fixture injection via env vars: PROC_NET_DEV in netspeed; PROC_STAT_1/2 in cpu
- `run "$SCRIPT"` pattern with `[ "$status" -eq 0 ]` + output assertion

### Integration Points
- `Makefile` `## Tmux scripts` section — add PATH and bats check to the `test` target
- `scripts/tmux/netspeed` — add SLEEP_INTERVAL and PROC_NET_DEV_1/2 support

</code_context>

<specifics>
## Specific Ideas

- The SLEEP_INTERVAL=0 + two-fixture approach should let us assert `↓1 ↑0 KB/s` or similar — a real value, not just format

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-bats-test-suite*
*Context gathered: 2026-03-09*
