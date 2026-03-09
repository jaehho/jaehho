# Technology Stack

**Analysis Date:** 2026-03-08

## Languages

**Primary:**
- Bash - All automation scripts (`scripts/ice/mount.sh`, `scripts/zotero/sync.sh`, `scripts/tmux/*`, `scripts/fix-cv2-fonts.sh`, `config/.bash_profile`)

**Secondary:**
- Python 3.14.3 - ML/CV workloads via `uv`-managed virtualenv (referenced in `scripts/fix-cv2-fonts.sh` and `pyproject.toml`)
- Tcl/Expect - Automated SSH interaction (`scripts/ice/ssh.exp`)

## Runtime

**Environment:**
- Linux (native and WSL2 — both supported, `scripts/tmux/netspeed` auto-detects interface)

**Package Manager:**
- `uv` - Python package management (used in `Makefile` `install-python` target)
- `apt` - System package management (used in `Makefile` `install-apt` target)
- Lockfile: Not present (no `uv.lock` or `requirements.txt`)

## Frameworks

**Core:**
- None — this is a personal dotfiles/devops configuration repository, not an application framework

**Build/Dev:**
- GNU Make - Task runner (`Makefile`)
- direnv - Per-directory environment loading (`.envrc` sourced via `direnv hook bash` in `config/.bash_profile`)
- tmux 3.5a - Terminal multiplexer with custom status bar (`config/.tmux.conf`)

## Key Dependencies

**Python (ML/CV):**
- `torch` + `torchvision` - Installed via `uv` from PyTorch CUDA 13.0 index (`https://download.pytorch.org/whl/cu130`)
- `opencv-python` (cv2) - Implied by `scripts/fix-cv2-fonts.sh` which patches cv2 Qt font paths

**System (apt-installed):**
- `sshfs` - FUSE-based remote filesystem mount
- `tmux` - Terminal multiplexer
- `expect` - Automated interactive CLI (used for SSH password automation)
- `direnv` - Environment variable management
- `sysstat` - System stats (`mpstat` used in `scripts/tmux/cpu`)
- `iproute2` - Network interface info (`ip` used in `scripts/tmux/netspeed`)
- `curl` - General HTTP utility

**GPU tooling:**
- `nvidia-smi` - GPU utilization query (used in `scripts/tmux/gpu`)

## Configuration

**Environment:**
- `.env` - Primary secrets file (not committed); template at `.env.sample`
- `.envrc` - direnv activation file (activates `.venv`); template at `.envrc.sample`
- Variables: `MOUNTPOINT`, `REMOTE_PATH`, `REMOTE_USER`, `LOCAL_USER`, `ICE_PASSWORD`
- `ICE_PASSWORD` is the only secret required; used by both mount and SSH scripts

**Build:**
- `pyproject.toml` - Minimal Python project definition, Python >= 3.12 required
- `Makefile` - All setup and service management targets

## Platform Requirements

**Development:**
- Python >= 3.12
- `uv` installed
- NVIDIA GPU + drivers (for `nvidia-smi` tmux widget)
- WSL2 or native Linux

**Production:**
- systemd (for `ice.service` and `zotero.service`)
- FUSE/sshfs for ICE cluster mounting
- Network access to `*.ee.cooper.edu` on port 31415

---

*Stack analysis: 2026-03-08*
