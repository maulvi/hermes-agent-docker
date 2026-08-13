#!/bin/bash

set -Eeuo pipefail

SSH_PORT="${SSH_PORT:-2222}"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Public key dari environment
if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
    printf '%s\n' "$SSH_PUBLIC_KEY" > "$HOME/.ssh/authorized_keys"
fi

# Public key dari mounted file
if [ -f /opt/data/ssh/authorized_keys ]; then
    cp /opt/data/ssh/authorized_keys "$HOME/.ssh/authorized_keys"
fi

if [ ! -s "$HOME/.ssh/authorized_keys" ]; then
    echo "ERROR: authorized_keys tidak ditemukan atau kosong" >&2
    exit 1
fi

chmod 600 "$HOME/.ssh/authorized_keys"
chown "$(id -u):$(id -g)" "$HOME/.ssh/authorized_keys"

if ! tmux has-session -t hermes 2>/dev/null; then
    tmux new-session -d -s hermes -c /opt/data
fi

hermes gateway run &
GATEWAY_PID=$!

sudo /usr/sbin/sshd -t -o "Port=$SSH_PORT"

trap 'kill "$GATEWAY_PID" 2>/dev/null || true' EXIT SIGTERM SIGINT

exec sudo /usr/sbin/sshd \
    -D \
    -e \
    -o "Port=$SSH_PORT"
