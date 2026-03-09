# Codebase Concerns

**Analysis Date:** 2026-03-08

## Tech Debt

**Password-based SSH authentication (no key-based auth):**
- Issue: All ICE cluster access relies on a plaintext password stored in `.env` and passed via `expect`. SSH key-based authentication is not used.
- Files: `scripts/ice/ssh.exp`, `scripts/ice/mount.sh`, `systemd/ice.service`
- Impact: Password is passed as a process argument and via stdin; visible in process lists and shell history. `expect` scripts are brittle and break on server banner changes or prompt format changes.
- Fix approach: Generate an SSH keypair, upload to ICE cluster, replace `expect` with direct `ssh -i key` and `sshfs -o IdentityFile=key`.

**Hard-coded absolute paths in tmux config:**
- Issue: `.tmux.conf` hard-codes `/home/jaeho/jaehho/scripts/tmux/yank` and all status bar scripts reference `/home/jaeho/jaehho/scripts/tmux/...`.
- Files: `config/.tmux.conf` (lines 41, 42, 61–68)
- Impact: Config breaks entirely on any other machine, username, or home directory. The whole dotfiles approach is undermined.
- Fix approach: Use an environment variable like `$JAEHHO_ROOT` or resolve paths relative to the config file at load time via `run-shell`.

**Zotero sync script uses WSL-specific Windows path:**
- Issue: `sync.sh` hard-codes `/mnt/c/Users/jaeho/wsl_link/Neuroscience.bib` as the source path.
- Files: `scripts/zotero/sync.sh` (line 3), `systemd/zotero.service`
- Impact: Script silently fails with `md5sum: '/mnt/c/Users/jaeho/...': No such file or directory` on non-WSL systems. The systemd service has no error handling for this.
- Fix approach: Make source path configurable via an env var with a documented default; add existence check before entering the loop.

**Makefile uses `.IGNORE` globally:**
- Issue: The top-level `Makefile` sets `.IGNORE:` which suppresses all errors from all targets, including destructive ones like `sudo ln -sf`.
- Files: `Makefile` (line 3)
- Impact: Silent failures during setup — a failed symlink or permission error will not abort `make setup-all`. Hard to diagnose setup problems.
- Fix approach: Remove `.IGNORE:` globally; add per-target error handling where silent failure is intentional (e.g., using `-` prefix on specific recipe lines).

**gitconfig `update-config` alias fetches and overwrites without review:**
- Issue: The alias `update-config` runs `curl -s ... -o ~/.gitconfig` which silently overwrites the local gitconfig with whatever is at the remote URL, with no diff or confirmation.
- Files: `config/.gitconfig` (line 26)
- Impact: Any change (including accidental or malicious) pushed to the remote branch would overwrite local git configuration immediately upon running the alias.
- Fix approach: Pipe through a diff first, or fetch to a temp file and prompt before replacing.

## Security Considerations

**Password passed via stdin to sshfs:**
- Risk: `echo "$PASSWORD" | /usr/bin/sshfs -o password_stdin ...` exposes the password in a pipeline. The variable also appears in the process environment of the spawned shell.
- Files: `scripts/ice/mount.sh` (line 43)
- Current mitigation: `.env` is gitignored; the file has `0644` permissions (readable by any user on the system).
- Recommendations: Restrict `.env` permissions to `0600`. Prefer SSH key auth to eliminate password handling entirely.

**`.env` file world-readable:**
- Risk: File permissions on `/home/jaeho/jaehho/.env` are `0644`, meaning any local user on the machine can read `ICE_PASSWORD`.
- Files: `.env`
- Current mitigation: `.env` is gitignored.
- Recommendations: Run `chmod 600 /home/jaeho/jaehho/.env`; add a `make check-env-perms` target or enforce in the `setup-env` target post-creation.

**`expect` script auto-accepts unknown host keys:**
- Risk: `ssh.exp` sends `yes\r` unconditionally when it sees the "Are you sure you want to continue connecting" prompt, accepting any host key — including from a MITM.
- Files: `scripts/ice/ssh.exp` (lines 25–28)
- Current mitigation: `mount.sh` uses `StrictHostKeyChecking=accept-new` which only accepts truly new hosts; `ssh.exp` has no equivalent guard.
- Recommendations: Pre-populate `~/.ssh/known_hosts` with ICE server fingerprints and set `StrictHostKeyChecking=yes` in both scripts.

**`claude --dangerously-skip-permissions` aliased in shell:**
- Risk: The alias `c='claude --dangerously-skip-permissions'` in `.bash_profile` disables Claude's permission safety checks for every invocation via `c`.
- Files: `config/.bash_profile` (line 100)
- Current mitigation: None — this is an intentional convenience alias.
- Recommendations: Document the intent explicitly in a comment; consider an alias name less likely to be used accidentally.

