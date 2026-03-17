#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

PROFILE=""
NO_SECRETS=false

usage() {
    echo "Usage: $(basename "$0") [--profile arch|ubuntu] [--no-secrets]"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift 2 ;;
        --no-secrets) NO_SECRETS=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Step 1: Auto-detect profile if not specified
detect_profile() {
    if command -v pacman &>/dev/null; then
        echo "arch"
    else
        echo "ubuntu"
    fi
}

if [[ -z "$PROFILE" ]]; then
    if [[ -f "$HOME/.dotfiles-profile" ]]; then
        PROFILE=$(cat "$HOME/.dotfiles-profile")
        echo "Using saved profile: $PROFILE"
    else
        PROFILE=$(detect_profile)
        echo "Auto-detected profile: $PROFILE"
    fi
fi

# Validate profile
if [[ ! -f "$REPO_ROOT/profiles/${PROFILE}.conf" ]]; then
    echo "ERROR: Unknown profile '$PROFILE'. Available: arch, ubuntu" >&2
    exit 1
fi

# Save profile
echo "$PROFILE" > "$HOME/.dotfiles-profile"
echo "Profile saved to ~/.dotfiles-profile"

# Step 2: Ensure stow is installed
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    if command -v pacman &>/dev/null; then
        sudo pacman -S --needed --noconfirm stow
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y stow
    else
        echo "ERROR: Cannot install stow — unknown package manager" >&2
        exit 1
    fi
fi

# Step 3: Install packages
echo ""
echo "=== Installing packages ==="
"$REPO_ROOT/scripts/install-packages.sh" "$PROFILE"

# Step 4: Apply profile (stow configs + services)
echo ""
echo "=== Applying profile ==="
"$REPO_ROOT/scripts/apply-profile.sh" "$PROFILE"

# Step 5: Interactive .env setup
if ! $NO_SECRETS; then
    echo ""
    echo "=== Environment setup ==="
    make -C "$REPO_ROOT" setup-env
fi

# Step 6: Summary
echo ""
echo "=== Bootstrap complete ==="
echo "Profile: $PROFILE"
echo "Dotfiles profile saved to: ~/.dotfiles-profile"
echo ""
echo "To re-apply configs:  make setup"
echo "To install packages:  make install"
