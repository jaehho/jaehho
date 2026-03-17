# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Personal dotfiles repo using GNU Stow, Make, and profile-based configuration. Manages configs across two environments: Arch Linux desktop (Hyprland) and Ubuntu server.

## Key Commands

- `make help` — list all targets
- `make bootstrap` — full setup (install packages, stow configs, create .env)
- `make install` — install system packages only
- `make setup` — stow configs and enable services only
- `make clean` — reverse setup (unstow, disable services, remove hooks)
- `make status` — show current dotfiles state
- `make stow-<pkg>` / `make unstow-<pkg>` — stow/unstow a single package (e.g., `make stow-nvim`)
- `make setup-env` — interactively generate `.env` from `.env.sample`

Profile auto-detects if not specified (saved to `~/.dotfiles-profile`).

## Architecture

**Profile system** (`profiles/*.conf`): Each profile declares `STOW_PACKAGES`, `SERVICES`, `SYSTEM_CONFIGS`, `SLEEP_HOOKS`, and optionally `INHERIT` for parent chaining. Resolution is recursive — `arch.conf` inherits from `common.conf`, getting both sets of packages merged. `SYSTEM_CONFIGS` symlinks a repo directory into `/etc/<name>/` (e.g., `libinput` → `/etc/libinput/`).

**Package installation** (`scripts/install-packages.sh`): Reads `packages/common.txt` + `packages/<profile>.txt`. Cross-distro name differences handled via `packages/mappings.conf` (canonical:apt:pacman format). AUR packages prefixed with `AUR:` in package lists. On apt systems, neovim is built from source since apt's version is too old.

**Stow packages** (`stow/`): Each subdirectory mirrors `$HOME`. Applied with `--no-folding --adopt` then `git checkout` to restore repo versions. The `bash` package stows `.bash_profile` normally; `apply-profile.sh` adds a `source ~/.bash_profile` line to `~/.bashrc` (marked with `# DOTFILES_BASH_PROFILE` for idempotency).

**Services** (`systemd/`): Service files are templates (`*.service.tmpl`) with `%REPO_ROOT%` and `%USER%` placeholders. `apply-profile.sh` generates concrete files into `systemd/.generated/` (gitignored), then symlinks them to `/etc/systemd/system/`. If a matching config directory exists at repo root (e.g., `keyd/`), its contents are linked to `/etc/<service>/`.

**Sleep hooks** (`system-sleep/`): Scripts copied to `/usr/lib/systemd/system-sleep/` for suspend/resume handling.

**Environment** (`.env`): Secrets (ICE cluster credentials) stored in `.env`, loaded via direnv. Gitignored. Generated interactively from `.env.sample`. Use `bootstrap.sh --no-secrets` to skip this step.

**Utility scripts** (`scripts/`): `update-nvim.sh` builds neovim from source (used on apt systems); `ice/mount.sh` and `ice/ssh.exp` manage ICE cluster connections.
