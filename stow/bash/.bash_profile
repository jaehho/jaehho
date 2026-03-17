# Bash completions
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
fi

# Repo root for these helpers
JAEHHO_ROOT="${JAEHHO_ROOT:-$HOME/jaehho}"

# Default editor
export EDITOR="nvim"
export VISUAL="nvim"

# User-local npm binaries (neovim, tree-sitter-cli, etc.)
export PATH="$HOME/.npm-global/bin:$PATH"

# ── internal helper ────────────────────────────────────────────────────────────
_ice_load_env() {
    if [ -f "$JAEHHO_ROOT/.env" ]; then
        set -a
        # shellcheck source=/dev/null
        source "$JAEHHO_ROOT/.env"
        set +a
    else
        echo "ERROR: $JAEHHO_ROOT/.env not found; ICE_PASSWORD unavailable." >&2
        return 1
    fi
}

# ── ssh wrapper ────────────────────────────────────────────────────────────────
ssh() {
    [ $# -eq 0 ] && { command ssh; return; }

    local host="$1"
    shift

    case "$host" in
        ice0[0-9]|ice1[01])
            _ice_load_env || return 1
            "$JAEHHO_ROOT/scripts/ice/ssh.exp" \
                "jaeho.cho@${host}.ee.cooper.edu" "$@"
            ;;
        jaeho.cho@ice0[0-9].ee.cooper.edu|jaeho.cho@ice1[01].ee.cooper.edu)
            _ice_load_env || return 1
            "$JAEHHO_ROOT/scripts/ice/ssh.exp" "$host" "$@"
            ;;
        *)
            command ssh "$host" "$@"
            ;;
    esac
}

# ── nohup helpers ──────────────────────────────────────────────────────────────
nh() {
    if [ $# -eq 0 ]; then
        echo "Usage: nh <command> [args...]"
        return 1
    fi

    local timestamp cmd_clean log_file pid tail_pid
    timestamp=$(date +%Y%m%d_%H%M%S)
    cmd_clean=$(echo "$*" | tr ' /' '__' | tr -dc '[:alnum:]_' | cut -c1-30)
    log_file="nohup_${timestamp}_${cmd_clean}.log"

    nohup "$@" > "$log_file" 2>&1 &
    pid=$!

    echo "PID:  $pid"
    echo "Log:  $log_file"
    echo "(Ctrl+C stops watching — process keeps running)"
    echo

    echo "$pid $log_file $*" >> ~/.nh_jobs

    tail -f "$log_file" &
    tail_pid=$!
    wait "$pid" 2>/dev/null
    kill "$tail_pid" 2>/dev/null
}

nh_list() {
    [ -f ~/.nh_jobs ] || { echo "No jobs recorded."; return; }

    local tmp
    tmp=$(mktemp)
    while read -r pid log cmd; do
        if kill -0 "$pid" 2>/dev/null; then
            printf "RUNNING  pid=%-7s log=%s cmd=%s\n" "$pid" "$log" "$cmd"
            echo "$pid $log $cmd" >> "$tmp"
        else
            printf "DONE     pid=%-7s log=%s cmd=%s\n" "$pid" "$log" "$cmd"
        fi
    done < ~/.nh_jobs
    mv "$tmp" ~/.nh_jobs
}

# list open nohup log files (quote carefully to avoid glob/word-split issues)
alias nhls='lsof | grep "nohup_.*\.log"'

# ── Hyprland auto-start on TTY1 ────────────────────────────────────────────────
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi

# ── tmux auto-attach ───────────────────────────────────────────────────────────
[[ $- == *i* ]] && [[ -t 1 ]] && [[ -z "$TMUX" ]] && [[ -z "$VSCODE_INJECTION" ]] && \
  { tmux attach 2>/dev/null || tmux new -s main; }

[[ -z "$VSCODE_INJECTION" ]] && eval "$(direnv hook bash)"

show_virtual_env() {
  if [[ -n "$VIRTUAL_ENV" && -n "$DIRENV_DIR" ]]; then
    echo "($(basename $(dirname $VIRTUAL_ENV))) "
  fi
}
PS1='$(show_virtual_env)'"$PS1"

alias c='claude --dangerously-skip-permissions'