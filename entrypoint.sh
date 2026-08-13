#!/bin/bash

set -e

# Pastikan folder SSH tersedia
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Ambil public key dari environment
if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
    printf '%s\n' "$SSH_PUBLIC_KEY" > "$HOME/.ssh/authorized_keys"
fi

# Atau gunakan public key dari volume
if [ -f /opt/data/ssh/authorized_keys ]; then
    cp /opt/data/ssh/authorized_keys "$HOME/.ssh/authorized_keys"
fi

if [ -f "$HOME/.ssh/authorized_keys" ]; then
    chmod 600 "$HOME/.ssh/authorized_keys"
fi

# Buat tmux hanya jika belum ada
if ! tmux has-session -t hermes 2>/dev/null; then
    tmux new-session -d -s hermes -c /opt/data
fi

# Jalankan Hermes gateway
hermes gateway run &

# SSHD menjadi proses utama container
exec sudo /usr/sbin/sshd -D -e
