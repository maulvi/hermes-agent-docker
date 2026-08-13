FROM debian:bookworm-slim

LABEL maintainer="hermes-agent"
LABEL description="Hermes Agent - Ready to use Docker image with all tools pre-installed"

# Non-interactive install
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PIP_BREAK_SYSTEM_PACKAGES=1

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
    sqlite3 \
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxrandr2 \
    libgbm1 libpango-1.0-0 libcairo2 libasound2 \
    libxshmfence1 libx11-xcb1 \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Node.js LTS (for WhatsApp bridge / Baileys)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 3. Setup Locale & TimeZone
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen


# 5. Setup User & Passwordless Sudo
RUN useradd -m -s /bin/bash hermes \
    && echo 'hermes ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/hermes \
    && chmod 0440 /etc/sudoers.d/hermes

# 6. Setup directories
RUN mkdir -p /opt/data /opt/hermes /opt/data/skills /opt/data/plugins \
    /opt/data/memories /opt/data/sessions /opt/data/cron \
    /opt/data/platforms/whatsapp/session \
    && chown -R hermes:hermes /opt/data /opt/hermes /opt/tailscale

USER hermes
WORKDIR /opt/data

# 7. Install Python dependencies
RUN pip3 install \
    hermes-agent \
    playwright \
    duckduckgo-search \
    paho-mqtt \
    beautifulsoup4 \
    requests \
    pydantic \
    uvicorn \
    fastapi \
    pillow \
    2>/dev/null || echo "Some packages may need manual install"

# 8. Install Playwright browsers
RUN python3 -m playwright install chromium 2>/dev/null || \
    echo "Playwright browsers will be installed on first run"

# 9. Install GitHub CLI
RUN mkdir -p ~/bin \
    && curl -fsSL "https://github.com/cli/cli/releases/download/v2.97.0/gh_2.97.0_linux_amd64.tar.gz" -o /tmp/gh.tar.gz \
    && tar xzf /tmp/gh.tar.gz -C /tmp \
    && cp /tmp/gh_*/bin/gh ~/bin/ \
    && rm -rf /tmp/gh* \
    && echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc

# 10. Expose ports
EXPOSE 3000 5001

# 11. Default entrypoint
CMD ["bash"]
