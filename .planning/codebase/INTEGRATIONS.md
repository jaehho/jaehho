# External Integrations

**Analysis Date:** 2026-03-08

## Remote Compute Clusters

**Cooper Union ICE Cluster:**
- Purpose: Remote HPC/research computing access (SSHFS mount + interactive SSH)
- Hosts: `ice00.ee.cooper.edu` through `ice11.ee.cooper.edu` (12 nodes, tried in order)
- Port: `31415` (non-standard SSH port)
- Protocol: SSHFS over SSH with password authentication
- Auth: `ICE_PASSWORD` env var (stored in `.env`, never committed)
- Mount script: `scripts/ice/mount.sh`
- SSH script: `scripts/ice/ssh.exp` (Expect-based password automation)
- Remote path: `/afs/ee.cooper.edu/user/j/jaeho.cho` (AFS filesystem)
- Local mount point: `/mnt/ice` (configurable via `MOUNTPOINT` env var)
- Systemd service: `systemd/ice.service` (managed via `Makefile` ice-* targets)

## Reference Management

**Zotero (Windows -> WSL2 sync):**
- Purpose: Sync Zotero bibliography file from Windows to WSL2 filesystem
- Source: `/mnt/c/Users/jaeho/wsl_link/Neuroscience.bib` (Windows path via WSL mount)
- Destination: `$HOME/neuro/paper/references.bib`
- Mechanism: Polling loop with md5sum comparison, 5-second interval
- Sync script: `scripts/zotero/sync.sh`
- Systemd service: `systemd/zotero.service` (runs as user `jaeho`, managed via Makefile zotero-* targets)
- Note: No network call — local filesystem copy only

## ML Frameworks

**PyTorch (CUDA):**
- Purpose: GPU-accelerated deep learning
- Source: `https://download.pytorch.org/whl/cu130` (CUDA 13.0 build index)
- Packages: `torch`, `torchvision`
- Install target: `make install-python`
- Runtime requirement: NVIDIA GPU + compatible CUDA drivers

## Shell Environment

**Claude Code CLI:**
- Purpose: AI assistant invocation shortcut
- Alias: `c='claude --dangerously-skip-permissions'` in `config/.bash_profile`
- No API key management visible in this repo (assumed handled externally)

## System Monitoring Integrations

**nvidia-smi:**
- Purpose: Real-time GPU utilization in tmux status bar
- Script: `scripts/tmux/gpu`
- Output: GPU utilization percentage

**sysstat / mpstat:**
- Purpose: CPU utilization in tmux status bar
- Script: `scripts/tmux/cpu`
- Sampling: 1-second measurement window

**procfs (`/proc/net/dev`):**
- Purpose: Network throughput in tmux status bar
- Script: `scripts/tmux/netspeed`
- Output: KB/s down/up on auto-detected default route interface

## File Storage

**Databases:** Not applicable
**File Storage:** Local filesystem only (plus SSHFS remote mount)
**Caching:** None

## Authentication & Identity

**ICE Cluster SSH:**
- Method: Password authentication (no key-based auth configured)
- Secret: `ICE_PASSWORD` in `.env`
- Automation: `scripts/ice/ssh.exp` (Expect script feeds password to SSH prompt)
- Host key handling: `StrictHostKeyChecking=accept-new` with known_hosts at `/root/.ssh/known_hosts`

## Webhooks & Callbacks

**Incoming:** None
**Outgoing:** None

## Environment Configuration

**Required env vars (from `.env.sample`):**
- `MOUNTPOINT` - Local mount point for ICE SSHFS (default: `/mnt/ice`)
- `REMOTE_PATH` - AFS path on ICE cluster
- `REMOTE_USER` - SSH username on ICE cluster
- `LOCAL_USER` - Linux user to own mounted files
- `ICE_PASSWORD` - SSH password for ICE cluster (sensitive)

**Secrets location:**
- `.env` file at repo root (git-ignored, generated from `.env.sample` via `make setup-env`)
- Loaded by systemd via `EnvironmentFile=` directive in `systemd/ice.service`
- Loaded by shell via `_ice_load_env()` helper in `config/.bash_profile`

---

*Integration audit: 2026-03-08*
