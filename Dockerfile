# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

LABEL maintainer="hermes-agent"
LABEL description="Hermes Agent - Ready to use Docker image with official installer"

# Non-interactive install
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ============================================================
# LAYER 1: System deps (rarely changes, heavily cached)
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    sudo \
    xz-utils \
    openssh-server \
    tmux \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# LAYER 2: Hermes installer (only rebuilds when hermes updates)
# Uses cache mounts for npm/pip to speed up subsequent builds
# ============================================================
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=/tmp/hermes-download \
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive --skip-setup

# ============================================================
# LAYER 3: User + SSH + tmux (rarely changes, cached)
# ============================================================
RUN useradd -m -s /bin/bash hermes \
    && echo 'hermes ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/hermes \
    && chmod 0440 /etc/sudoers.d/hermes \
    && chown -R hermes:hermes /opt/hermes /opt/data /root/.hermes 2>/dev/null || true

RUN mkdir -p /run/sshd \
    && ssh-keygen -A \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

USER hermes
WORKDIR /opt/data

RUN echo 'set -g default-terminal "screen-256color"' > ~/.tmux.conf \
    && echo 'set -g history-limit 10000' >> ~/.tmux.conf \
    && echo 'set -g mouse on' >> ~/.tmux.conf \
    && mkdir -p ~/.ssh && chmod 700 ~/.ssh

COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod +x /entrypoint.sh

EXPOSE 22 5002

CMD ["/entrypoint.sh"]
