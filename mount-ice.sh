#!/bin/bash
set -euo pipefail

MOUNTPOINT="/mnt/ice"
REMOTE_PATH="/afs/ee.cooper.edu/user/j/jaeho.cho/"
REMOTE_USER="jaeho.cho" # TODO: Add this to .env

# Local user that should own files under /mnt/ice
LOCAL_USER="jaeho"

# Expect password from environment (set by EnvironmentFile or shell)
if [ -z "${ICE_PASSWORD:-}" ]; then
    echo "ERROR: ICE_PASSWORD is not set (check your .env or service EnvironmentFile)" >&2
    exit 1
fi

PASSWORD="$ICE_PASSWORD"

# Resolve UID/GID for the local user who should "own" the mount
if ! LOCAL_UID=$(id -u "$LOCAL_USER" 2>/dev/null); then
    echo "ERROR: Local user '$LOCAL_USER' not found" >&2
    exit 1
fi

if ! LOCAL_GID=$(id -g "$LOCAL_USER" 2>/dev/null); then
    echo "ERROR: Could not get primary group for '$LOCAL_USER'" >&2
    exit 1
fi

# Ensure mountpoint exists
mkdir -p "$MOUNTPOINT"

for i in $(seq 0 11); do
    HOST=$(printf "ice%02d.ee.cooper.edu" "$i")
    echo "Trying $HOST..." >&2

    if echo "$PASSWORD" | /usr/bin/sshfs \
        -o password_stdin \
        -o allow_other,default_permissions \
        -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
        -o uid="$LOCAL_UID",gid="$LOCAL_GID",umask=0022 \
        -o ssh_command="/usr/bin/ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/root/.ssh/known_hosts" \
        "${REMOTE_USER}@${HOST}:${REMOTE_PATH}" \
        "$MOUNTPOINT"; then
        echo "Mounted from $HOST (presented as uid=$LOCAL_UID,gid=$LOCAL_GID)" >&2
        exit 0
    fi
done

echo "Failed to mount from any ice00–ice11 host" >&2
exit 1
