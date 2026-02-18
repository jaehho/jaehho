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

if [ -f "$JAEHHO_ROOT/scripts/md2typ.bash" ]; then
    source "$JAEHHO_ROOT/scripts/md2typ.bash" && echo "source md2typ"
fi

nh() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    # Clean the command string for the filename
    local cmd_clean=$(echo "$*" | tr ' /' '__' | tr -dc '[:alnum:]_')
    local log_file="nohup_${timestamp}_${cmd_clean}.log"

    # Start the command in the background
    nohup "$@" > "$log_file" 2>&1 &
    
    local pid=$!
    echo "PID: $pid"
    echo "Watching log (Ctrl+C to stop watching, process will keep running)..."
    echo ""

    # 'tail -f' the log file. 
    # The --pid flag tells tail to exit automatically if the process finishes.
    tail -f "$log_file" --pid=$pid
}

alias nhls="lsof | grep "nohup_.*\.log""

export COMPOSE_BAKE=true
echo "docker COMPOSE_BAKE=true"
