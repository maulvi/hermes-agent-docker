FROM debian:trixie-slim

LABEL maintainer="hermes-agent"
LABEL description="Hermes Agent - Ready to use Docker image with official installer"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ============================================================
# LAYER 1: System dependencies and locale
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
    ripgrep \
    ffmpeg \
    sqlite3 \
    locales \
    tzdata \
    && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# LAYER 2: Hermes installer
# ============================================================
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=/tmp/hermes-download \
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh \
    | bash -s -- --non-interactive --skip-setup

# ============================================================
# LAYER 3: User, data directory, SSH, and tmux
# ============================================================
RUN useradd -m -s /bin/bash hermes \
    && echo 'hermes ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/hermes \
    && chmod 0440 /etc/sudoers.d/hermes \
    && mkdir -p /opt/data /root/.hermes /home/hermes/.hermes /run/sshd \
    && chown -R hermes:hermes /opt/data /home/hermes/.hermes \
    && ssh-keygen -A \
    && sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# ============================================================
# LAYER 4: Hermes user configuration
# ============================================================
USER hermes

ENV HOME=/home/hermes \
    PATH=/opt/hermes/bin:/home/hermes/.local/bin:${PATH}

WORKDIR /opt/data

RUN printf '%s\n' \
    'set -g default-terminal "screen-256color"' \
    'set -g history-limit 10000' \
    'set -g mouse on' \
    > /home/hermes/.tmux.conf \
    && mkdir -p /home/hermes/.ssh \
    && chmod 700 /home/hermes/.ssh \
    && mkdir -p /home/hermes/.hermes

# ============================================================
# LAYER 5: Entrypoint
# ============================================================
COPY --chown=hermes:hermes entrypoint.sh /entrypoint.sh

USER root

RUN chmod 0755 /entrypoint.sh

EXPOSE 22 5002

ENTRYPOINT ["/entrypoint.sh"]
