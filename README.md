## Overview
Personal productivity and reference tools: system setup helpers, ICE SSHFS mounting, and a Markdown → Typst helper.

Add new scripts under [scripts/](scripts/) and dotfiles under [config/](config/).

## Contents
- [Makefile](Makefile): task entrypoint for setup and service management (`make help` for current targets).
- [config/.gitconfig](config/.gitconfig), [config/.bash_profile](config/.bash_profile): personal settings.
- [scripts/md2typ.bash](scripts/md2typ.bash): `md2typ` helper (uses `pandoc`, optional `xclip`).
- [scripts/ice/mount-ice.sh](scripts/ice/mount-ice.sh): SSHFS mount (tries ice00–ice11, uses `ICE_PASSWORD`).
- [scripts/ice/ssh-ice.exp](scripts/ice/ssh-ice.exp): Expect SSH login using `ICE_PASSWORD`.
- [systemd/ice.service](systemd/ice.service): systemd oneshot unit (start mount, stop unmount).
- [systemd/zotero.service](systemd/zotero.service): systemd unit for continuous Zotero bibliography sync.
- [.env](.env): config + secrets (don’t commit real passwords).

## Quick use
Personal setup:
1. `make setup-all`

ICE mount:
1. Set `ICE_PASSWORD` in `.env`.
2. First-time setup (or after editing service file):
	- `make ice-link`
	- `make ice-enable`
3. Start and verify:
	- `make ice-start`
	- `make ice-status`

Zotero bib sync:
1. First-time setup (or after editing service file):
	- `make zotero-link`
	- `make zotero-enable`
2. Start and verify:
	- `make zotero-start`
	- `make zotero-status`

## Requirements
`sshfs`, `fuse/fusermount`, `expect`, `pandoc` (optional `xclip`).
