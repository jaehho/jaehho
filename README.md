## Overview
Personal productivity and reference tools: system setup helpers, ICE SSHFS mounting, and a Markdown → Typst helper.

Add new scripts under [scripts/](scripts/) and dotfiles under [config/](config/).

## Contents
- [Makefile](Makefile): `make setup|link-gitconfig|bashrc|link|enable|start|stop|restart|status`.
- [config/.gitconfig](config/.gitconfig), [config/.bash_profile](config/.bash_profile): personal settings.
- [scripts/md2typ.bash](scripts/md2typ.bash): `md2typ` helper (uses `pandoc`, optional `xclip`).
- [scripts/ice/mount-ice.sh](scripts/ice/mount-ice.sh): SSHFS mount (tries ice00–ice11, uses `ICE_PASSWORD`).
- [scripts/ice/ssh-ice.exp](scripts/ice/ssh-ice.exp): Expect SSH login using `ICE_PASSWORD`.
- [systemd/ice.service](systemd/ice.service): systemd oneshot unit (start mount, stop unmount).
- [.env](.env): config + secrets (don’t commit real passwords).

## Quick use
Personal setup:
1. `make setup`

ICE mount:
1. Set `ICE_PASSWORD` in `.env`.
2. `make link && make enable && make start`
3. `make status`

## Requirements
`sshfs`, `fuse/fusermount`, `expect`, `pandoc` (optional `xclip`).
