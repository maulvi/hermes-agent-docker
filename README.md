# 🤖 Hermes Agent — Docker Ready

Docker image untuk [Hermes Agent](https://github.com/NousResearch/hermes-agent) dengan official installer, SSH server, dan tmux built-in.

## 🚀 Quick Start

### 1. Pull Image
```bash
docker pull vltruist/hermes-agent:latest
```

### 2. Setup SSH Public Key
```bash
mkdir -p ssh
cp ~/.ssh/id_ed25519.pub ssh/authorized_keys
```

### 3. Setup Environment
```bash
cp .env.example .env
# Edit .env dengan API keys kamu
```

### 4. Run
```bash
docker-compose -f docker-compose.host.yml up -d
```

### 5. Connect
```bash
ssh hermes@<IP_HOST>
tmux attach -t hermes
```

## 📦 Apa yang ada di image ini?

### Layer 1: System Dependencies (pre-installed)
| Package | Fungsi |
|---------|--------|
| git | Version control |
| curl, wget | HTTP client |
| sudo | Elevated permissions |
| xz-utils | Extract .tar.xz (untuk installer) |
| openssh-server | SSH access ke container |
| tmux | Persistent terminal sessions |
| sqlite3 | Database |

### Layer 2: Hermes Agent (via official installer)
Installer otomatis install:
- **Python 3** + virtual environment
- **Node.js 22 LTS**
- **ripgrep** (fast search)
- **ffmpeg** (media processing)
- **Playwright + Chromium** (browser tools)
- **Hermes Agent** + semua dependencies

### Layer 3: SSH + tmux + Entrypoint
- SSH server (public key only, password disabled)
- tmux config (256 color, mouse support, 10k history)
- Entrypoint: SSH + tmux + Hermes gateway auto-start

## 🔐 SSH Access

Container punya SSH server built-in. Login pakai **public key only** (password disabled).

### Setup:

**Option 1: Via file (recommended)**
```bash
# Di host, buat folder ssh
mkdir -p ssh
cp ~/.ssh/id_ed25519.pub ssh/authorized_keys
```

**Option 2: Via environment variable**
```bash
# Di .env
SSH_PUBLIC_KEY=ssh-ed25519 AAAA... your@email.com
```

### Connect:
```bash
ssh hermes@<IP_HOST>
```

> **Username:** `hermes` | **Port:** `22` | **Auth:** Public key only (password disabled)

### Tmux (persistent sessions):
```bash
# tmux auto-start saat container boot
# Kalau disconnect, reconnect:
ssh hermes@<IP_HOST>
tmux attach -t hermes
```

| Shortcut | Fungsi |
|----------|--------|
| `Ctrl+B, D` | Detach (session tetap jalan) |
| `tmux ls` | Lihat semua session |
| `tmux attach -t nama` | Reconnect |
| `tmux kill-session -t nama` | Hapus session |

## ⚙️ Configuration

Hermes baca config dari `/opt/data/`:
- `config.yaml` — model, provider, toolsets
- `.env` — API keys, secrets

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

### Fallback
```yaml
fallback_providers:
  provider: openrouter
  model: qwen/qwen3.7-flash
```

## 🌐 Network

Image ini pakai `network_mode: host` — container langsung pakai jaringan host.

- ✅ WebSocket langsung jalan
- ✅ Tailscale langsung akses (tanpa install di container)
- ✅ Port langsung exposed
- ⚠️ Security diatur lewat firewall host (UFW)

## 📁 Volume Mounts

| Path | Fungsi |
|------|--------|
| `/opt/data` | Data persisten (config, memory, sessions) |

Mount `/opt/data` dari host untuk persistensi data antar restart.

## 🐳 Docker Compose

```yaml
services:
  hermes:
    image: vltruist/hermes-agent:latest
    container_name: hermes
    restart: unless-stopped
    network_mode: host
    volumes:
      - hermes-data:/opt/data
      - ./ssh:/opt/data/ssh:ro
    env_file:
      - .env
    environment:
      - TZ=Asia/Jakarta
      - HERMES_DASHBOARD_PORT=5002
```

## 🔧 Build

Image di-build otomatis via GitHub Actions setiap push ke `main`.

### Build locally:
```bash
docker build -t hermes-agent .
```

### Build time:
- **First build:** ~13 menit (download semua dependencies)
- **Cached build:** ~5 menit (pakai BuildKit cache)

### GitHub Secrets:
| Secret | Fungsi |
|--------|--------|
| `DOCKER_USERNAME` | Username Docker Hub |
| `DOCKER_PASSWORD` | Password/access token Docker Hub |

## ⚠️ Known Limitations

| Issue | Workaround |
|-------|------------|
| No GPU access | Pakai cloud model (OpenRouter) |
| No WhatsApp bridge | Install manual di dalam container |
| Security via host firewall | Atur UFW di bare metal |

## 📄 License

MIT
