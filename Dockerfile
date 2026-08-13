FROM debian:bookworm-slim

LABEL maintainer="hermes-agent"
LABEL description="Hermes Agent - Ready to use Docker image with all tools pre-installed"

# Non-interactive install
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# 1. Install system utilities & dev libs
RUN apt-get update && apt-get install -y --no-install-recommends \
    coreutils bash sed grep mawk findutils \
    curl wget jq netcat-openbsd socat \
    openssh-client \
    python3 python3-pip python3-venv \
    libffi-dev libssl-dev \
    build-essential \
    tzdata locales sudo nano tmux git \
    ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Node.js 20.x (for WhatsApp bridge / Baileys)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 3. Setup Locale & TimeZone
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 TZ=Asia/Jakarta

# 4. Install Tailscale (static binary)
RUN mkdir -p /opt/tailscale \
    && curl -fsSL -o /tmp/ts.tgz "https://pkgs.tailscale.com/stable/tailscale_1.102.2_amd64.tgz" \
    && tar xzf /tmp/ts.tgz -C /tmp \
    && cp /tmp/tailscale_1.102.2_amd64/tailscale /opt/tailscale/ \
    && cp /tmp/tailscale_1.102.2_amd64/tailscaled /opt/tailscale/ \
    && rm -rf /tmp/ts.tgz /tmp/tailscale_1.102.2_amd64

# 5. Setup User & Passwordless Sudo
RUN useradd -m -s /bin/bash hermes \
    && echo 'hermes ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/hermes \
    && chmod 0440 /etc/sudoers.d/hermes

# 6. Setup directories
RUN mkdir -p /opt/data /opt/hermes \
    && chown -R hermes:hermes /opt/data /opt/hermes /opt/tailscale

USER hermes
WORKDIR /opt/data

# 7. Install Hermes Agent
RUN pip3 install --user --break-system-packages hermes-agent 2>/dev/null || \
    echo "Hermes will be installed on first run or via pip"

# 8. Expose ports
EXPOSE 3000 5001

CMD ["bash"]
