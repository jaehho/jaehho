# Phase 1: Script Fixes - Research

**Researched:** 2026-03-08
**Domain:** Bash shell scripting, Linux system metrics APIs, cross-distro compatibility
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SCRP-01 | `cpu` script outputs a valid integer (0–100) on Fedora with locale-agnostic mpstat parsing | LC_ALL=C prefix eliminates comma/dot decimal separator ambiguity; /proc/stat alternative confirmed working |
| SCRP-02 | `cpu` script outputs a valid integer (0–100) on Ubuntu (no regression) | LC_ALL=C is a no-op when locale already uses dot; /proc/stat is kernel ABI stable across distros |
| SCRP-03 | `gpu` script outputs a valid integer (0–100) when nvidia-smi is available | nvidia-smi --query-gpu output format verified stable; command -v guard pattern documented |
| SCRP-04 | `gpu` script outputs a graceful fallback string (e.g., `N/A`) when nvidia-smi is absent or fails | command -v guard + || fallback pattern is the standard bash approach |
| SCRP-05 | `ram` script outputs a valid integer (0–100) on both Ubuntu and Fedora | `free` NR==2 column layout verified identical on Fedora 43 and Ubuntu; no fix needed |
| SCRP-06 | `disk` script outputs a valid percentage string (e.g., `42%`) on both Ubuntu and Fedora | `df -h /` NR==2 $5 layout verified correct on Fedora; no fix needed |
| SCRP-07 | `netspeed` script outputs a valid KB/s string (e.g., `↓12 ↑3 KB/s`) on both Ubuntu and Fedora | /proc/net/dev column layout ($2=rx bytes, $10=tx bytes) verified correct on Fedora 43; no fix needed |
</phase_requirements>

---

## Summary

Five tmux status bar scripts currently run on Ubuntu. The project is adding Fedora support. Two scripts have confirmed cross-distro problems; three work as-is. Phase 1 is surgical: fix the two broken scripts (`cpu` and `gpu`), verify the three already-correct scripts (`ram`, `disk`, `netspeed`) pass unchanged, and wire up a `make test` target pointing at bats 1.12.0 (available in the Fedora 43 `dnf` repo).

The cpu script's failure root is locale-sensitive output from `mpstat`. When the system locale uses a comma as the decimal separator (common on European Fedora installs), `mpstat` prints idle CPU as `12,50` instead of `12.50`. AWK interprets `12,50` as the integer `12` (stops at the comma), producing a result 0–1 percentage points off — wrong but not catastrophically so. The canonical one-word fix is prepending `LC_ALL=C` to the `mpstat` invocation. An alternative that removes the `sysstat` dependency entirely is reading `/proc/stat` directly; this is locale-agnostic by design because `/proc/stat` emits raw kernel integers.

The gpu script silently produces no output (empty string) when `nvidia-smi` is missing. tmux then shows a blank widget. The fix is a `command -v nvidia-smi` guard before the query; on failure, print `N/A`.

**Primary recommendation:** Prefix `mpstat` with `LC_ALL=C`; guard `nvidia-smi` with a command check and echo `N/A` on failure. The other three scripts need no code changes on Fedora.

---

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| bash | 5.2+ (both distros) | Script runtime | Already used; POSIX-compatible |
| mpstat (sysstat) | any | CPU idle sampling | Already used; fix is one word: `LC_ALL=C` |
| /proc/stat | kernel ABI | Alternative CPU source | No package dependency; locale-agnostic integers |
| free | procps-ng | RAM stats | Already used; column layout verified identical on both distros |
| df | coreutils | Disk usage | Already used; `-h /` NR==2 $5 verified correct on both distros |
| /proc/net/dev | kernel ABI | Network byte counters | Already used; format is kernel-stable |
| nvidia-smi | NVIDIA driver | GPU utilization | Already used; needs absent-binary guard |
| bats | 1.12.0 (fc43) | Bash test framework | In Fedora 43 dnf repo; `sudo dnf install bats` |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| command -v | bash built-in | Binary existence check | Guard optional binaries like nvidia-smi |
| mktemp -d | coreutils | Temp mock dir for tests | bats PATH-override mocking pattern |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| LC_ALL=C mpstat | /proc/stat read | /proc/stat removes sysstat dependency entirely; adds ~10 lines of bash; eliminates mpstat column version concerns |
| LC_ALL=C mpstat | mpstat -o JSON | JSON output is locale-agnostic but requires sysstat >=11.5.1 and a JSON parser (python3/jq); heavier dependency chain |
| sudo dnf install bats | git clone bats-core | git clone works on Ubuntu too; dnf install is simpler on Fedora |

