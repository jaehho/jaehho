# Coding Conventions

**Analysis Date:** 2026-03-08

## Overview

This is a personal dotfiles/system configuration repository. The primary languages are Bash and Make. A small Expect script (`scripts/ice/ssh.exp`) handles automated SSH. Python is used inline within Bash scripts for memory allocation and GPU stress tasks. There is no TypeScript/JavaScript source code.

## Naming Patterns

**Files:**
- Bash scripts use lowercase, no extension: `cpu`, `ram`, `disk`, `gpu`, `netspeed`, `yank` (in `scripts/tmux/`)
- Test scripts use `test-<target>.sh` naming: `test-cpu.sh`, `test-disk.sh`, `test-gpu.sh`
- Shell scripts outside the tmux directory use `.sh` extension: `mount.sh`, `sync.sh`, `fix-cv2-fonts.sh`
- Config files use dotfile convention: `.bash_profile`, `.gitconfig`, `.tmux.conf`
- Expect scripts use `.exp` extension: `ssh.exp`

**Makefile Targets:**
- Grouped by service prefix: `ice-*`, `zotero-*`, `setup-*`, `install-*`
- Hyphen-separated, lowercase: `ice-link`, `ice-reload`, `ice-enable`, `setup-gitconfig`, `setup-bashrc`
- Every public target has a `## comment` for the help system

**Variables:**
- Makefile variables: SCREAMING_SNAKE_CASE with descriptive suffixes (`ICE_SERVICE_NAME`, `ICE_SERVICE_SRC`, `ICE_SERVICE_DST`, `REPO_ROOT`)
- Bash script variables: SCREAMING_SNAKE_CASE for globals and positional parameters (`DURATION`, `SCRIPT_DIR`, `NCPU`, `IFACE`, `PASSWORD`)
- Bash local variables: lowercase snake_case (`local_uid`, `local_gid`, `timestamp`, `cmd_clean`, `log_file`)
- Environment variable names: SCREAMING_SNAKE_CASE (`ICE_PASSWORD`, `MOUNTPOINT`, `REMOTE_PATH`, `REMOTE_USER`, `LOCAL_USER`)

**Bash Functions:**
- Internal/private helpers prefixed with underscore: `_ice_load_env`
- Public shell functions: short lowercase names (`nh`, `nh_list`, `ssh`)

## Code Style

**Formatting (Bash):**
- Shebang line always present: `#!/bin/bash` or `#!/usr/bin/env bash`
- Single blank line between logical sections
- Inline comments use `#` on same line or dedicated line above the statement
- Block comments for section headers use `# ── description ────` separator style (in `.bash_profile`)

**Formatting (Makefile):**
- `.SILENT:` suppresses default echo; `echo` used explicitly for help output
- `.IGNORE:` set globally
- `.DEFAULT_GOAL := help`
- Section headers use `## Section Name` comment lines (picked up by the help grep)
- Variable blocks use aligned assignment with space-padded `=` for readability:
  ```makefile
  ICE_SERVICE_NAME = ice.service
  ICE_SERVICE_SRC  = $(REPO_ROOT)/systemd/$(ICE_SERVICE_NAME)
  ICE_SERVICE_DST  = /etc/systemd/system/$(ICE_SERVICE_NAME)
  ```

**Shell Strictness:**
- Safety flags `set -euo pipefail` used in scripts that run with elevated context or make destructive changes (`scripts/ice/mount.sh`)
- Simpler/shorter scripts omit strict mode (`scripts/tmux/*`, `scripts/zotero/sync.sh`)
- `SCRIPT_DIR` is always computed with `$(cd "$(dirname "$0")/.." && pwd)` in test scripts for portable sibling-script resolution

## Import Organization

- No module imports; Bash scripts source environment via explicit patterns:
  ```bash
  set -a
  source "$ENV_FILE"
  set +a
  ```
- `.bash_profile` is sourced from `~/.bashrc` (not directly executed)
- `direnv` manages per-directory `.envrc` activation

## Error Handling

**Patterns:**
- Validate required environment variables before use, exit with a message to stderr:
  ```bash
  if [ -z "${ICE_PASSWORD:-}" ]; then
      echo "ERROR: ICE_PASSWORD is not set (check your .env or service EnvironmentFile)" >&2
      exit 1
  fi
  ```
- Validate system tool availability before using:
  ```bash
  if ! command -v nvidia-smi &>/dev/null; then
      echo "ERROR: nvidia-smi not found."
      exit 1
  fi
  ```
- Errors always print to stderr (`>&2`); informational output goes to stdout
- `set -euo pipefail` in critical scripts to abort on any error
- Use `2>/dev/null` to silently suppress non-critical command failures

**Cleanup Pattern (trap):**
All test scripts and long-running scripts register a `cleanup` function via `trap`:
```bash
cleanup() {
    echo -e "\nStopping stressors..."
    kill "${PIDS[@]}" 2>/dev/null
    wait "${PIDS[@]}" 2>/dev/null
    echo "Done."
    exit
}
trap cleanup INT TERM EXIT
```

**Fallback/Default Values:**
- Use `${VAR:-default}` for optional variables with sensible defaults
- Use `: "${VAR:=default}"` for declaring defaults for global script variables:
  ```bash
  : "${MOUNTPOINT:=/mnt/ice}"
  : "${REMOTE_USER:=jaeho.cho}"
  ```
- Positional parameters use `${1:-default}`:
  ```bash
  DURATION=${1:-30}
  ```

## Logging

**Pattern:**
- No logging framework; use `echo` for informational output (stdout)
- Error messages: `echo "ERROR: ..." >&2`
- Progress display: `printf "\r..."` with carriage return for in-place updates
- `echo "=== Section Header ==="` format for test script banners

## Comments

**When to Comment:**
- Comment every Makefile target with `## Description` for help system inclusion
- Comment non-obvious one-liners explaining the "why": `# Fallback: first non-loopback interface listed in /proc/net/dev`
- File-level comment at the top of each test script explaining purpose and usage
- Comment `.env.sample` entries explaining what each variable controls and which scripts use it

**Usage header format:**
```bash
# Usage: ./test-cpu.sh [duration_seconds]  (default: 30)
```

## Portability

- Scripts use `/bin/bash` explicitly; avoid `/bin/sh` except the git hook (`post-commit`)
- Clipboard access is abstracted: `scripts/tmux/yank` detects macOS (`pbcopy`), Wayland (`wl-copy`), X11 (`xclip`, `xsel`) in order
- Network interface detection falls back from `ip route` to `/proc/net/dev` for WSL compatibility
- Bash profile guards tmux auto-attach and direnv hook with environment checks (`[[ -z "$TMUX" ]]`, `[[ -z "$VSCODE_INJECTION" ]]`)

## Systemd Unit Conventions

- `EnvironmentFile=` points directly to `$REPO_ROOT/.env` for secret injection
- `ExecStart=` uses absolute paths to repo scripts
- Service type `oneshot` + `RemainAfterExit=yes` for mount operations; `simple` + `Restart=always` for daemons

---

*Convention analysis: 2026-03-08*
