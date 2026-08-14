#!/bin/bash

set -Eeuo pipefail

SSH_PORT="${SSH_PORT:-2222}"
HERMES_HOME="/home/hermes"
SSH_DIR="${HERMES_HOME}/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"

# Pastikan direktori user dan SSH benar
install -d \
    -o hermes \
    -g hermes \
    -m 0755 \
    "$HERMES_HOME"

install -d \
    -o hermes \
    -g hermes \
    -m 0700 \
    "$SSH_DIR"

# Public key dari environment variable
if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
    printf '%s\n' "$SSH_PUBLIC_KEY" > "$AUTHORIZED_KEYS"
fi

# Mounted key menjadi sumber utama jika tersedia
if [ -f /opt/data/ssh/authorized_keys ]; then
    install \
        -o hermes \
        -g hermes \
        -m 0600 \
        /opt/data/ssh/authorized_keys \
        "$AUTHORIZED_KEYS"
fi

if [ ! -s "$AUTHORIZED_KEYS" ]; then
    echo "ERROR: $AUTHORIZED_KEYS tidak ada atau kosong" >&2
    exit 1
fi

chown hermes:hermes "$SSH_DIR" "$AUTHORIZED_KEYS"
chmod 0700 "$SSH_DIR"
chmod 0600 "$AUTHORIZED_KEYS"

# Buat tmux sebagai user hermes
if ! sudo -u hermes -H tmux has-session -t hermes 2>/dev/null; then
    sudo -u hermes -H tmux new-session \
        -d \
        -s hermes \
        -c /opt/data
fi

# Validasi konfigurasi SSH
/usr/sbin/sshd -t -o "Port=${SSH_PORT}"

trap cleanup SIGTERM SIGINT EXIT

echo "Starting SSH server on port ${SSH_PORT}..."
echo "Authorized keys: ${AUTHORIZED_KEYS}"

exec /usr/sbin/sshd \
    -D \
    -e \
    -o "Port=${SSH_PORT}"