## Performance Bottlenecks

**`netspeed` script sleeps 1 second every status bar refresh:**
- Problem: `scripts/tmux/netspeed` runs `sleep 1` inline to sample bytes-per-second. tmux calls all status scripts at every `status-interval` (5 seconds), so this script blocks for 1 second of each 5-second cycle.
- Files: `scripts/tmux/netspeed` (line 9), `config/.tmux.conf` (line 62)
- Cause: The 1-second sleep is the sampling window for delta calculation. tmux spawns the script synchronously in the status refresh.
- Improvement path: Cache the previous sample to a tmpfile and compute the delta between refresh cycles, eliminating the sleep.

**`cpu` script runs `mpstat 1 1` (1-second blocking call) on every refresh:**
- Problem: `scripts/tmux/cpu` runs `mpstat 1 1` which blocks for 1 second per status bar refresh.
- Files: `scripts/tmux/cpu`, `config/.tmux.conf`
- Cause: Same pattern as netspeed — sampling window equals a blocking sleep.
- Improvement path: Read `/proc/stat` twice with a short sleep, or cache to a tmpfile updated by a background process.

## Fragile Areas

**`zotero/sync.sh` — infinite loop with no error handling:**
- Files: `scripts/zotero/sync.sh`
- Why fragile: If the source path (`/mnt/c/...`) does not exist, `md5sum` exits with an error on every iteration. The loop continues indefinitely printing errors with no backoff, no exit, and no alerting. The systemd service will spin at 100% CPU in this failure mode.
- Safe modification: Add a file existence check before `md5sum`; add a configurable sleep on error; add `StandardError=journal` to the service unit.
- Test coverage: None.

**`ssh.exp` — fragile prompt matching with `expect`:**
- Files: `scripts/ice/ssh.exp`
- Why fragile: The `expect` pattern `-re "password:*"` uses a glob `*` not a regex `+`, matching "passwor", "password", "passworddddd", etc. Server-side MOTD changes, two-factor prompts, or updated SSH banners can cause `expect` to time out or send the password at the wrong moment.
- Safe modification: Use `-re {[Pp]assword: ?$}` and add a timeout handler that prints a useful message.
- Test coverage: None.

**`config/.gitconfig` is a hard link, not a symlink:**
- Files: `config/.gitconfig`, `Makefile` (line 88)
- Why fragile: `ln -f` creates a hard link. Hard links do not work across filesystems. If `~` and the repo root are on different filesystems this silently fails with an error that `.IGNORE` swallows.
- Safe modification: Use `ln -sf` (symlink) as done for other configs, or document the hard-link requirement.
- Test coverage: None.

**`post-commit` hook depends on `xclip`:**
- Files: `.git-hooks/post-commit`
- Why fragile: The hook calls `xclip -selection clipboard` unconditionally. On Wayland-only sessions, headless systems, or non-X11 environments, `xclip` fails and the commit hook exits non-zero, which git treats as an error. This can confuse users into thinking their commit failed.
- Safe modification: Mirror the fallback logic from `scripts/tmux/yank`; detect available clipboard tool before calling it; exit 0 on clipboard failure with a warning to stderr.
- Test coverage: None.

## Missing Critical Features

**No automated tests for shell scripts:**
- Problem: All functional scripts (`ssh.exp`, `mount.sh`, `sync.sh`, status bar scripts, `yank`) have zero automated tests. The `scripts/tmux/tests/` directory contains only manual stress-test helpers, not assertions.
- Blocks: Cannot validate changes to scripts without manual verification on specific hardware/environment.

**No linting or static analysis:**
- Problem: No shellcheck integration in CI or Makefile targets. Shell scripts contain issues detectable by shellcheck (e.g., unquoted variables, glob in regex position in `ssh.exp`).
- Files: All `*.sh` and `*.exp` files under `scripts/`
- Blocks: Regressions can be introduced silently without a linting gate.

## Dependencies at Risk

**`expect` for SSH automation:**
- Risk: `expect` is an old, brittle automation tool. Cooper ICE cluster changes to authentication (e.g., DUO 2FA, banner updates) would silently break the SSH and mount workflows.
- Impact: `ssh` wrapper function and SSHFS mount both stop working entirely.
- Migration plan: SSH key-based auth eliminates the `expect` dependency completely.

**CUDA 13.0 pinned PyTorch index:**
- Risk: `Makefile` pins PyTorch to `https://download.pytorch.org/whl/cu130`. If the system CUDA version changes or cu130 wheels are removed, `install-python` fails.
- Files: `Makefile` (line 131)
- Impact: Python environment cannot be rebuilt.
- Migration plan: Make the CUDA version a variable (e.g., `PYTORCH_INDEX ?= ...`) and document how to override it.

---

*Concerns audit: 2026-03-08*
