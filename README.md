# 🤖 Hermes Agent — Docker Ready

AI agent yang bisa ngobrol, kerjain tugas, dan akses sistem langsung. Support WhatsApp, Discord, Telegram, dan banyak lagi.

## 🚀 Quick Start

### 1. Pull Image
```bash
docker pull vltruist/hermes-agent:latest
```

### 2. Setup Environment
```bash
cp .env.example .env
# Edit .env dengan API keys kamu
```

### 3. Run
```bash
# Option A: Bridge network (default, lebih aman)
docker-compose up -d

# Option B: Host network (recommended — WebSocket & Tailscale langsung jalan)
docker-compose -f docker-compose.host.yml up -d
```

> **Note:** Dengan `network_mode: host`, container langsung pakai jaringan host. Port custom (`3001`, `5002`) di-set lewat `.env`.

## 📦 Tools Pre-installed

| Tool | Fungsi |
|------|--------|
| curl, wget, jq | HTTP requests & JSON parsing |
| git | Version control |
| openssh-client | SSH ke server lain |
| python3 + pip | Scripting & automation |
| nodejs LTS | WhatsApp bridge (Baileys) |
| tailscale | VPN/mesh networking |
| sudo | Elevated permissions |
| bash, coreutils | Shell utilities |
| sqlite3 | Database untuk sessions & kanban |
| playwright + chromium | Web browsing & automation |
| gh (GitHub CLI) | GitHub operations |
| duckduckgo-search | Web search |

## 🔧 Fitur

### WhatsApp Bridge
- Support Baileys (unofficial WhatsApp Web)
- Auto-reconnect & session management
- Allowlist mode (hybrid: semua bisa chat, admin command terbatas)

### Browser Tools
- Playwright + Chromium headless
- Bisa buka website, screenshot, fill form
- Support vision analysis

### Database
- SQLite3 untuk sessions, kanban, memory
- Persisten via volume mount

### VPN/Mesh
- Tailscale untuk koneksi ke server lain
- Bisa akses private network

### GitHub Integration
- GitHub CLI (gh) untuk manage repo
- CI/CD integration

## ⚙️ Configuration

### Model Provider (OpenRouter)
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

## 🌐 Network Modes

### Bridge Network (Default)
```yaml
# docker-compose.yml
services:
  hermes:
    ports:
      - "3000:3000"   # WhatsApp bridge
      - "5001:5001"   # Dashboard
```
- ✅ Lebih aman (isolated)
- ❌ WebSocket bisa diblokir
- ❌ Tailscale perlu setup manual

### Host Network (Recommended untuk production)
```yaml
# docker-compose.host.yml
services:
  hermes:
    network_mode: host
```
- ✅ WebSocket langsung jalan
- ✅ Tailscale langsung akses
- ✅ Port langsung exposed
- ⚠️ Kurang aman (container bisa akses semua port host)

## 🔐 Environment Variables

```bash
# API Keys
OPENROUTER_API_KEY=your_key_here

# WhatsApp
WHATSAPP_ENABLED=true
WHATSAPP_ALLOWED_USERS=*

# Discord
DISCORD_ENABLED=true
DISCORD_BOT_TOKEN=your_token
DISCORD_ALLOWED_USERS=your_user_id

# Tailscale (optional)
TAILSCALE_AUTH_KEY=tskey-auth-your_key_here
```

## 📁 Volume Mounts

| Path | Fungsi |
|------|--------|
| `/opt/data` | Data persisten (config, memory, sessions) |
| `/opt/data/config.yaml` | Konfigurasi utama |
| `/opt/data/.env` | API keys & secrets |
| `/opt/data/skills/` | Custom skills |
| `/opt/data/plugins/` | Custom plugins |

## 🐳 GitHub Actions

Image otomatis ter-build dan ter-push ke Docker Hub setiap push ke `main`.

### Setup GitHub Secrets:
1. `DOCKER_USERNAME` — username Docker Hub (vltruist)
2. `DOCKER_PASSWORD` — password/access token Docker Hub

## 📝 Dockerfile Layers

1. **Base** — Debian bookworm-slim
2. **System tools** — curl, wget, jq, git, openssh, python3, nodejs, tailscale
3. **Dev libs** — build-essential, libffi, libssl
4. **Playwright** — chromium + dependencies
5. **SQLite3** — database
6. **GitHub CLI** — gh command
7. **Hermes Agent** — pip install

## ⚠️ Known Limitations

| Issue | Workaround |
|-------|------------|
| WebSocket di bridge network | Pakai `network_mode: host` |
| Tailscale socket path beda | Set socket path manual |
| No GPU access | Pakai cloud model (OpenRouter) |
| File system isolated | Pakai volumes untuk persisten |

## 📄 License

MIT
