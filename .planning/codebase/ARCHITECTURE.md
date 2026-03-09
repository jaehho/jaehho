# Architecture

**Analysis Date:** 2026-03-08

## Pattern Overview

**Overall:** Dotfiles and automation repository — a personal environment management monorepo.

**Key Characteristics:**
- No application runtime; all components are shell scripts, config files, and systemd units
- Makefile-driven orchestration for installation/linking of config files and managing services
- Environment secrets sourced from a single `.env` file and propagated to scripts and systemd units
- Three distinct subsystems: ICE cluster access, Zotero sync, and tmux status bar

## Layers

**Configuration Layer:**
- Purpose: Stores user dotfiles that are symlinked or hard-linked into `$HOME`
- Location: `config/`
- Contains: `.bash_profile`, `.gitconfig`, `.tmux.conf`
- Depends on: Nothing (standalone config files)
- Used by: Shell (bash sources `.bash_profile`), git (reads `.gitconfig`), tmux (reads `.tmux.conf`)

**Scripts Layer:**
- Purpose: Executable automation scripts invoked by shell aliases, tmux, or systemd
- Location: `scripts/`
- Contains: Bash scripts, an Expect script, organized by subsystem (`ice/`, `tmux/`, `zotero/`)
- Depends on: `.env` for secrets, system tools (`sshfs`, `expect`, `nvidia-smi`, `mpstat`, etc.)
- Used by: `config/.bash_profile` (ssh wrapper calls `scripts/ice/ssh.exp`), `config/.tmux.conf` (status scripts), systemd units

**Service Layer:**
- Purpose: Systemd unit files that run scripts as persistent or one-shot background services
- Location: `systemd/`
- Contains: `ice.service` (SSHFS mount), `zotero.service` (bib sync daemon)
- Depends on: `.env` (via `EnvironmentFile=`), scripts in `scripts/`
- Used by: Installed into `/etc/systemd/system/` via `make *-link` targets

**Orchestration Layer:**
- Purpose: Wires setup, installation, and service lifecycle management
- Location: `Makefile`
- Contains: Targets for linking configs, installing apt/python deps, managing systemd service lifecycle
- Depends on: All other layers
- Used by: Developer directly via `make <target>`

**Environment Layer:**
- Purpose: Secrets and runtime parameters for all scripts and services
- Location: `.env` (gitignored), `.env.sample` (committed template), `.envrc` (gitignored), `.envrc.sample`
- Contains: `ICE_PASSWORD`, `MOUNTPOINT`, `REMOTE_PATH`, `REMOTE_USER`, `LOCAL_USER`
- Depends on: Nothing
- Used by: `scripts/ice/mount.sh`, `scripts/ice/ssh.exp` (via `config/.bash_profile`), `systemd/ice.service`

## Data Flow

**ICE SSH Login:**

1. User types `ssh ice03` in shell
2. `ssh` wrapper function in `config/.bash_profile` matches the hostname pattern
3. `_ice_load_env()` sources `.env`, exporting `ICE_PASSWORD`
4. `scripts/ice/ssh.exp` is invoked with target host and any extra args
5. Expect script spawns `ssh -X -Y -p31415 <host>`, auto-accepts host key, sends password
6. Interactive SSH session handed back to user

**ICE SSHFS Mount (via systemd):**

1. `systemd/ice.service` starts after `network-online.target`
2. Service reads `EnvironmentFile=/home/jaeho/jaehho/.env` to get `ICE_PASSWORD`
3. `scripts/ice/mount.sh` iterates ice00–ice11, attempts `sshfs` with `password_stdin`
4. First successful mount exits; filesystem available at `/mnt/ice`
5. On service stop: `fusermount -u /mnt/ice` unmounts

**Zotero Bib Sync (via systemd):**

1. `systemd/zotero.service` runs `scripts/zotero/sync.sh` as user `jaeho`
2. Script polls every 5 seconds, comparing md5 of source (`/mnt/c/Users/jaeho/wsl_link/Neuroscience.bib`) to destination
3. On hash mismatch, copies source to `$HOME/neuro/paper/references.bib`

