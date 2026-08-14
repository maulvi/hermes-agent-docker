#!/usr/bin/env bash

set -Eeuo pipefail

SSH_PORT="${SSH_PORT:-22}"
HERMES_USER="${HERMES_USER:-hermes}"
HERMES_HOME="${HOME:-/opt/data}"
SSH_DIR="${HERMES_HOME}/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"
MOUNTED_AUTHORIZED_KEYS="/opt/data/ssh/authorized_keys"

log() {
    printf '[entrypoint] %s\n' "$*" >&2
}

# Pastikan lokasi utama Hermes benar
if ! getent passwd "$HERMES_USER" >/dev/null 2>&1; then
    log "ERROR: user ${HERMES_USER} tidak ditemukan"
    exit 1
fi

# Pastikan home user sesuai dengan /opt/data
HERMES_HOME="$(getent passwd "$HERMES_USER" | cut -d: -f6)"

if [ "$HERMES_HOME" != "/opt/data" ]; then
    log "WARNING: home user ${HERMES_USER} adalah ${HERMES_HOME}, bukan /opt/data"
    HERMES_HOME="/opt/data"
    SSH_DIR="${HERMES_HOME}/.ssh"
    AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"
fi

# Pastikan direktori data dan SSH tersedia
install -d \
    -o "$HERMES_USER" \
    -g "$HERMES_USER" \
    -m 0755 \
    "$HERMES_HOME"

install -d \
    -o "$HERMES_USER" \
    -g "$HERMES_USER" \
    -m 0700 \
    "$SSH_DIR"

# Public key dari environment variable
if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
    printf '%s\n' "$SSH_PUBLIC_KEY" > "$AUTHORIZED_KEYS"
fi

# File mounted hanya dipakai jika tersedia dan tidak kosong
if [ -s "$MOUNTED_AUTHORIZED_KEYS" ]; then
    install \
        -o "$HERMES_USER" \
        -g "$HERMES_USER" \
        -m 0600 \
        "$MOUNTED_AUTHORIZED_KEYS" \
        "$AUTHORIZED_KEYS"
fi

# Pastikan authorized_keys memiliki ownership dan permission benar
if [ -f "$AUTHORIZED_KEYS" ]; then
    chown "$HERMES_USER:$HERMES_USER" "$AUTHORIZED_KEYS"
    chmod 0600 "$AUTHORIZED_KEYS"
fi

chown "$HERMES_USER:$HERMES_USER" "$SSH_DIR"
chmod 0700 "$SSH_DIR"

if [ ! -s "$AUTHORIZED_KEYS" ]; then
    log "ERROR: $AUTHORIZED_KEYS tidak ada atau kosong"
    log "Isi SSH_PUBLIC_KEY atau mount file authorized_keys terlebih dahulu"
    exit 1
fi

# Pastikan konfigurasi tmux berada di /opt/data
TMUX_CONFIG="${HERMES_HOME}/.tmux.conf"

if [ ! -f "$TMUX_CONFIG" ]; then
    install \
        -o "$HERMES_USER" \
        -g "$HERMES_USER" \
        -m 0644 \
        /dev/null \
        "$TMUX_CONFIG"

    cat > "$TMUX_CONFIG" <<'EOF'
set -g default-terminal "xterm-256color"
set -g history-limit 10000
set -g mouse on
EOF

    chown "$HERMES_USER:$HERMES_USER" "$TMUX_CONFIG"
fi

# Buat tmux session sebagai user hermes jika belum ada
if ! sudo -u "$HERMES_USER" \
    env HOME="$HERMES_HOME" \
    tmux has-session -t hermes 2>/dev/null; then

    sudo -u "$HERMES_USER" \
        env HOME="$HERMES_HOME" \
        tmux new-session \
        -d \
        -s hermes \
        -c "$HERMES_HOME"
fi

# Pastikan sshd memakai port 22 dan authorized_keys relatif terhadap HOME
if grep -qE '^[[:space:]]*Port[[:space:]]+' /etc/ssh/sshd_config; then
    sed -i -E "s/^[[:space:]]*Port[[:space:]]+.*/Port ${SSH_PORT}/" \
        /etc/ssh/sshd_config
else
    printf '\nPort %s\n' "$SSH_PORT" >> /etc/ssh/sshd_config
fi

if ! grep -qE '^[[:space:]]*AuthorizedKeysFile[[:space:]]+' /etc/ssh/sshd_config; then
    printf '\nAuthorizedKeysFile .ssh/authorized_keys\n' \
        >> /etc/ssh/sshd_config
fi

# Validasi konfigurasi SSH
/usr/sbin/sshd -t

trap 'log "Stopping SSH server"; exit 0' SIGTERM SIGINT

log "Starting SSH server on port ${SSH_PORT}"
log "Hermes home: ${HERMES_HOME}"
log "Authorized keys: ${AUTHORIZED_KEYS}"

# sshd menjadi PID 1 dan menerima signal Docker secara langsung
exec /usr/sbin/sshd \
    -D \
    -e