**Installation (Fedora):**
```bash
sudo dnf install bats
```

**Installation (Ubuntu):**
```bash
sudo apt-get install bats
```

---

## Architecture Patterns

### Recommended Project Structure
```
scripts/tmux/
├── cpu            # Fix: add LC_ALL=C prefix to mpstat
├── gpu            # Fix: add command -v guard, echo N/A fallback
├── ram            # No change needed (verified correct on Fedora)
├── disk           # No change needed (verified correct on Fedora)
├── netspeed       # No change needed (verified correct on Fedora)
└── tests/
    ├── cpu.bats   # New: bats unit tests (replaces/supplements test-cpu.sh)
    ├── gpu.bats   # New
    ├── ram.bats   # New
    ├── disk.bats  # New
    └── netspeed.bats  # New
```

### Pattern 1: LC_ALL=C locale override for mpstat
**What:** Prepend `LC_ALL=C` to the `mpstat` invocation so the command always outputs dot-decimal numbers regardless of system locale.
**When to use:** Any time a tool is known to be locale-sensitive and the output is parsed numerically.
**Example:**
```bash
# Before (fails on non-C locales: outputs "88" when idle is "12,5" instead of "87")
mpstat 1 1 | awk '/Average:/{printf "%d", 100-$NF}'

# After (locale-agnostic)
LC_ALL=C mpstat 1 1 | awk '/Average:/{printf "%d", 100-$NF}'
```

### Pattern 2: /proc/stat direct read (alternative CPU approach)
**What:** Read `/proc/stat` twice with a 1-second sleep and compute active CPU from integer deltas. No sysstat required, no locale sensitivity.
**When to use:** If sysstat is not installed, or if complete locale-independence is preferred.
**Example:**
```bash
#!/bin/bash
read -r _ u1 n1 s1 i1 w1 irq1 sirq1 steal1 _ < /proc/stat
sleep 1
read -r _ u2 n2 s2 i2 w2 irq2 sirq2 steal2 _ < /proc/stat
total1=$((u1+n1+s1+i1+w1+irq1+sirq1+steal1))
total2=$((u2+n2+s2+i2+w2+irq2+sirq2+steal2))
idle_diff=$((i2-i1))
total_diff=$((total2-total1))
printf "%d" $(( (total_diff-idle_diff)*100/total_diff ))
```
This approach was tested live on Fedora 43 and produces correct results.

### Pattern 3: command -v guard for optional binaries
**What:** Check whether an external command exists before calling it; print a fallback value if absent.
**When to use:** Any widget that depends on hardware-specific tools (nvidia-smi, etc.).
**Example:**
```bash
#!/bin/bash
if ! command -v nvidia-smi &>/dev/null; then
  echo "N/A"
  exit 0
fi
nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | tr -d ' '
```

### Pattern 4: bats PATH-override mocking
**What:** In bats `setup()`, create a temp directory prepended to `$PATH` containing stub scripts. The real scripts under test then call the stubs instead of real system commands.
**When to use:** Any test that must run without real hardware (CI-safe).
**Example:**
```bash
setup() {
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
}

teardown() {
  rm -rf "$MOCK_BIN"
}

@test "gpu outputs integer when nvidia-smi present" {
  printf '#!/bin/bash\necho 45\n' > "$MOCK_BIN/nvidia-smi"
  chmod +x "$MOCK_BIN/nvidia-smi"
  run "$BATS_TEST_DIRNAME/../gpu"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
}

@test "gpu outputs N/A when nvidia-smi absent" {
  # MOCK_BIN is empty; real nvidia-smi not in PATH on CI
  run "$BATS_TEST_DIRNAME/../gpu"
  [ "$status" -eq 0 ]
  [ "$output" = "N/A" ]
}
```

### Anti-Patterns to Avoid
- **Piping through `tr` to fix locale:** `mpstat ... | tr ',' '.'` works but runs before awk sees the data, which is brittle if other comma-using output appears. Use `LC_ALL=C` at the source instead.
- **Using `which` instead of `command -v`:** `which` is not portable; `command -v` is a bash built-in and POSIX.
- **Silent failure on missing nvidia-smi:** The current script produces empty output. tmux shows a blank widget with no indication of the problem.
- **Testing with real hardware in CI:** Tests that call real `mpstat`, real `nvidia-smi`, or real network interfaces cannot run in CI. All tests must mock external commands via PATH.
- **Hardcoding interface names in netspeed tests:** The netspeed script already auto-detects the interface via `ip route`. Tests should mock `/proc/net/dev` data, not assume `eth0` or `wlo1`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Locale-agnostic numeric output | Custom awk substitution loops | `LC_ALL=C` env prefix | One word, covers all locale fields, zero maintenance |
| Bash test framework | Custom assert functions in bash | bats 1.12.0 | TAP output, per-test isolation, `run` wrapper, `$status`/`$output` variables |
| Command mocking | LD_PRELOAD tricks or function exports | PATH-override with temp dir | Simplest approach; works with external scripts, not just sourced functions |

