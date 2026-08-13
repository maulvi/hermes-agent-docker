FROM debian:bookworm-slim

LABEL maintainer="hermes-agent"
LABEL description="Hermes Agent - Ready to use Docker image with official installer"

# Non-interactive install
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# 1. Install ONLY what installer doesn't handle
# - openssh-server: SSH access
# - tmux: persistent sessions
# - sudo: elevated permissions
# - xz-utils: installer needs this to extract Node.js .tar.xz
# - sqlite3: database
# - git, curl, ca-certificates: installer dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    gnupg \
    sudo \
    xz-utils \
    openssh-server \
    tmux \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Hermes Agent (official installer - handles Python, Node.js, ripgrep, ffmpeg)
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive --skip-setup

# 3. Setup User & Passwordless Sudo
RUN useradd -m -s /bin/bash hermes \
    && echo 'hermes ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/hermes \
    && chmod 0440 /etc/sudoers.d/hermes \
    && chown -R hermes:hermes /opt/hermes /opt/data /root/.hermes 2>/dev/null || true

# 4. Setup SSH
RUN mkdir -p /run/sshd \
    && ssh-keygen -A \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# 5. Switch to hermes user
USER hermes
WORKDIR /opt/data

# 6. Tmux config
RUN echo 'set -g default-terminal "screen-256color"' > ~/.tmux.conf \
    && echo 'set -g history-limit 10000' >> ~/.tmux.conf \
    && echo 'set -g mouse on' >> ~/.tmux.conf \
    && mkdir -p ~/.ssh && chmod 700 ~/.ssh

# 7. Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod +x /entrypoint.sh

EXPOSE 22 5002

CMD ["/entrypoint.sh"]
