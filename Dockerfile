FROM nousresearch/hermes-agent:latest

LABEL maintainer="hermes-agent"
LABEL description="Hermes Agent"

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
    nano \
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
    alacritty \
    && rm -rf /var/lib/apt/lists/*
    
# ============================================================
# LAYER 3: User, data directory, SSH, and tmux
# ============================================================
RUN echo 'hermes ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/hermes \
 && chmod 0440 /etc/sudoers.d/hermes \
 && mkdir -p /opt/data /root/.hermes /home/hermes/.hermes /run/sshd \
 && chown -R hermes:hermes /opt/data /home/hermes/.hermes \
 && ssh-keygen -A \
 && sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
 && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
 && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
 
RUN getent passwd hermes \
 && test -d /home/hermes \
 && echo 'hermes ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/hermes \
 && chmod 0440 /etc/sudoers.d/hermes \
 && mkdir -p /opt/data /root/.hermes /home/hermes/.hermes /run/sshd \
 && chown -R hermes:hermes /opt/data /home/hermes/.hermes \
 && ssh-keygen -A

# ============================================================
# LAYER 4: Hermes user configuration
# ============================================================
USER hermes

ENV HOME=/home/hermes \
    PATH=/opt/hermes/bin:/home/hermes/.local/bin:${PATH}

WORKDIR /opt/data

RUN printf '%s\n' \
    'set -g default-terminal "xterm-256color"' \
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

EXPOSE 2222

ENTRYPOINT ["/entrypoint.sh"]