**Tmux Status Bar:**

1. `config/.tmux.conf` calls status scripts every 5 seconds via `#(...)`
2. Each script in `scripts/tmux/` queries a system resource and prints a short string
3. `scripts/tmux/yank` is invoked on copy-mode `y` or `Enter` to pipe selection to system clipboard

**Environment Setup (one-time):**

1. `make setup-env` copies `.env.sample` to `.env`, prompts for values interactively (passwords masked)
2. `make setup-gitconfig` hard-links `config/.gitconfig` to `~/.gitconfig`
3. `make setup-bashrc` appends `source <path>/config/.bash_profile` to `~/.bashrc`
4. `make setup-tmux` hard-links `config/.tmux.conf` to `~/.tmux.conf`

## Key Abstractions

**`_ice_load_env` helper:**
- Purpose: Lazily loads `.env` only when an ICE command is needed; avoids polluting the shell environment permanently
- Examples: `config/.bash_profile` lines 5–15
- Pattern: Called at invocation time, not at shell startup

**`ssh` wrapper:**
- Purpose: Transparently intercepts `ssh <ice-host>` calls and injects password automation
- Examples: `config/.bash_profile` lines 18–38
- Pattern: Shell function overriding the `ssh` builtin; falls through to `command ssh` for non-ICE hosts

**Makefile service lifecycle targets:**
- Purpose: Provide a consistent interface for linking, enabling, starting, stopping, and restarting systemd services
- Examples: `Makefile` targets `ice-link`, `ice-enable`, `ice-start`, `ice-status` (and zotero equivalents)
- Pattern: Each service has a parallel set of `<name>-link`, `<name>-reload`, `<name>-enable`, `<name>-start`, `<name>-stop`, `<name>-restart`, `<name>-status` targets

**Tmux status scripts:**
- Purpose: Single-responsibility executables each printing one metric for the status bar
- Examples: `scripts/tmux/cpu`, `scripts/tmux/ram`, `scripts/tmux/disk`, `scripts/tmux/gpu`, `scripts/tmux/netspeed`
- Pattern: No arguments, print a short human-readable string to stdout, exit 0

## Entry Points

**Interactive Shell (`~/.bashrc`):**
- Location: Delegates to `config/.bash_profile`
- Triggers: Every new bash interactive session
- Responsibilities: Loads ICE helpers and `ssh` wrapper, auto-attaches to tmux, activates direnv, sets PS1

**Makefile:**
- Location: `Makefile`
- Triggers: `make <target>` invoked by user
- Responsibilities: Environment bootstrap, config linking, dependency installation, systemd service management

**`systemd/ice.service`:**
- Location: `systemd/ice.service` (linked to `/etc/systemd/system/`)
- Triggers: Boot, after `network-online.target`; or manually via `make ice-start`
- Responsibilities: Mounts ICE AFS filesystem at `/mnt/ice`

**`systemd/zotero.service`:**
- Location: `systemd/zotero.service` (linked to `/etc/systemd/system/`)
- Triggers: Boot; restarts automatically on exit
- Responsibilities: Keeps `references.bib` in sync from WSL Windows filesystem

## Error Handling

**Strategy:** Fail-fast with descriptive stderr messages; scripts use `set -euo pipefail` where appropriate.

**Patterns:**
- `scripts/ice/mount.sh`: Validates `ICE_PASSWORD`, `LOCAL_USER`, and `LOCAL_GID` before proceeding; iterates all hosts and exits non-zero if all fail
- `scripts/ice/ssh.exp`: Checks `ICE_PASSWORD` env var presence; exits 1 with error message if missing
- `config/.bash_profile` `_ice_load_env`: Returns 1 (propagating failure) if `.env` not found

## Cross-Cutting Concerns

**Logging:** Scripts write status/error messages to stderr (`>&2`); systemd captures stdout/stderr via journald.
**Validation:** Env var presence checked at invocation time in each script, not centrally.
**Authentication:** All ICE authentication flows through `ICE_PASSWORD` from `.env`; no SSH keys used for ICE cluster access.

---

*Architecture analysis: 2026-03-08*
