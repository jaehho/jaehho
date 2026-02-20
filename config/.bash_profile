# Repo root for these helpers
JAEHHO_ROOT="${JAEHHO_ROOT:-$HOME/jaehho}"

# ssh function for ice servers
ssh() {
    # No host given → just call real ssh
    if [ $# -eq 0 ]; then
        command ssh
        return
    fi

    local host="$1"
    shift

    # Match ice00..ice09, ice10, ice11 (short form)
    case "$host" in
        ice0[0-9]|ice1[01])
            # Load secrets for Expect script
            if [ -f "$JAEHHO_ROOT/.env" ]; then
                set -a
                source "$JAEHHO_ROOT/.env"
                set +a
            else
                echo "ERROR: $JAEHHO_ROOT/.env not found; ICE_PASSWORD unavailable."
                return 1
            fi

            local target="jaeho.cho@${host}.ee.cooper.edu"
            "$JAEHHO_ROOT/scripts/ice/ssh-ice.exp" "$target" "$@"
            return
            ;;

        jaeho.cho@ice0[0-9].ee.cooper.edu|jaeho.cho@ice1[01].ee.cooper.edu)
            # Load secrets for Expect script
            if [ -f "$JAEHHO_ROOT/.env" ]; then
                set -a
                source "$JAEHHO_ROOT/.env"
                set +a
            else
                echo "ERROR: $JAEHHO_ROOT/.env not found; ICE_PASSWORD unavailable."
                return 1
            fi

            "$JAEHHO_ROOT/scripts/ice/ssh-ice.exp" "$host" "$@"
            return
            ;;

        *)
            # Any other host → normal ssh
            command ssh "$host" "$@"
            return
            ;;
    esac
}

alias ssh-mililab='ssh -J jaeho.cho@dev.ee.cooper.edu:31415 jaeho@10.5.1.124 -X -Y'

nh() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: nh <command> [args...]"
        return 1
    fi

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local cmd_clean=$(echo "$*" | tr ' /' '__' | tr -dc '[:alnum:]_' | cut -c1-30)
    local log_file="nohup_${timestamp}_${cmd_clean}.log"

    nohup "$@" > "$log_file" 2>&1 &
    local pid=$!

    echo "PID:     $pid"
    echo "Log:     $log_file"
    echo "(Ctrl+C stops watching — process keeps running)"
    echo ""

    echo "$pid $log_file $*" >> ~/.nh_jobs

    # portable tail -f that exits when process finishes
    tail -f "$log_file" &
    local tail_pid=$!
    wait $pid 2>/dev/null
    kill $tail_pid 2>/dev/null
}

nh_list() {
    local tmp=$(mktemp)
    while read -r pid log cmd; do
        if kill -0 "$pid" 2>/dev/null; then
            echo "RUNNING  pid=$pid log=$log cmd=$cmd"
            echo "$pid $log $cmd" >> "$tmp"
        else
            echo "DONE     pid=$pid log=$log cmd=$cmd"
        fi
    done < ~/.nh_jobs
    mv "$tmp" ~/.nh_jobs
}

alias nhls="lsof | grep "nohup_.*\.log""

export COMPOSE_BAKE=true
echo "docker COMPOSE_BAKE=true"

[ -z "$TMUX" ] && tmux attach 2>/dev/null || tmux new -s main


start_tmux() {
    # Check if TMUX is already running
    [ "$TMUX" == "" ] || return

    # Get a list of available sessions
    sessions=($(tmux list-sessions -F "#S" 2>/dev/null))

    # If there are available sessions, display them and ask to choose
    if [ ${#sessions[@]} -gt 0 ]; then
        PS3="Please choose a session: "
        echo "Available sessions"
        echo "------------------"
        select session in "${sessions[@]}"
        do
            tmux attach-session -t "$session"
            return
        done
    fi

    # If no sessions, ask to create a new one
    read -rp "Enter new session name (press Enter to use default): " SESSION_NAME
    if [ -z "$SESSION_NAME" ]; then
        tmux
    else
        tmux new -s "$SESSION_NAME"
        # If you want to stay in the new session after creating it, remove the "exit" command.
        # exit
    fi
}