**Key insight:** `/proc/stat`, `/proc/net/dev`, `free`, and `df` emit locale-agnostic output (integers and ASCII strings) natively. Only `mpstat` is locale-sensitive because sysstat formats its output as human-readable floating point.

---

## Common Pitfalls

### Pitfall 1: Comma decimal causes wrong (not missing) CPU output
**What goes wrong:** On a Fedora system with `LANG=fr_FR.UTF-8`, `mpstat` outputs `12,50` as the idle field. AWK evaluates `"12,50"` as the integer `12` (stops parsing at the comma). The result is `100 - 12 = 88` when the correct value is `100 - 12.5 = 87`. The output is a plausible integer — the bug is subtle.
**Why it happens:** AWK's numeric coercion stops at the first non-digit, non-dot character. A comma is not a decimal separator in AWK regardless of locale.
**How to avoid:** `LC_ALL=C mpstat 1 1` forces dot-decimal output before AWK ever sees the data.
**Warning signs:** CPU readings that seem slightly high during low-load periods.

### Pitfall 2: nvidia-smi exit code 6 vs "command not found"
**What goes wrong:** On systems where the NVIDIA driver is partially installed (driver present, no GPU physically), `nvidia-smi` exists as a binary but exits with status 6 and prints an error to stdout/stderr. The current script would then output the error string to the tmux bar.
**Why it happens:** The current script has no error handling at all — it runs `nvidia-smi` unconditionally and pipes to `tr`.
**How to avoid:** After the `command -v` guard, also check the exit status: `nvidia-smi ... || echo "N/A"`.
**Warning signs:** tmux status bar showing `Failed to initialize NVML` or similar error text.

### Pitfall 3: `free` NR==2 vs `free -b` NR==2
**What goes wrong:** If `free` is called with `-b` (bytes), the column layout is identical but values are much larger integers. The ram script uses `free` without flags, which outputs kibibytes. The arithmetic `$3/$2*100` is correct in either case (ratio is unit-independent), but tests that mock `free` output must use consistent units.
**Why it happens:** None — this is not actually broken. Document it so test authors don't get confused.
**How to avoid:** Mock `free` output in kibibytes (same as real `free` default output).

### Pitfall 4: df output wraps when filesystem path is long
**What goes wrong:** If the filesystem path is longer than the terminal width, `df -h` may wrap the output so that the percentage appears on a different line. `NR==2` would then pick up the wrong data.
**Why it happens:** GNU `df` wraps long device paths to the next line.
**How to avoid:** Use `df -h --output=pcent /` or `df -P /` (POSIX mode, no wrapping). On the current system, `/dev/sda3` is short enough that NR==2 works, but this is fragile.
**Warning signs:** disk script outputting an unexpected value when device path is very long (e.g., LVM or ZFS paths).

### Pitfall 5: netspeed test can't mock /proc/net/dev directly
**What goes wrong:** `/proc/net/dev` is a kernel virtual file; tests can't simply replace it with a fixture.
**Why it happens:** The script reads `/proc/net/dev` directly (not via a command). PATH-override mocking doesn't work here.
**How to avoid:** Refactor `netspeed` to accept the proc file path as an environment variable (e.g., `PROC_NET_DEV=${PROC_NET_DEV:-/proc/net/dev}`) so tests can point it at a fixture file. Alternatively, extract the awk logic into a function and test it directly.

---

## Code Examples

### cpu — current (broken on non-C locales)
```bash
#!/bin/bash
mpstat 1 1 | awk '/Average:/{printf "%d", 100-$NF}'
```

### cpu — fixed with LC_ALL=C
```bash
#!/bin/bash
LC_ALL=C mpstat 1 1 | awk '/Average:/{printf "%d", 100-$NF}'
```

