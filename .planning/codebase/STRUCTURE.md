# Codebase Structure

**Analysis Date:** 2026-03-08

## Directory Layout

```
jaehho/                        # Repo root (personal environment monorepo)
├── Makefile                   # All setup, service lifecycle, and dep install targets
├── pyproject.toml             # Python project metadata (uv-managed)
├── .env.sample                # Template for .env (committed); actual .env is gitignored
├── .envrc.sample              # Template for .envrc (direnv); actual .envrc is gitignored
├── .gitignore                 # Ignores .venv/, __pycache__/, .env, .envrc
├── README.md                  # Empty placeholder
├── config/                    # Dotfiles linked into $HOME
│   ├── .bash_profile          # Shell helpers, ssh wrapper, tmux auto-attach, aliases
│   ├── .gitconfig             # Git identity, aliases, credential helper, hooks path
│   └── .tmux.conf             # Tmux keybindings, status bar, copy-mode config
├── scripts/                   # Executable automation scripts
│   ├── fix-cv2-fonts.sh       # One-off: links DejaVu fonts into active venv's cv2 dir
│   ├── ice/                   # Cooper ICE HPC cluster access scripts
│   │   ├── ssh.exp            # Expect script: automated SSH password auth to ICE
│   │   └── mount.sh           # SSHFS mount: iterates ice00–ice11, mounts at /mnt/ice
│   ├── tmux/                  # Tmux status bar plugins (called every 5s by .tmux.conf)
│   │   ├── cpu                # Prints CPU utilization % (uses mpstat)
│   │   ├── ram                # Prints RAM utilization % (uses free)
│   │   ├── disk               # Prints root disk usage % (uses df)
│   │   ├── gpu                # Prints GPU utilization % (uses nvidia-smi)
│   │   ├── netspeed           # Prints net RX/TX in KB/s (reads /proc/net/dev)
│   │   ├── yank               # Clipboard pipe: stdin → pbcopy/wl-copy/xclip/xsel
│   │   └── tests/             # Stress/validation tests for status scripts
│   │       ├── test-cpu.sh
│   │       ├── test-ram.sh
│   │       ├── test-disk.sh
│   │       ├── test-gpu.sh
│   │       └── test-netspeed.sh
│   └── zotero/                # Zotero bibliography sync
│       └── sync.sh            # Polls and copies Neuroscience.bib from WSL Windows path
├── systemd/                   # Systemd unit files (linked to /etc/systemd/system/ via make)
│   ├── ice.service            # One-shot service: mounts ICE SSHFS at boot
│   └── zotero.service         # Simple daemon: runs zotero/sync.sh, restarts on exit
└── .git-hooks/                # Repo-local git hooks (referenced by config/.gitconfig)
    └── post-commit            # Copies short commit hash to clipboard via xclip
```

## Directory Purposes

**`config/`:**
- Purpose: Versioned dotfiles for shell, git, and tmux
- Contains: Three dotfiles only; no subdirectories
- Key files: `config/.bash_profile` (primary shell entry point), `config/.gitconfig`, `config/.tmux.conf`
- Installation: Hard-linked or sourced into `$HOME` by `make setup-*` targets

**`scripts/ice/`:**
- Purpose: All automation for connecting to and mounting the Cooper ICE HPC cluster
- Contains: An Expect script for password-based SSH, a Bash script for SSHFS mounting
- Key files: `scripts/ice/ssh.exp`, `scripts/ice/mount.sh`
- Dependencies: `expect`, `sshfs`, `ICE_PASSWORD` from `.env`

**`scripts/tmux/`:**
- Purpose: Single-metric executables invoked by `.tmux.conf` for the status bar
- Contains: One script per metric; a `yank` clipboard helper; a `tests/` subdir
- Key files: `scripts/tmux/cpu`, `scripts/tmux/gpu`, `scripts/tmux/netspeed`, `scripts/tmux/yank`
- Convention: No arguments; print a single short string to stdout; exit 0

**`scripts/tmux/tests/`:**
- Purpose: Manual stress/validation tests to verify each status script under load
- Contains: One test script per status script
- Key files: `scripts/tmux/tests/test-cpu.sh` (representative example)
- Generated: No — committed

**`scripts/zotero/`:**
- Purpose: Cross-environment bib file sync (WSL Windows → WSL Linux)
- Contains: Single polling daemon script
- Key files: `scripts/zotero/sync.sh`

**`systemd/`:**
- Purpose: Systemd unit files for background services
- Contains: Two unit files
- Key files: `systemd/ice.service`, `systemd/zotero.service`
- Installation: `sudo ln -sf <repo>/systemd/<name>.service /etc/systemd/system/` via `make <name>-link`

