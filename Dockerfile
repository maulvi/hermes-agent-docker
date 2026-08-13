FROM debian:bookworm-slim

LABEL maintainer="hermes-agent"
LABEL description="Hermes Agent - Ready to use Docker image with official installer"

# Non-interactive install
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# 1. Install minimal system dependencies (needed for installer)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    sudo \
    git \
    openssh-server \
    tmux \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup User & Passwordless Sudo
RUN useradd -m -s /bin/bash hermes \
    && echo 'hermes ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/hermes \
    && chmod 0440 /etc/sudoers.d/hermes

# 3. Setup directories
RUN mkdir -p /opt/data /opt/hermes \
    && chown -R hermes:hermes /opt/data /opt/hermes

USER hermes
WORKDIR /opt/hermes

# 4. Install Hermes Agent (official installer)
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# 5. Setup SSH
RUN sudo mkdir -p /run/sshd \
    && sudo ssh-keygen -A \
    && sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && mkdir -p ~/.ssh && chmod 700 ~/.ssh

# 6. Tmux config
RUN echo 'set -g default-terminal "screen-256color"' > ~/.tmux.conf \
    && echo 'set -g history-limit 10000' >> ~/.tmux.conf \
    && echo 'set -g mouse on' >> ~/.tmux.conf

# 7. Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod +x /entrypoint.sh

EXPOSE 22 5002

CMD ["/entrypoint.sh"]
