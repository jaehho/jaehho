#!/bin/bash
set -e

MOUNTPOINT="/mnt/ice"
REMOTE_PATH="/afs/ee.cooper.edu/user/j/jaeho.cho/"
REMOTE_USER="jaeho.cho"

# Expect password from environment (set by EnvironmentFile)
if [ -z "$ICE_PASSWORD" ]; then
    echo "ERROR: ICE_PASSWORD is not set (check /home/jaeho/jaehho/.env)" >&2
    exit 1
fi

PASSWORD="$ICE_PASSWORD"

mkdir -p "$MOUNTPOINT"

for i in $(seq 0 11); do
    HOST=$(printf "ice%02d.ee.cooper.edu" "$i")
    echo "Trying $HOST..." >&2

    if echo "$PASSWORD" | /usr/bin/sshfs \
        -o password_stdin,allow_other,default_permissions,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
        -o ssh_command="/usr/bin/ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/root/.ssh/known_hosts" \
        "${REMOTE_USER}@${HOST}:${REMOTE_PATH}" \
        "$MOUNTPOINT"; then
        echo "Mounted from $HOST" >&2
        exit 0
    fi
done

echo "Failed to mount from any ice00–ice11 host" >&2
exit 1
