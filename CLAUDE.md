# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Personal dotfiles repo using GNU Stow, Make, and profile-based configuration. Manages configs across three environments: Arch Linux desktop (Hyprland), Ubuntu server, and WSL2.

## Key Commands

- `make help` — list all targets
- `make bootstrap` — full setup (install packages, stow configs, create .env)
- `make install` — install system packages only
- `make setup` — stow configs and enable services only
- `make stow-<pkg>` / `make unstow-<pkg>` — stow/unstow a single package (e.g., `make stow-nvim`)
- `make setup-env` — interactively generate `.env` from `.env.sample`

Profile auto-detects if not specified (saved to `~/.dotfiles-profile`).

## Architecture

**Profile system** (`profiles/*.conf`): Each profile declares `STOW_PACKAGES`, `SERVICES`, `SLEEP_HOOKS`, and optionally `INHERIT` for parent chaining. Resolution is recursive — `arch.conf` inherits from `common.conf`, getting both sets of packages merged.

**Package installation** (`scripts/install-packages.sh`): Reads `packages/common.txt` + `packages/<profile>.txt`. Cross-distro name differences handled via `packages/mappings.conf` (canonical:apt:pacman format). AUR packages prefixed with `AUR:` in package lists. On apt systems, neovim is built from source since apt's version is too old.

**Stow packages** (`stow/`): Each subdirectory mirrors `$HOME`. Applied with `--no-folding --adopt` then `git checkout` to restore repo versions. The `bash` package is special — its `.bash_profile` is sourced from `~/.bashrc` rather than stowed directly.

**Services** (`systemd/`): Service files are symlinked to `/etc/systemd/system/` and enabled. If a matching config directory exists at repo root (e.g., `keyd/`), its contents are linked to `/etc/<service>/`.

**Sleep hooks** (`system-sleep/`): Scripts copied to `/usr/lib/systemd/system-sleep/` for suspend/resume handling.

**Environment** (`.env` / `.envrc`): Secrets (ICE cluster credentials) stored in `.env`, loaded via `.envrc` (direnv). Both are gitignored. Generated interactively from `.env.sample` / `.envrc.sample`.