**`.git-hooks/`:**
- Purpose: Repo-local git lifecycle hooks, pointed to by `config/.gitconfig` (`core.hooksPath = ~/.git-hooks`)
- Contains: `post-commit` only
- Key files: `.git-hooks/post-commit`
- Note: `core.hooksPath` in `.gitconfig` points to `~/.git-hooks` (home dir), so hooks are active globally for this user after `make setup-gitconfig`

**`.planning/`:**
- Purpose: GSD planning documents (architecture maps, phase plans)
- Contains: `codebase/` subdirectory with analysis docs
- Generated: No — committed
- Committed: Yes

## Key File Locations

**Entry Points:**
- `config/.bash_profile`: Shell environment entry point — sourced by `~/.bashrc`
- `Makefile`: Primary developer interface for all setup and service management
- `systemd/ice.service`: Boot-time SSHFS mount service
- `systemd/zotero.service`: Boot-time bib sync daemon

**Configuration:**
- `.env.sample`: Documents all required environment variables with defaults and descriptions
- `config/.gitconfig`: Git configuration hard-linked to `~/.gitconfig`
- `config/.tmux.conf`: Tmux configuration hard-linked to `~/.tmux.conf`
- `pyproject.toml`: Python project metadata for uv

**Core Logic:**
- `scripts/ice/mount.sh`: ICE SSHFS mount logic with fallback across ice00–ice11
- `scripts/ice/ssh.exp`: Automated SSH password injection via Expect
- `scripts/zotero/sync.sh`: Polling bib sync loop
- `scripts/tmux/yank`: Portable clipboard writer

**Testing:**
- `scripts/tmux/tests/`: Manual stress tests for each tmux status script

## Naming Conventions

**Files:**
- Shell scripts: lowercase, hyphen-separated words with `.sh` extension (`mount.sh`, `fix-cv2-fonts.sh`, `sync.sh`)
- Tmux status scripts: lowercase single word, no extension (`cpu`, `ram`, `disk`, `gpu`, `netspeed`, `yank`)
- Expect scripts: lowercase with `.exp` extension (`ssh.exp`)
- Test scripts: `test-<target>.sh` pattern in `tests/` subdir (`test-cpu.sh`)
- Systemd units: `<service-name>.service` (`ice.service`, `zotero.service`)
- Dotfiles: leading dot, matching standard dotfile names (`.bash_profile`, `.gitconfig`, `.tmux.conf`)

**Directories:**
- Subsystem grouping: lowercase single word (`ice/`, `tmux/`, `zotero/`)
- Top-level purpose grouping: lowercase plural noun (`scripts/`, `config/`, `systemd/`)

## Where to Add New Code

**New HPC/remote-access automation:**
- Scripts: `scripts/ice/`
- If it needs a systemd service: `systemd/<name>.service` + corresponding Makefile targets

**New tmux status bar metric:**
- Script: `scripts/tmux/<metric-name>` (no extension, executable, no args, prints one short string)
- Test: `scripts/tmux/tests/test-<metric-name>.sh`
- Wire up: Add `#(/home/jaeho/jaehho/scripts/tmux/<metric-name>)` to `status-right` in `config/.tmux.conf`

**New shell helper or alias:**
- Add to `config/.bash_profile`

**New background sync or daemon service:**
- Script: `scripts/<subsystem>/` directory or new subdir under `scripts/`
- Unit file: `systemd/<name>.service`
- Makefile targets: follow the `<name>-link`, `<name>-reload`, `<name>-enable`, `<name>-start`, `<name>-stop`, `<name>-restart`, `<name>-status` pattern

**New environment variable:**
- Document in `.env.sample` with comment explaining purpose and which script consumes it
- Mark sensitive vars with names containing `PASSWORD`, `SECRET`, `KEY`, or `TOKEN` (the `make setup-env` prompt masks these)

**New Python tooling:**
- Dependencies managed via `uv`; install targets go in the `## Dependencies` section of `Makefile`

## Special Directories

**`.git-hooks/`:**
- Purpose: Git lifecycle hooks for the repository
- Generated: No
- Committed: Yes
- Note: Activated globally (not just for this repo) once `config/.gitconfig` is linked to `~/.gitconfig`, because `core.hooksPath = ~/.git-hooks`

**`.planning/`:**
- Purpose: GSD codebase maps and phase plans
- Generated: No
- Committed: Yes

**`.venv/` (not committed):**
- Purpose: Python virtual environment managed by uv
- Generated: Yes (by `uv`)
- Committed: No (in `.gitignore`)

---

*Structure analysis: 2026-03-08*