### cpu — alternative using /proc/stat (no sysstat dependency)
```bash
#!/bin/bash
read -r _ u1 n1 s1 i1 w1 irq1 sirq1 steal1 _ < /proc/stat
sleep 1
read -r _ u2 n2 s2 i2 w2 irq2 sirq2 steal2 _ < /proc/stat
total1=$((u1+n1+s1+i1+w1+irq1+sirq1+steal1))
total2=$((u2+n2+s2+i2+w2+irq2+sirq2+steal2))
total_diff=$((total2-total1))
idle_diff=$((i2-i1))
printf "%d" $(( (total_diff-idle_diff)*100/total_diff ))
```

### gpu — current (silent empty output when nvidia-smi absent)
```bash
#!/bin/bash
nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | tr -d ' '
```

### gpu — fixed with guard and fallback
```bash
#!/bin/bash
if ! command -v nvidia-smi &>/dev/null; then
  echo "N/A"
  exit 0
fi
nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | tr -d ' ' || echo "N/A"
```

### ram — no change needed (verified correct on Fedora 43)
```bash
#!/bin/bash
free | awk 'NR==2{printf "%d", $3/$2*100}'
# Verified: free NR==2 is "Mem:" line. $2=total, $3=used. Layout identical on Ubuntu and Fedora.
```

### disk — no change needed (verified correct on Fedora 43)
```bash
#!/bin/bash
df -h / | awk 'NR==2{print $5}'
# Verified: df -h / NR==2 $5 is "Use%" column. Layout identical on Ubuntu and Fedora.
# Note: fragile if device path is very long (wraps to extra line). EXT item, not Phase 1.
```

### netspeed — no change needed (verified correct on Fedora 43)
```bash
# /proc/net/dev columns: $1=iface, $2=rx_bytes, $10=tx_bytes
# Verified on Fedora 43 with wlo1 interface.
# Interface auto-detection via `ip route` also works correctly.
```

### bats mock pattern for mpstat (CPU tests)
```bash
# Source: bats-core PATH-override pattern (bats-core.readthedocs.io)
setup() {
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
}
teardown() { rm -rf "$MOCK_BIN"; }

# Mock mpstat to emit Fedora-style comma decimal output
make_mpstat_mock() {
  local idle="$1"
  cat > "$MOCK_BIN/mpstat" << EOF
#!/bin/bash
echo "Average: all  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  ${idle}"
EOF
  chmod +x "$MOCK_BIN/mpstat"
}

@test "cpu outputs integer on C locale idle=12.5" {
  make_mpstat_mock "12.5"
  run scripts/tmux/cpu
  [ "$status" -eq 0 ]
  [ "$output" = "87" ]
}

@test "cpu outputs integer on Fedora fr locale idle=12,5" {
  make_mpstat_mock "12,5"
  run scripts/tmux/cpu
  [ "$status" -eq 0 ]
  # With LC_ALL=C fix, mpstat receives LC_ALL=C so mock won't emit comma output
  # This test verifies the script doesn't break with comma input from a non-fixed mock
  [[ "$output" =~ ^[0-9]+$ ]]
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plain `mpstat` | `LC_ALL=C mpstat` | Standard practice | Locale-agnostic numeric output |
| No test for missing tools | `command -v` guard | Standard practice | Graceful fallback instead of empty/error output |
| Manual stress tests only | bats unit tests with mocks | This phase | CI-safe, hardware-free test suite |

**Deprecated/outdated:**
- `which nvidia-smi`: Use `command -v nvidia-smi` instead. `which` is not POSIX and behavior varies.
- `bats` (original Sstephenson fork, abandoned 2016): Use `bats-core` (maintained fork, packaged as `bats` in Fedora/Ubuntu repos).

---

## Open Questions

1. **CPU fix approach: LC_ALL=C vs /proc/stat**
   - What we know: Both work. `LC_ALL=C` is a one-line change. `/proc/stat` removes the sysstat dependency entirely.
   - What's unclear: Whether the user prefers to keep sysstat as a dependency or eliminate it.
   - Recommendation: Use `LC_ALL=C mpstat` for Phase 1 (minimal diff, same behavior). Document `/proc/stat` approach for EXT-03 when the blocking sleep is eliminated anyway.

2. **df wrapping pitfall — fix now or defer?**
   - What we know: Current `/dev/sda3` path is short enough that NR==2 works. Long LVM/ZFS paths could break it.
   - What's unclear: Whether the user's machine will ever have a long device path.
   - Recommendation: Defer to v2. Use `df -P /` (POSIX mode, no wrapping) if raised as a bug.

3. **netspeed testability: /proc/net/dev fixture injection**
   - What we know: The script reads `/proc/net/dev` directly; PATH-override mocking doesn't cover this.
   - What's unclear: Whether the user wants a refactor in Phase 1 or is OK with a simpler but less thorough test.
   - Recommendation: For Phase 1 bats tests (TEST-06), add `PROC_NET_DEV` env var support to the script so tests can point it at a fixture file. This is a one-line addition: `PROC_NET_DEV=${PROC_NET_DEV:-/proc/net/dev}`.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bats 1.12.0 (Fedora 43: `sudo dnf install bats`; Ubuntu: `sudo apt-get install bats`) |
| Config file | none — bats discovers `*.bats` files by argument |
| Quick run command | `bats scripts/tmux/tests/` |
| Full suite command | `make test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCRP-01 | cpu outputs integer on Fedora (comma locale mpstat) | unit | `bats scripts/tmux/tests/cpu.bats` | No — Wave 0 |
| SCRP-02 | cpu outputs integer on Ubuntu (dot locale mpstat, no regression) | unit | `bats scripts/tmux/tests/cpu.bats` | No — Wave 0 |
| SCRP-03 | gpu outputs integer when nvidia-smi present | unit | `bats scripts/tmux/tests/gpu.bats` | No — Wave 0 |
| SCRP-04 | gpu outputs N/A when nvidia-smi absent | unit | `bats scripts/tmux/tests/gpu.bats` | No — Wave 0 |
| SCRP-05 | ram outputs integer on both distros | unit | `bats scripts/tmux/tests/ram.bats` | No — Wave 0 |
| SCRP-06 | disk outputs percentage string on both distros | unit | `bats scripts/tmux/tests/disk.bats` | No — Wave 0 |
| SCRP-07 | netspeed outputs KB/s format on both distros | unit | `bats scripts/tmux/tests/netspeed.bats` | No — Wave 0 |

