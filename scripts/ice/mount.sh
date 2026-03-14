#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ENV_FILE:-$REPO_ROOT/.env}"

# Load environment variables from .env file if it exists
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

if [ -z "${ICE_USER:-}" ]; then
    echo "ERROR: ICE_USER is not set (check your .env or service EnvironmentFile)" >&2
    exit 1
fi

if [ -z "${ICE_PASSWORD:-}" ]; then
    echo "ERROR: ICE_PASSWORD is not set (check your .env or service EnvironmentFile)" >&2
    exit 1
fi

: "${MOUNTPOINT:=/mnt/ice}"
: "${LOCAL_USER:=${SUDO_USER:-${USER:-jaeho}}}"

if ! LOCAL_UID=$(id -u "$LOCAL_USER" 2>/dev/null); then
    echo "ERROR: Local user '$LOCAL_USER' not found" >&2
    exit 1
fi

if ! LOCAL_GID=$(id -g "$LOCAL_USER" 2>/dev/null); then
    echo "ERROR: Could not get primary group for '$LOCAL_USER'" >&2
    exit 1
fi

mkdir -p "$MOUNTPOINT"

OBSCURED_PASS=$(rclone obscure "$ICE_PASSWORD")

ICE_HOME="/afs/ee.cooper.edu/user/${ICE_USER:0:1}/${ICE_USER}"

exec rclone mount "ice:${ICE_HOME}" "$MOUNTPOINT" \
    --sftp-pass "$OBSCURED_PASS" \
    --allow-other \
    --default-permissions \
    --uid "$LOCAL_UID" \
    --gid "$LOCAL_GID" \
    --umask 0022 \
    --vfs-cache-mode minimal
