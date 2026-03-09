# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-08)

**Core value:** Every tmux status bar widget prints a valid value on any supported Linux distro, verified by automated tests that run without real hardware.
**Current focus:** Phase 1 — Script Fixes

## Current Position

Phase: 1 of 2 (Script Fixes)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-03-08 — Roadmap created

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: -
- Trend: -

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Bash only for scripts; bats for testing framework
- Fix all 5 scripts (not just cpu+gpu) to prevent future cross-distro surprises
- Mock system commands in tests so suite runs CI-safe without hardware

### Pending Todos

None yet.

### Blockers/Concerns

- CPU script: mpstat locale issue (comma vs dot decimal) is the primary known failure mode on Fedora — fix must use locale-agnostic parsing (e.g., `LC_ALL=C` or awk substitution)
- GPU script: silent failure mode when nvidia-smi is missing must be handled explicitly

## Session Continuity

Last session: 2026-03-08
Stopped at: Roadmap created, no plans written yet
Resume file: None
