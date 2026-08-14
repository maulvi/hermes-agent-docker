#!/usr/bin/env bash

set -Eeuo pipefail

export HOME=/opt/data
export HERMES_HOME=/opt/data
export PATH="/opt/hermes/bin:/opt/hermes/.venv/bin:/opt/data/.local/bin:${PATH:-}"

SSH_PORT="${SSH_PORT:-22}"
HERMES_USER="${HERMES_USER:-hermes}"
HERMES_HOME="/opt/data"
SSH_DIR="${HERMES_HOME}/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"
MOUNTED_AUTHORIZED_KEYS="/opt/data/ssh/authorized_keys"

log() {
    printf '[entrypoint] %s\n' "$*" >&2
}

if ! getent passwd "$HERMES_USER" >/dev/null 2>&1; then
    log "ERROR: user '$HERMES_USER' tidak ditemukan"
    exit 1
fi

if ! command -v hermes >/dev/null 2>&1; then
    log "ERROR: Hermes CLI tidak ditemukan"
    log "PATH=${PATH}"
    exit 1
fi

log "Hermes CLI: $(command -v hermes)"
log "Hermes home: ${HERMES_HOME}"

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

if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
    printf '%s\n' "$SSH_PUBLIC_KEY" > "$AUTHORIZED_KEYS"
fi

if [ -s "$MOUNTED_AUTHORIZED_KEYS" ]; then
    install \
        -o "$HERMES_USER" \
        -g "$HERMES_USER" \
        -m 0600 \
        "$MOUNTED_AUTHORIZED_KEYS" \
        "$AUTHORIZED_KEYS"
fi

if [ ! -s "$AUTHORIZED_KEYS" ]; then
    log "ERROR: $AUTHORIZED_KEYS tidak ada atau kosong"
    exit 1
fi

chown "$HERMES_USER:$HERMES_USER" "$SSH_DIR"
chown "$HERMES_USER:$HERMES_USER" "$AUTHORIZED_KEYS"
chmod 0700 "$SSH_DIR"
chmod 0600 "$AUTHORIZED_KEYS"

if grep -qE '^[[:space:]]*Port[[:space:]]+' /etc/ssh/sshd_config; then
    sed -i -E "s/^[[:space:]]*Port[[:space:]]+.*/Port ${SSH_PORT}/" \
        /etc/ssh/sshd_config
else
    printf '\nPort %s\n' "$SSH_PORT" >> /etc/ssh/sshd_config
fi

if grep -qE '^[[:space:]]*AuthorizedKeysFile[[:space:]]+' /etc/ssh/sshd_config; then
    sed -i -E \
        's|^[[:space:]]*AuthorizedKeysFile[[:space:]]+.*|AuthorizedKeysFile .ssh/authorized_keys|' \
        /etc/ssh/sshd_config
else
    printf '\nAuthorizedKeysFile .ssh/authorized_keys\n' \
        >> /etc/ssh/sshd_config
fi

/usr/sbin/sshd -t

trap 'log "Stopping SSH server"; exit 0' SIGTERM SIGINT

log "Starting SSH server on port ${SSH_PORT}"
log "Authorized keys: ${AUTHORIZED_KEYS}"

if [ "$#" -gt 0 ]; then
    exec "$@"
fi

exec /usr/sbin/sshd -D -e
