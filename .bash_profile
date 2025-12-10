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
            if [ -f "$HOME/jaehho/.env" ]; then
                set -a
                source "$HOME/jaehho/.env"
                set +a
            else
                echo "ERROR: $HOME/jaehho/.env not found; ICE_PASSWORD unavailable."
                return 1
            fi

            local target="jaeho.cho@${host}.ee.cooper.edu"
            ~/jaehho/ssh-ice.exp "$target" "$@"
            return
            ;;

        jaeho.cho@ice0[0-9].ee.cooper.edu|jaeho.cho@ice1[01].ee.cooper.edu)
            # Load secrets for Expect script
            if [ -f "$HOME/.env" ]; then
                set -a
                source "$HOME/.env"
                set +a
            else
                echo "ERROR: $HOME/.env not found; ICE_PASSWORD unavailable."
                return 1
            fi

            ~/jaehho/ssh-ice.exp "$host" "$@"
            return
            ;;

        *)
            # Any other host → normal ssh
            command ssh "$host" "$@"
            return
            ;;
    esac
}
