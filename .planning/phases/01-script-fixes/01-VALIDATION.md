---
phase: 1
slug: script-fixes
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bats 1.12.0 |
| **Config file** | none — bats discovers `*.bats` files by argument |
| **Quick run command** | `bats scripts/tmux/tests/` |
| **Full suite command** | `make test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bats scripts/tmux/tests/`
- **After every plan wave:** Run `make test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 0 | SCRP-01,02 | unit | `bats scripts/tmux/tests/cpu.bats` | ❌ W0 | ⬜ pending |
| 1-01-02 | 01 | 0 | SCRP-03,04 | unit | `bats scripts/tmux/tests/gpu.bats` | ❌ W0 | ⬜ pending |
| 1-01-03 | 01 | 0 | SCRP-05 | unit | `bats scripts/tmux/tests/ram.bats` | ❌ W0 | ⬜ pending |
| 1-01-04 | 01 | 0 | SCRP-06 | unit | `bats scripts/tmux/tests/disk.bats` | ❌ W0 | ⬜ pending |
| 1-01-05 | 01 | 0 | SCRP-07 | unit | `bats scripts/tmux/tests/netspeed.bats` | ❌ W0 | ⬜ pending |
| 1-01-06 | 01 | 1 | SCRP-01,02 | unit | `bats scripts/tmux/tests/cpu.bats` | ✅ | ⬜ pending |
| 1-01-07 | 01 | 1 | SCRP-03,04 | unit | `bats scripts/tmux/tests/gpu.bats` | ✅ | ⬜ pending |
| 1-01-08 | 01 | 1 | SCRP-05,06,07 | unit | `bats scripts/tmux/tests/` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/tmux/tests/cpu.bats` — stubs for SCRP-01, SCRP-02
- [ ] `scripts/tmux/tests/gpu.bats` — stubs for SCRP-03, SCRP-04
- [ ] `scripts/tmux/tests/ram.bats` — stubs for SCRP-05
- [ ] `scripts/tmux/tests/disk.bats` — stubs for SCRP-06
- [ ] `scripts/tmux/tests/netspeed.bats` — stubs for SCRP-07
- [ ] `Makefile` `test` target: `bats scripts/tmux/tests/`
- [ ] bats installed: `sudo dnf install bats` (Fedora) / `sudo apt-get install bats` (Ubuntu)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| tmux status bar shows numeric CPU % | SCRP-01,02 | Requires live tmux session | Open tmux, observe CPU widget shows a number followed by nothing (no %) |
| tmux status bar shows numeric GPU % or N/A | SCRP-03,04 | Requires live tmux session | Open tmux, observe GPU widget shows integer or N/A |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