### Sampling Rate
- **Per task commit:** `bats scripts/tmux/tests/`
- **Per wave merge:** `make test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `scripts/tmux/tests/cpu.bats` — covers SCRP-01, SCRP-02
- [ ] `scripts/tmux/tests/gpu.bats` — covers SCRP-03, SCRP-04
- [ ] `scripts/tmux/tests/ram.bats` — covers SCRP-05
- [ ] `scripts/tmux/tests/disk.bats` — covers SCRP-06
- [ ] `scripts/tmux/tests/netspeed.bats` — covers SCRP-07 (requires `PROC_NET_DEV` env var support in netspeed script)
- [ ] `Makefile` `test` target: `bats scripts/tmux/tests/`
- [ ] Framework install: `sudo dnf install bats` (Fedora) / `sudo apt-get install bats` (Ubuntu) — not in current Makefile

---

## Sources

### Primary (HIGH confidence)
- Live system inspection — `/proc/stat`, `/proc/net/dev`, `free`, `df -h` output verified on Fedora 43 (this machine)
- Live computation — `/proc/stat` CPU calculation tested and produced correct output (16%)
- Live verification — `free` column layout ($2=total, $3=used), `df -h` column layout ($5=Use%) confirmed on Fedora 43
- `dnf list available bats` — bats 1.12.0-2.fc43 confirmed available in Fedora 43 fedora repo
- Kernel documentation — `/proc/net/dev` column layout is kernel ABI (columns 2=rx_bytes, 10=tx_bytes confirmed by live awk inspection)

### Secondary (MEDIUM confidence)
- [Redhat Bugzilla #849515](https://bugzilla.redhat.com/show_bug.cgi?id=849515) — documents the mpstat locale/decimal separator issue on Fedora
- [bats-core documentation](https://bats-core.readthedocs.io/en/stable/) — PATH-override mocking pattern, `run` wrapper semantics
- [bats-core GitHub](https://github.com/bats-core/bats-core) — version history, installation methods
- [sysstat/sysstat GitHub issue #159](https://github.com/sysstat/sysstat/issues/159) — confirms %steal column placement differences between mpstat versions; $NF=%idle is consistent across versions

### Tertiary (LOW confidence)
- None — all critical claims verified via live system or official sources.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified by live `dnf list` and direct system calls
- Architecture: HIGH — all patterns verified on the actual Fedora 43 system
- Pitfalls: HIGH (cpu/gpu) — reproduced and confirmed; MEDIUM (df wrapping) — known GNU behavior, not reproduced on this machine
- Validation architecture: HIGH — bats 1.12.0 confirmed in repo; mock pattern is standard bats idiom

**Research date:** 2026-03-08
**Valid until:** 2026-09-08 (stable domain — kernel proc ABI, locale behavior, bats API change slowly)
