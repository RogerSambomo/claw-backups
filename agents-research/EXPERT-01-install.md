# Expert 01: OpenClaw Installation

## Requirements

### System Requirements

- **Operating Systems**: macOS, Linux, or Windows (native or WSL2; WSL2 recommended for Windows)
- **Node.js**: **Node 24** (recommended) or **Node 22.14+** (minimum)
  - The installer script handles Node installation automatically
  - On macOS: installs Node via Homebrew
  - On Linux: installs Node via NodeSource setup scripts (apt/dnf/yum)
  - On Windows: installs Node via winget → Chocolatey → Scoop fallback chain
- **Git**: Required for git install method; also needed by npm dependencies that use git URLs
- **pnpm**: Only required if building from source
- **Docker** (optional): Only needed for containerized gateway deployments; minimum 2 GB RAM for image build

### Optional for Full Deployment

- **Docker Desktop / Docker Engine** + Docker Compose v2 (for containerized setup)
- **Tailscale** (for remote access to VPS-hosted gateway)
- **Systemd** (Linux) — for user service management; requires `sudo loginctl enable-linger $USER`
- **Homebrew** (macOS) — installed automatically by installer if missing

### Disk / RAM Notes

- Docker image build needs **2 GB+ RAM** (pnpm install may be OOM-killed on 1 GB hosts, exit 137)
- Standard CLI install is lightweight

---

## Installation Methods

### 1. Recommended: Installer Script (One-liner)

**macOS / Linux / WSL2:**
```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

**Skip onboarding:**
```bash
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
```

The installer script automatically:
- Detects OS
- Installs Node 24 if missing
- Installs Git if missing
- Installs OpenClaw via npm (default) or git
- Attempts to run onboarding and install daemon (Gateway service)

---

### 2. Local Prefix Installer (`install-cli.sh`)

Best for environments where you want **self-contained** installation under `~/.openclaw` with **no system Node dependency**.

```bash
curl -fsSL https://openclaw.ai/install-cli.sh | bash
```

**Features:**
- Downloads a pinned Node LTS tarball to `<prefix>/tools/node-v<version>` with SHA-256 verification
- Installs OpenClaw under prefix
- Writes wrapper to `<prefix>/bin/openclaw`
- Supports `--prefix`, `--json` (NDJSON events for automation), `--version`, `--node-version` flags

**Example with custom prefix:**
```bash
curl -fsSL https://openclaw.ai/install-cli.sh | bash -s -- --prefix /opt/openclaw --json
```

---

### 3. npm / pnpm / Bun (Existing Node.js)

Assumes you already manage Node yourself.

**npm:**
```bash
npm install -g openclaw@latest
openclaw onboard --install-daemon
```

**pnpm** (requires explicit approval for build scripts):
```bash
pnpm add -g openclaw@latest
pnpm approve-builds -g
openclaw onboard --install-daemon
```

**Bun** (CLI-only; Gateway still uses Node):
```bash
bun add -g openclaw@latest
openclaw onboard --install-daemon
```

**Sharp build workaround** (if sharp/libvips fails):
```bash
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest
```

---

### 4. From Source

For contributors or bleeding-edge users:

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install && pnpm ui:build && pnpm build
pnpm link --global
openclaw onboard --install-daemon
```

Or use without linking:
```bash
pnpm openclaw ...
```

**Prereqs for source:**
- Node 24 (or 22.14+)
- pnpm (preferred) or Bun

---

### 5. GitHub main Branch via npm

```bash
npm install -g github:openclaw/openclaw#main
```

---

### 6. Docker / Containerized

**Pre-built image:**
```bash
export OPENCLAW_IMAGE="ghcr.io/openclaw/openclaw:latest"
./scripts/docker/setup.sh
```

**Build locally then setup:**
```bash
./scripts/docker/setup.sh
```

Pre-built images at GitHub Container Registry: tags include `main`, `latest`, `<version>`.

The setup script runs onboarding automatically, generates a gateway token to `.env`, and starts the gateway via Docker Compose.

**Manual Docker flow:**
```bash
docker build -t openclaw:local -f Dockerfile .
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js onboard --mode local --no-install-daemon
docker compose up -d openclaw-gateway
```

**Podman** is also supported (rootless container alternative to Docker).

---

### 7. Nix

Declarative install via Nix flake. See: `/install/nix`

---

### 8. Ansible

Automated fleet provisioning. See: `/install/ansible`

---

## Configuration Basics

### Key Files & Paths

| Path | Purpose |
|------|---------|
| `~/.openclaw/workspace/` | User workspace (skills, prompts, memories) — keep this as your git repo |
| `~/.openclaw/openclaw.json` | Main configuration file (JSON/JSON5) |
| `~/.openclaw/credentials/` | Channel/provider credentials |
| `~/.openclaw/agents/<agentId>/sessions/` | Session state |
| `~/.openclaw/secrets.json` | File-backed secrets (optional) |
| `/tmp/openclaw/` | Logs |
| `<prefix>/bin/openclaw` | CLI wrapper (install-cli.sh prefix method) |

