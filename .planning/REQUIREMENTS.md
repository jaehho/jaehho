# Requirements: Tmux Status Bar Cross-Distro Fix

**Defined:** 2026-03-08
**Core Value:** Every tmux status bar widget prints a valid value on any supported Linux distro, verified by automated tests that run without real hardware.

## v1 Requirements

### Script Fixes

- [x] **SCRP-01**: `cpu` script outputs a valid integer (0–100) on Fedora with locale-agnostic mpstat parsing
- [x] **SCRP-02**: `cpu` script outputs a valid integer (0–100) on Ubuntu (no regression)
- [x] **SCRP-03**: `gpu` script outputs a valid integer (0–100) when nvidia-smi is available
- [x] **SCRP-04**: `gpu` script outputs a graceful fallback string (e.g., `N/A`) when nvidia-smi is absent or fails
- [x] **SCRP-05**: `ram` script outputs a valid integer (0–100) on both Ubuntu and Fedora
- [x] **SCRP-06**: `disk` script outputs a valid percentage string (e.g., `42%`) on both Ubuntu and Fedora
- [x] **SCRP-07**: `netspeed` script outputs a valid KB/s string (e.g., `↓12 ↑3 KB/s`) on both Ubuntu and Fedora

### Unit Tests

- [x] **TEST-01**: Bats test suite installed and runnable via `make test`
- [x] **TEST-02**: `cpu` tests mock `mpstat` output for both Ubuntu and Fedora locale formats and assert integer output
- [x] **TEST-03**: `gpu` tests mock `nvidia-smi` present/absent and assert correct output in both cases
- [x] **TEST-04**: `ram` tests mock `free` output and assert integer output
- [x] **TEST-05**: `disk` tests mock `df` output and assert percentage string output
- [x] **TEST-06**: `netspeed` tests mock `/proc/net/dev` and assert KB/s format output
- [x] **TEST-07**: All tests pass without real hardware (nvidia-smi, GPU, physical network interface)
- [x] **TEST-08**: All tests complete without blocking sleeps (CI-safe)

## v2 Requirements

### Extended Coverage

- **EXT-01**: Tests run in CI (GitHub Actions or equivalent)
- **EXT-02**: ShellCheck integration in Makefile for linting all tmux scripts
- **EXT-03**: Performance fix: eliminate 1-second blocking sleep in `cpu` and `netspeed` via tmpfile caching

## Out of Scope

| Feature | Reason |
|---------|--------|
| Fixing hard-coded paths in .tmux.conf | Separate tech debt item, not related to broken output |
| WSL detection / WSL-specific fixes | Current scripts already handle WSL via ip route; no new WSL issues reported |
| Other script fixes (ssh.exp, mount.sh, zotero) | Out of scope for this milestone |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCRP-01 | Phase 1 | Complete |
| SCRP-02 | Phase 1 | Complete |
| SCRP-03 | Phase 1 | Complete |
| SCRP-04 | Phase 1 | Complete |
| SCRP-05 | Phase 1 | Complete |
| SCRP-06 | Phase 1 | Complete |
| SCRP-07 | Phase 1 | Complete |
| TEST-01 | Phase 2 | Complete |
| TEST-02 | Phase 2 | Complete |
| TEST-03 | Phase 2 | Complete |
| TEST-04 | Phase 2 | Complete |
| TEST-05 | Phase 2 | Complete |
| TEST-06 | Phase 2 | Complete |
| TEST-07 | Phase 2 | Complete |
| TEST-08 | Phase 2 | Complete |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-08*
*Last updated: 2026-03-08 after roadmap creation*
