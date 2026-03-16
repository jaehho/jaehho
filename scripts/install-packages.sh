#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES_DIR="$REPO_ROOT/packages"
MAPPINGS="$PACKAGES_DIR/mappings.conf"

DRY_RUN=false
PROFILE="${1:-}"

usage() {
    echo "Usage: $(basename "$0") [--dry-run] <profile>"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        -*) echo "Unknown option: $1"; usage ;;
        *) PROFILE="$1"; shift ;;
    esac
done

[[ -z "$PROFILE" ]] && usage

# Detect package manager
detect_pm() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    else
        echo "unknown"
    fi
}

PM=$(detect_pm)

# Load mappings into associative arrays
declare -A APT_MAP PACMAN_MAP
if [[ -f "$MAPPINGS" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        IFS=: read -r canonical apt pacman <<< "$line"
        APT_MAP["$canonical"]="$apt"
        PACMAN_MAP["$canonical"]="$pacman"
    done < "$MAPPINGS"
fi

# Map a package name for the current package manager
map_pkg() {
    local pkg="$1"
    case "$PM" in
        apt)    echo "${APT_MAP[$pkg]:-$pkg}" ;;
        pacman) echo "${PACMAN_MAP[$pkg]:-$pkg}" ;;
        *)      echo "$pkg" ;;
    esac
}

# Read package lists for the profile (common + profile-specific)
read_packages() {
    local profile="$1"
    local pkgs=()
    local aur_pkgs=()
    local npm_pkgs=()

    # Read common packages
    if [[ -f "$PACKAGES_DIR/common.txt" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            pkgs+=("$(map_pkg "$line")")
        done < "$PACKAGES_DIR/common.txt"
    fi

    # Read profile-specific packages
    if [[ -f "$PACKAGES_DIR/${profile}.txt" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            if [[ "$line" == AUR:* ]]; then
                aur_pkgs+=("${line#AUR:}")
            elif [[ "$line" == NPM:* ]]; then
                npm_pkgs+=("${line#NPM:}")
            else
                pkgs+=("$(map_pkg "$line")")
            fi
        done < "$PACKAGES_DIR/${profile}.txt"
    fi

    # Install regular packages
    if [[ ${#pkgs[@]} -gt 0 ]]; then
        case "$PM" in
            apt)
                if $DRY_RUN; then
                    echo "[dry-run] apt-get install ${pkgs[*]}"
                else
                    sudo apt-get update -qq
                    sudo apt-get install -y "${pkgs[@]}"
                fi
                ;;
            pacman)
                if $DRY_RUN; then
                    echo "[dry-run] pacman -S --needed ${pkgs[*]}"
                else
                    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
                fi
                ;;
            *)
                echo "ERROR: Unsupported package manager" >&2
                exit 1
                ;;
        esac
    fi

    # Install npm global packages (skip already-installed)
    if [[ ${#npm_pkgs[@]} -gt 0 ]]; then
        if $DRY_RUN; then
            echo "[dry-run] npm install -g ${npm_pkgs[*]}"
        else
            if ! command -v npm &>/dev/null; then
                echo "WARNING: npm not found, skipping npm packages: ${npm_pkgs[*]}" >&2
            else
                local missing_npm=()
                for pkg in "${npm_pkgs[@]}"; do
                    if ! npm ls -g --prefix "$HOME/.npm-global" "$pkg" &>/dev/null; then
                        missing_npm+=("$pkg")
                    fi
                done
                if [[ ${#missing_npm[@]} -gt 0 ]]; then
                    npm install -g --prefix "$HOME/.npm-global" "${missing_npm[@]}"
                else
                    echo "All npm packages already installed, skipping."
                fi
            fi
        fi
    fi

    # Install AUR packages (Arch only)
    if [[ ${#aur_pkgs[@]} -gt 0 && "$PM" == "pacman" ]]; then
        if $DRY_RUN; then
            echo "[dry-run] paru -S --needed ${aur_pkgs[*]}"
        else
            if ! command -v paru &>/dev/null; then
                echo "WARNING: paru not found, skipping AUR packages: ${aur_pkgs[*]}" >&2
            else
                paru -S --needed --noconfirm "${aur_pkgs[@]}"
            fi
        fi
    fi
}

echo "Installing packages for profile: $PROFILE (package manager: $PM)"
read_packages "$PROFILE"

# On apt-based systems, build neovim from source (apt version is too old)
if [[ "$PM" == "apt" ]]; then
    if $DRY_RUN; then
        echo "[dry-run] Build neovim from source via scripts/update-nvim.sh"
    else
        # Skip build if installed nvim is already the latest stable
        NVIM_INSTALLED=""
        if command -v nvim &>/dev/null; then
            NVIM_INSTALLED="v$(nvim --version | head -1 | grep -oP '\d+\.\d+\.\d+')"
        fi
        NVIM_LATEST="$(git ls-remote --tags --sort=-v:refname https://github.com/neovim/neovim.git 'refs/tags/v[0-9]*' | head -1 | sed 's|.*refs/tags/||; s|\^{}||')"
        if [[ "$NVIM_INSTALLED" == "$NVIM_LATEST" ]]; then
            echo "Neovim $NVIM_INSTALLED is already the latest stable, skipping build."
        else
            echo "Building neovim from source (installed: ${NVIM_INSTALLED:-none}, latest: $NVIM_LATEST)..."
            "$REPO_ROOT/scripts/update-nvim.sh"
        fi
    fi
fi

echo "Package installation complete."
