#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROFILES_DIR="$REPO_ROOT/profiles"
STOW_DIR="$REPO_ROOT/stow"
SYSTEMD_DIR="$REPO_ROOT/systemd"

PROFILE="${1:-}"
[[ -z "$PROFILE" ]] && { echo "Usage: $(basename "$0") <profile>"; exit 1; }

# Resolve profile inheritance (same logic as apply-profile.sh)
resolve_profile() {
    local profile="$1"
    local conf="$PROFILES_DIR/${profile}.conf"

    if [[ ! -f "$conf" ]]; then
        echo "ERROR: Profile config not found: $conf" >&2
        exit 1
    fi

    local inherit stow_pkgs services system_configs sleep_hooks
    inherit=$(grep '^INHERIT=' "$conf" | cut -d= -f2 | tr -d '"' || true)
    stow_pkgs=$(grep '^STOW_PACKAGES=' "$conf" | cut -d= -f2 | tr -d '"' || true)
    services=$(grep '^SERVICES=' "$conf" | cut -d= -f2 | tr -d '"' || true)
    system_configs=$(grep '^SYSTEM_CONFIGS=' "$conf" | cut -d= -f2 | tr -d '"' || true)
    sleep_hooks=$(grep '^SLEEP_HOOKS=' "$conf" | cut -d= -f2 | tr -d '"' || true)

    local parent_stow="" parent_services="" parent_system_configs="" parent_sleep_hooks=""
    if [[ -n "$inherit" ]]; then
        local parent_output
        parent_output="$(resolve_profile "$inherit")"
        parent_stow="${parent_output%%|*}"
        local rest="${parent_output#*|}"
        parent_services="${rest%%|*}"
        rest="${rest#*|}"
        parent_system_configs="${rest%%|*}"
        parent_sleep_hooks="${rest#*|}"
    fi

    echo "${parent_stow} ${stow_pkgs}|${parent_services} ${services}|${parent_system_configs} ${system_configs}|${parent_sleep_hooks} ${sleep_hooks}"
}

_resolved="$(resolve_profile "$PROFILE")"
ALL_STOW="${_resolved%%|*}"
_rest="${_resolved#*|}"
ALL_SERVICES="${_rest%%|*}"
_rest="${_rest#*|}"
ALL_SYSTEM_CONFIGS="${_rest%%|*}"
ALL_SLEEP_HOOKS="${_rest#*|}"

# Deduplicate and trim
ALL_STOW=$(echo "$ALL_STOW" | tr ' ' '\n' | { grep -v '^$' || true; } | awk '!seen[$0]++' | tr '\n' ' ')
ALL_SERVICES=$(echo "$ALL_SERVICES" | tr ' ' '\n' | { grep -v '^$' || true; } | awk '!seen[$0]++' | tr '\n' ' ')
ALL_SYSTEM_CONFIGS=$(echo "$ALL_SYSTEM_CONFIGS" | tr ' ' '\n' | { grep -v '^$' || true; } | awk '!seen[$0]++' | tr '\n' ' ')
ALL_SLEEP_HOOKS=$(echo "$ALL_SLEEP_HOOKS" | tr ' ' '\n' | { grep -v '^$' || true; } | awk '!seen[$0]++' | tr '\n' ' ')

echo "Cleaning profile: $PROFILE"

# 1. Unstow all profile packages
for pkg in $ALL_STOW; do
    if [[ -d "$STOW_DIR/$pkg" ]]; then
        echo "Unstowing: $pkg"
        stow -d "$STOW_DIR" -t "$HOME" -D "$pkg" 2>/dev/null || true
    fi
done

# 2. Remove bash_profile source line from ~/.bashrc
BASHRC="$HOME/.bashrc"
if [[ -f "$BASHRC" ]]; then
    if grep -q '# DOTFILES_BASH_PROFILE' "$BASHRC"; then
        sed -i '/# DOTFILES_BASH_PROFILE/d' "$BASHRC"
        echo "Removed bash_profile source line from ~/.bashrc"
    fi
fi

# 3. Disable and unlink services
GENERATED_DIR="$SYSTEMD_DIR/.generated"
for svc in $ALL_SERVICES; do
    system_service="/etc/systemd/system/${svc}.service"

    if systemctl is-enabled "${svc}.service" &>/dev/null; then
        echo "Disabling service: $svc"
        sudo systemctl disable "${svc}.service" 2>/dev/null || true
    fi

    if [[ -L "$system_service" ]]; then
        echo "Removing service symlink: $system_service"
        sudo rm "$system_service"
    fi

    # Remove config symlinks for services
    local_conf_dir="$REPO_ROOT/$svc"
    system_conf_dir="/etc/$svc"
    if [[ -d "$local_conf_dir" ]] && [[ -d "$system_conf_dir" ]]; then
        for conf in "$local_conf_dir"/*; do
            local target="$system_conf_dir/$(basename "$conf")"
            if [[ -L "$target" ]]; then
                echo "  Removing config symlink: $target"
                sudo rm "$target"
            fi
        done
    fi
done
if [[ -n "$ALL_SERVICES" ]]; then
    sudo systemctl daemon-reload
fi

# 4. Remove system config symlinks
for cfg in $ALL_SYSTEM_CONFIGS; do
    system_conf_dir="/etc/$cfg"
    local_conf_dir="$REPO_ROOT/$cfg"
    if [[ -d "$local_conf_dir" ]] && [[ -d "$system_conf_dir" ]]; then
        for conf in "$local_conf_dir"/*; do
            local target="$system_conf_dir/$(basename "$conf")"
            if [[ -L "$target" ]]; then
                echo "Removing system config symlink: $target"
                sudo rm "$target"
            fi
        done
    fi
done

# 5. Remove sleep hooks
for hook in $ALL_SLEEP_HOOKS; do
    system_hook="/usr/lib/systemd/system-sleep/$hook"
    if [[ -f "$system_hook" ]]; then
        echo "Removing sleep hook: $hook"
        sudo rm "$system_hook"
    fi
done

# 6. Clean generated service files
if [[ -d "$GENERATED_DIR" ]]; then
    echo "Removing generated service files"
    rm -rf "$GENERATED_DIR"
fi

echo "Profile cleaned successfully."
