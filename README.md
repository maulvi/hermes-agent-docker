# 🤖 Hermes Agent — Docker Ready

AI agent yang bisa ngobrol, kerjain tugas, dan akses sistem langsung. Support WhatsApp, Discord, Telegram, dan banyak lagi.

## 🚀 Quick Start

### 1. Pull Image
```bash
docker pull yourusername/hermes-agent:latest
```

### 2. Setup Environment
```bash
cp .env.example .env
# Edit .env dengan API keys kamu
```

### 3. Run
```bash
docker-compose up -d
```

## 📦 Tools Pre-installed

| Tool | Fungsi |
|------|--------|
| curl, wget, jq | HTTP requests & JSON parsing |
| git | Version control |
| openssh-client | SSH ke server lain |
| python3 + pip | Scripting & automation |
| nodejs + npm | WhatsApp bridge (Baileys) |
| tailscale | VPN/mesh networking |
| sudo | Elevated permissions |
| bash, coreutils | Shell utilities |

## ⚙️ Configuration

### Model Provider
```yaml
# config.yaml
model:
  default: qwen/qwen3.7-flash
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
```

### Custom Provider (e.g., 9router)
```yaml
providers:
  custom:
    api_key: sk-your_key_here
    base_url: http://100.100.12.34:20128/v1
```

### Fallback Model
```yaml
fallback_providers:
  provider: openrouter
  model: qwen/qwen3.7-flash
```

## 🔧 GitHub Actions

Image otomatis ter-build dan ter-push ke Docker Hub setiap push ke `main`.

### Setup GitHub Secrets:
1. `DOCKER_USERNAME` — username Docker Hub
2. `DOCKER_PASSWORD` — password/access token Docker Hub

## 📁 Volume Mounts

| Path | Fungsi |
|------|--------|
| `/opt/data` | Data persisten (config, memory, sessions) |
| `/opt/data/config.yaml` | Konfigurasi utama |
| `/opt/data/.env` | API keys & secrets |

## 🌐 Ports

| Port | Fungsi |
|------|--------|
| 3000 | WhatsApp bridge |
| 5001 | Dashboard |

## 🐳 Docker Compose

```yaml
services:
  hermes:
    image: yourusername/hermes-agent:latest
    container_name: hermes
    restart: unless-stopped
    volumes:
      - hermes-data:/opt/data
    env_file:
      - .env
    ports:
      - "3000:3000"
      - "5001:5001"
```

## 📝 License

MIT
