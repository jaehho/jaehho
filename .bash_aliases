alias m='matlab -nodesktop'
mat() {
    if [ -z "$1" ]; then
        echo "Usage: mat script_name.m"
        return 1
    fi

    full_arg="$1"
    script_name="${full_arg%.m}"

    if [ ! -f "$full_arg" ] && [ ! -f "${script_name}.m" ]; then
        echo "'$full_arg' not found."
        return 1
    fi

    timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p logs
    log_file="logs/${script_name}_${timestamp}.log"

    nohup matlab -nodesktop -r "try, ${script_name}; catch ME, disp(getReport(ME)), end; exit;" > "$log_file" 2>&1 &

    echo "Started '$full_arg' (log: $log_file)"
}

alias ssh-display='export DISPLAY=localhost:10.0 && echo "DISPLAY set to $DISPLAY"'