# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Personal dotfiles repo using GNU Stow, Make, and profile-based configuration. Manages configs across two environments: Arch Linux desktop (Hyprland) and Ubuntu server.

## Key Commands

- `make help` — list all targets
- `make sync` — full sync (install packages, stow configs, reload apps, create .env)
- `make upgrade` — install/upgrade system packages
- `make apply` — stow configs, enable services, and reload running apps
- `make clean` — reverse setup (unstow, disable services, remove hooks)
- `make status` — show current dotfiles state
- `make stow-<pkg>` / `make unstow-<pkg>` — stow/unstow a single package (e.g., `make stow-nvim`)
- `make env` — interactively generate `.env` from `.env.sample`

Profile auto-detects if not specified (saved to `~/.dotfiles-profile`).

## Architecture

**Profile system** (`profiles/*.conf`): Each profile declares `STOW_PACKAGES`, `SERVICES`, `SYSTEM_CONFIGS`, `SLEEP_HOOKS`, and optionally `INHERIT` for parent chaining. Resolution is recursive — `arch.conf` inherits from `common.conf`, getting both sets of packages merged. `SYSTEM_CONFIGS` symlinks a repo directory into `/etc/<name>/` (e.g., `libinput` → `/etc/libinput/`).

**Package installation** (`scripts/install-packages.sh`): Reads `packages/common.txt` + `packages/<profile>.txt`. Cross-distro name differences handled via `packages/mappings.conf` (canonical:apt:pacman format). AUR packages prefixed with `AUR:` in package lists. On apt systems, neovim is built from source since apt's version is too old.

**Stow packages** (`stow/`): Each subdirectory mirrors `$HOME`. Applied with `--no-folding --adopt` then `git checkout` to restore repo versions. The `bash` package stows `.bash_profile` normally; `apply-profile.sh` adds a `source ~/.bash_profile` line to `~/.bashrc` (marked with `# DOTFILES_BASH_PROFILE` for idempotency).

**Reload scripts** (`reload/`): Each stow package can have a corresponding `reload/<pkg>.sh` script that `apply-profile.sh` runs after stowing. Adding a new reloadable package requires only adding a script — no edits to `apply-profile.sh`.

**Services** (`systemd/`): Service files are templates (`*.service.tmpl`) with `%REPO_ROOT%` and `%USER%` placeholders. `apply-profile.sh` generates concrete files into `systemd/.generated/` (gitignored), then symlinks them to `/etc/systemd/system/`. If a matching config directory exists at repo root (e.g., `keyd/`), its contents are linked to `/etc/<service>/`.

**Sleep hooks** (`system-sleep/`): Scripts copied to `/usr/lib/systemd/system-sleep/` for suspend/resume handling.

**Environment** (`.env`): Secrets (ICE cluster credentials) stored in `.env`, loaded via direnv. Gitignored. Generated interactively from `.env.sample`. Use `bootstrap.sh --no-secrets` to skip this step.

**Utility scripts** (`scripts/`): `update-nvim.sh` builds neovim from source (used on apt systems); `ice/mount.sh` and `ice/ssh.exp` manage ICE cluster connections.

## Hyprland Configuration

The Hyprland config uses a modular split. `hyprland.conf` only contains `source` statements pointing to `conf.d/`:

- `env.conf` — Environment variables (XDG, Qt, cursor)
- `nvidia.conf` — NVIDIA-specific env vars and cursor settings
- `monitors.conf` — Monitor layout, workspace binding, lid switch
- `autostart.conf` — Programs, exec-once statements
- `appearance.conf` — general, decoration, animations, layout, misc, binds, permissions
- `input.conf` — Keyboard, mouse, touchpad, gestures
- `keybindings.conf` — All binds (uses `bindd` for descriptions where possible)
- `windowrules.conf` — All window/layer rules

## Desktop Utility Scripts

Located in `stow/hypr/.local/lib/dotfiles/`:

- `volumecontrol.sh` — Volume up/down/mute with OSD notification
- `brightnesscontrol.sh` — Brightness up/down with smart stepping and OSD
- `screenshot.sh` — Full/region/annotate screenshot modes
- `clipboard.sh` — Rofi-based cliphist manager
- `wallpaper.sh` — swww wallpaper management with optional matugen theming
- `gamemode.sh` — Toggle animations/gaps off for gaming performance
- `keybinds-hint.sh` — Parse bindd descriptions and show in rofi

## Theming

Uses matugen for dynamic Material Design 3 color generation from wallpapers. Each app has a color include file that matugen overwrites:

- Kitty: `~/.config/kitty/theme.conf`
- Waybar: colors in `style.css`
- Hyprland: border colors in `conf.d/appearance.conf`
- Mako: colors in `config`
- Hyprlock: colors in `hyprlock.conf`

Catppuccin Mocha is the default/fallback when matugen is not installed or no wallpaper is set.

## Shell

- **Bash** — Used on all environments. `.bash_profile` handles direnv, fzf, starship, ICE SSH wrapper, Hyprland autostart on TTY1.
- **Fish** — Desktop interactive shell on Arch (set as kitty's shell). Config in `stow/fish/`.
