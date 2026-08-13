#!/bin/bash
# Inject SSH public key if provided via environment variable
if [ -n "$SSH_PUBLIC_KEY" ]; then
    echo "$SSH_PUBLIC_KEY" > ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

# Also check for mounted key file
if [ -f /opt/data/ssh/authorized_keys ]; then
    cp /opt/data/ssh/authorized_keys ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

# Start tmux session in background (auto-start)
tmux new-session -d -s hermes

# Start SSH daemon
exec sudo /usr/sbin/sshd -D
