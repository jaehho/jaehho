# Fish shell configuration — Arch desktop interactive shell

# Suppress greeting
set -g fish_greeting

# Environment
set -gx EDITOR nvim
set -gx VISUAL nvim

# Path additions
fish_add_path ~/.local/bin
fish_add_path ~/.npm-global/bin

# Aliases
alias c 'claude --dangerously-skip-permissions --model opus --effort max'
alias ls 'eza --icons'
alias la 'eza --icons -la'
alias lt 'eza --icons --tree --level=2'
alias cat 'bat --style=plain'
alias lg 'lazygit'
alias vim 'nvim'

# Abbreviations (expand on type, better than aliases for complex commands)
abbr -a gs git status
abbr -a gd git diff
abbr -a gc git commit
abbr -a gp git push
abbr -a gl git log --oneline --graph --decorate -20

# nohup helper
function nh --description 'Run command in background, detached from terminal'
    nohup $argv &>/dev/null &
    disown
    echo "Started: $argv (PID: $last_pid)"
end

# ICE cluster SSH wrapper
function ssh --wraps ssh --description 'SSH with ICE cluster auto-handling'
    set -l host $argv[-1]
    if string match -qr '^ice0[0-9]$|^ice1[01]$' $host
        set -l ice_user (grep '^ICE_USER=' ~/.dotfiles/.env 2>/dev/null | cut -d= -f2)
        if test -n "$ice_user"
            command ssh "$ice_user@$host.cooper.edu" $argv[1..-2]
        else
            command ssh $argv
        end
    else
        command ssh $argv
    end
end

# direnv hook
if command -q direnv
    direnv hook fish | source
end

# fzf key bindings
if command -q fzf
    fzf --fish | source
end

# Starship prompt
if command -q starship
    starship init fish | source
end
