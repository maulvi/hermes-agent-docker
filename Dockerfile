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
USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
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
# LAYER 2: Locale and timezone
# ============================================================
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo "${TZ}" > /etc/timezone \
 && sed -i '/^# *en_US.UTF-8 UTF-8/s/^# *//' /etc/locale.gen \
 && locale-gen en_US.UTF-8

# ============================================================
# LAYER 3: Hermes data directory and SSH
# ============================================================
RUN getent passwd hermes \
 && mkdir -p \
      /opt/data/.hermes \
      /opt/data/.ssh \
      /root/.hermes \
      /run/sshd \
 && touch /opt/data/.ssh/authorized_keys \
 && chmod 755 /opt/data \
 && chmod 700 /opt/data/.ssh \
 && chmod 600 /opt/data/.ssh/authorized_keys \
 && chown -R hermes:hermes /opt/data \
 && printf '%s\n' \
      'hermes ALL=(ALL) NOPASSWD: ALL' \
      > /etc/sudoers.d/hermes \
 && chmod 0440 /etc/sudoers.d/hermes \
 && ssh-keygen -A \
 && sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' \
      /etc/ssh/sshd_config \
 && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' \
      /etc/ssh/sshd_config \
 && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' \
      /etc/ssh/sshd_config \
 && sshd -t

# ============================================================
# LAYER 4: Hermes user configuration
# ============================================================
ENV HOME=/opt/data \
    PATH=/opt/hermes/bin:/opt/data/.local/bin:${PATH}

WORKDIR /opt/data

RUN printf '%s\n' \
      'set -g default-terminal "xterm-256color"' \
      'set -g history-limit 10000' \
      'set -g mouse on' \
      > /opt/data/.tmux.conf \
 && chown hermes:hermes /opt/data/.tmux.conf


# ============================================================
# LAYER 5: Entrypoint
# ============================================================
RUN cat > /etc/profile.d/hermes.sh <<'EOF'
export HOME=/opt/data
export HERMES_HOME=/opt/data
export PATH=/opt/hermes/bin:/opt/hermes/.venv/bin:/opt/data/.local/bin:$PATH
EOF

RUN chmod 0644 /etc/profile.d/hermes.sh \
 && chown root:root /etc/profile.d/hermes.sh

RUN cat > /opt/data/.bash_profile <<'EOF'
if [ -f /etc/profile ]; then
    . /etc/profile
fi

if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
EOF

RUN chown hermes:hermes /opt/data/.bash_profile \
 && chmod 0644 /opt/data/.bash_profile
 
COPY --chown=hermes:hermes entrypoint.sh /entrypoint.sh

RUN chmod 0755 /entrypoint.sh

EXPOSE 22

USER root

ENTRYPOINT ["/entrypoint.sh"]
