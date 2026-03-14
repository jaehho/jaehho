#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROFILES_DIR="$REPO_ROOT/profiles"
STOW_DIR="$REPO_ROOT/stow"
SYSTEMD_DIR="$REPO_ROOT/systemd"

PROFILE="${1:-}"
[[ -z "$PROFILE" ]] && { echo "Usage: $(basename "$0") <profile>"; exit 1; }

# Resolve profile inheritance: collect STOW_PACKAGES and SERVICES
resolve_profile() {
    local profile="$1"
    local conf="$PROFILES_DIR/${profile}.conf"

    if [[ ! -f "$conf" ]]; then
        echo "ERROR: Profile config not found: $conf" >&2
        exit 1
    fi

    local inherit stow_pkgs services
    inherit=$(grep '^INHERIT=' "$conf" | cut -d= -f2 | tr -d '"' || true)
    stow_pkgs=$(grep '^STOW_PACKAGES=' "$conf" | cut -d= -f2 | tr -d '"' || true)
    services=$(grep '^SERVICES=' "$conf" | cut -d= -f2 | tr -d '"' || true)

    # Recurse into parent
    local parent_stow="" parent_services=""
    if [[ -n "$inherit" ]]; then
        local parent_output
        parent_output="$(resolve_profile "$inherit")"
        parent_stow="${parent_output%%|*}"
        parent_services="${parent_output#*|}"
    fi

    # Merge (parent first, then child)
    echo "${parent_stow} ${stow_pkgs}|${parent_services} ${services}"
}

_resolved="$(resolve_profile "$PROFILE")"
ALL_STOW="${_resolved%%|*}"
ALL_SERVICES="${_resolved#*|}"

# Deduplicate and trim
ALL_STOW=$(echo "$ALL_STOW" | tr ' ' '\n' | { grep -v '^$' || true; } | awk '!seen[$0]++' | tr '\n' ' ')
ALL_SERVICES=$(echo "$ALL_SERVICES" | tr ' ' '\n' | { grep -v '^$' || true; } | awk '!seen[$0]++' | tr '\n' ' ')

echo "Profile: $PROFILE"
echo "Stow packages: $ALL_STOW"
echo "Services: $ALL_SERVICES"

# 1. Clean up existing targets that would conflict with stow
#    (old symlinks from pre-stow setup, regular files, etc.)
clean_conflicts() {
    local pkg_dir="$1"
    # Walk both files and directories in the stow package
    while IFS= read -r -d '' src; do
        local rel="${src#"$pkg_dir"/}"
        local target="$HOME/$rel"
        if [[ -L "$target" ]]; then
            # Remove symlink unless it already points into our stow dir
            local link_target
            link_target="$(readlink "$target" 2>/dev/null || true)"
            if [[ "$link_target" != *"/stow/"* ]]; then
                echo "  Removing stale symlink: $target -> $link_target"
                rm "$target"
            fi
        fi
    done < <(find "$pkg_dir" \( -type f -o -type d \) -print0)
}

# 2. Stow packages
for pkg in $ALL_STOW; do
    if [[ -d "$STOW_DIR/$pkg" ]]; then
        echo "Stowing: $pkg"
        clean_conflicts "$STOW_DIR/$pkg"
        stow -d "$STOW_DIR" -t "$HOME" --no-folding --adopt "$pkg"
        # --adopt moves existing files into stow dir; restore repo versions
        git -C "$REPO_ROOT" checkout -- "$STOW_DIR/$pkg/" 2>/dev/null || true
    else
        echo "WARNING: stow package directory not found: $STOW_DIR/$pkg" >&2
    fi
done

# 3. Install TPM if tmux was stowed
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ " $ALL_STOW " == *" tmux "* ]] && [[ ! -d "$TPM_DIR" ]]; then
    echo "Installing TPM (Tmux Plugin Manager)..."
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# 4. Bash source line (always applied regardless of profile)
BASH_PROFILE_SRC="$STOW_DIR/bash/.bash_profile"
BASHRC="$HOME/.bashrc"
if [[ -f "$BASH_PROFILE_SRC" ]]; then
    touch "$BASHRC"
    if ! grep -qxF "source $BASH_PROFILE_SRC" "$BASHRC"; then
        echo "source $BASH_PROFILE_SRC" >> "$BASHRC"
        echo "Added bash_profile source line to ~/.bashrc"
    fi
fi

# 5. Systemd services
for svc in $ALL_SERVICES; do
    local_service="$SYSTEMD_DIR/${svc}.service"
    system_service="/etc/systemd/system/${svc}.service"

    if [[ ! -f "$local_service" ]]; then
        echo "WARNING: service file not found: $local_service" >&2
        continue
    fi

    echo "Setting up service: $svc"
    sudo ln -sf "$local_service" "$system_service"

    # SELinux context if applicable
    if command -v chcon &>/dev/null; then
        sudo chcon -t systemd_unit_file_t "$local_service" 2>/dev/null || true
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable "${svc}.service"
    echo "Service $svc enabled (start with: sudo systemctl start ${svc}.service)"
done

echo "Profile applied successfully."
