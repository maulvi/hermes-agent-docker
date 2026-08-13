#!/bin/bash

set -e

SSH_PORT="${SSH_PORT:-2222}"

# Validasi port harus angka 1-65535
case "$SSH_PORT" in
    ''|*[!0-9]*)
        echo "Invalid SSH_PORT: $SSH_PORT" >&2
        exit 1
        ;;
esac

if [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
    echo "SSH_PORT must be between 1 and 65535" >&2
    exit 1
fi

# Inject SSH public key if provided
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
    printf '%s\n' "$SSH_PUBLIC_KEY" > "$HOME/.ssh/authorized_keys"
fi

# Use mounted authorized_keys if available
if [ -f /opt/data/ssh/authorized_keys ]; then
    cp /opt/data/ssh/authorized_keys "$HOME/.ssh/authorized_keys"
fi

if [ -f "$HOME/.ssh/authorized_keys" ]; then
    chmod 600 "$HOME/.ssh/authorized_keys"
fi

# Start tmux only if it does not already exist
if ! tmux has-session -t hermes 2>/dev/null; then
    tmux new-session -d -s hermes -c /opt/data
fi

# Start Hermes gateway
hermes gateway run &

GATEWAY_PID=$!

# Validate sshd configuration with the selected port
sudo /usr/sbin/sshd -t -o "Port=$SSH_PORT"

echo "Starting SSH server on port $SSH_PORT..."

cleanup() {
    kill "$GATEWAY_PID" 2>/dev/null || true
    wait "$GATEWAY_PID" 2>/dev/null || true
}

trap cleanup SIGTERM SIGINT EXIT

# SSHD remains the main container process
exec sudo /usr/sbin/sshd \
    -D \
    -e \
    -o "Port=$SSH_PORT"