### Post-Install Setup

```bash
openclaw setup        # Bootstrap workspace + config
openclaw onboard --install-daemon   # Run onboarding + install Gateway service
```

### Gateway Service Management

- **macOS**: LaunchAgent via `openclaw onboard --install-daemon` or `openclaw gateway install`
- **Linux/WSL2**: systemd **user** service. Enable lingering to survive logout:
  ```bash
  sudo loginctl enable-linger $USER
  ```
- **Windows**: Scheduled Task + per-user Startup-folder fallback

### Verifying Install

```bash
openclaw --version       # Confirm CLI is available
openclaw doctor           # Check for config issues
openclaw gateway status   # Verify Gateway is running
openclaw health           # Sanity check
```

### Gateway Configuration (openclaw.json schema)

Key config paths (set via `openclaw config set` or directly in `openclaw.json`):
- `gateway.mode` — `local`, `lan`, `tailnet`, etc.
- `gateway.bind` — bind address
- `gateway.port` — default `18789`
- `gateway.auth.token` — gateway token for remote access
- `gateway.auth.password` — password auth alternative to token
- `gateway.controlUi.allowedOrigins` — CORS origins for Control UI

### Startup Tuning for Small VMs / ARM

```bash
export NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
mkdir -p /var/tmp/openclaw-compile-cache
export OPENCLAW_NO_RESPAWN=1
```

---

## Key Insights for Auto-Deployment

### 1. Fully Non-Interactive Install (Best for VPS / CI)

```bash
# One-liner: non-interactive npm install, skip onboarding
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-prompt --no-onboard
```

```bash
# Or git method via environment variables
OPENCLAW_INSTALL_METHOD=git OPENCLAW_NO_PROMPT=1 \
  curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash
```

### 2. Use `install-cli.sh` for Self-Contained VPS Deployments

Best for fresh server provisioning — everything under `~/.openclaw`, no system Node dependency:

```bash
curl -fsSL https://openclaw.ai/install-cli.sh | bash -s -- --prefix /opt/openclaw --json
```

The `--json` flag emits NDJSON events for programmatic automation.

### 3. Docker Is Optional But Simplifies Isolation

Docker is **not required** for normal use. It shines when you want:
- Clean separation from host system
- Throwaway gateway environments
- CI/CD pipelines

For a **simple VPS**, the CLI install is lighter and preferred.

### 4. Node Is Installed Automatically

The installer scripts handle Node 24 installation for you. You do **not** need to pre-install Node for:
- `install.sh` / `install.ps1` — handles Node automatically
- `install-cli.sh` — bundles its own Node under prefix

Only use manual `npm install -g` if you already have Node managed.

### 5. Sharp/libvips Workaround May Be Needed

On some systems, `sharp` (image processing) conflicts with globally installed `libvips`. The installer defaults `SHARP_IGNORE_GLOBAL_LIBVIPS=1`. To override:
```bash
SHARP_IGNORE_GLOBAL_LIBVIPS=0 curl -fsSL https://openclaw.ai/install.sh | bash
```

### 6. PATH Check After Install

If `openclaw` command is not found after install, check:
```bash
node -v           # Is Node installed?
npm prefix -g     # Where are global packages?
echo "$PATH"      # Is the global bin dir in PATH?
```

Fix: add to `~/.bashrc` or `~/.zshrc`:
```bash
export PATH="$(npm prefix -g)/bin:$PATH"
```

### 7. systemd Lingering for Always-On Gateway on Linux

Without lingering, systemd kills user services on logout:
```bash
sudo loginctl enable-linger $USER
```

### 8. Gateway Remote Access Options

- **Loopback only** (default, most secure)
- **LAN** — bind to LAN interface (requires `gateway.auth.token` or password)
- **Tailscale** — via Tailscale Serve (recommended for remote access)
- **SSH tunnel** — tunnel local port to VPS

### 9. Update Without Wrecking Setup

Keep personal config and workspace **outside** the repo:
- Config: `~/.openclaw/openclaw.json`
- Workspace: `~/.openclaw/workspace` (git repo)

Updates: `git pull` + `pnpm install` (or your package manager's install step).

### 10. Credential Storage

Channel credentials stored at `~/.openclaw/credentials/<channel>/`. These are the files to back up, along with `openclaw.json` and the workspace git repo.

---

## Quick-Start for Fresh VPS (Summary)

```bash
# 1. Non-interactive install
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-prompt --no-onboard

# 2. Verify
openclaw --version
openclaw doctor

# 3. Setup workspace
openclaw setup

# 4. Install gateway as systemd user service
openclaw onboard --install-daemon

# 5. Enable lingering so gateway survives logout
sudo loginctl enable-linger $USER

# 6. Reload and check
systemctl --user daemon-reload
systemctl --user enable --now openclaw-gateway
openclaw gateway status
```

For **completely self-contained** (no system Node):
```bash
curl -fsSL https://openclaw.ai/install-cli.sh | bash -s -- --prefix ~/.openclaw --json
```
