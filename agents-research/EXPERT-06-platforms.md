# Expert 06: OpenClaw Platforms

## Supported Platforms

### Desktop / Server OS

| Platform | Status | Gateway Host | Companion App | Service Manager |
|----------|--------|-------------|--------------|-----------------|
| **macOS** | ✅ Fully supported | Yes | Yes (menu bar) | LaunchAgent (`ai.openclaw.gateway`) |
| **Linux** | ✅ Fully supported | Yes | Planned (contributions welcome) | systemd user service |
| **Windows (WSL2)** | ✅ Recommended | Yes | Planned | systemd user service (inside WSL) |
| **Windows (Native)** | ⚠️ Partial | Yes | Planned | Scheduled Task + Startup folder fallback |
| **Bun** | ❌ Not recommended | N/A | N/A | Gateway has WhatsApp/Telegram bugs on Bun |

**Runtime:** Node is the recommended runtime everywhere. Bun is explicitly not recommended for the Gateway.

### Cloud VPS / Hosting

| Provider | Method | Notes |
|----------|--------|-------|
| **AWS** | Not directly documented | Generic Linux instructions apply |
| **GCP (Compute Engine)** | Docker | e2-small (2 vCPU, 2GB RAM) minimum; e2-micro works but may OOM on Docker builds |
| **Azure (Linux VM)** | Installer script + Azure Bastion | SSH via Bastion only (no public IP on VM); NSG hardening included; Standard_B2as_v2 VM ~$55/mo + Bastion ~$140/mo |
| **Hetzner** | Docker | ~$5/mo for a Debian VPS; most cost-effective option; community Terraform modules available |
| **Fly.io** | Docker | Free tier eligible; shared-cpu-2x + 2GB RAM ~$10-15/mo; auto HTTPS; x86 only |
| **exe.dev** | VM + nginx proxy | Stateful VM; Shelley (exe.dev agent) can auto-install OpenClaw; HTTPS handled by exe.dev |

### Mobile Nodes

| Platform | Status | Role | Gateway Required |
|----------|--------|------|-----------------|
| **iOS** | 🧪 Internal preview (not publicly distributed) | Node only (no gateway) | Yes — connects to remote gateway |
| **Android** | 🧪 Source available, not publicly released | Node only (no gateway) | Yes — connects to remote gateway |

---

## Platform-Specific Setup

### macOS

- **Installation:** Install `OpenClaw.app`, complete TCC permission checklist (Notifications, Accessibility, Screen Recording, Microphone, Speech Recognition, Automation/AppleScript).
- **Modes:**
  - **Local** (default): app attaches to local Gateway or auto-enables launchd service.
  - **Remote:** connects to Gateway over SSH/Tailscale; starts node host service for remote Gateway access.
- **Node capabilities:** Canvas (`canvas.present`, `canvas.navigate`, `canvas.eval`, `canvas.snapshot`, `canvas.a2ui.*`), Camera (`camera.snap`, `camera.clip`), Screen (`screen.record`), System (`system.run`, `system.notify`).
- **Exec approvals:** Controlled via `~/.openclaw/exec-approvals.json` with per-agent allowlist patterns.
- **State dir:** Avoid iCloud/cloud-synced paths (`~/Library/Mobile Documents/...`, `~/Library/CloudStorage/...`) — can cause file-lock/sync races.
- **Service:** Per-user LaunchAgent label `ai.openclaw.gateway` (or `ai.openclaw.<profile>`).
- **Deep links:** `openclaw://agent?message=...` with optional `sessionKey`, `deliver`, `channel`.
- **SSH tunnels:** When in remote mode, opens SSH tunnel `ssh -N -L 18789:127.0.0.1:18789` with BatchMode + ExitOnForwardFailure + keepalive.

### Linux

- **Quick path (VPS):**
  1. Install Node 24 (or Node 22 LTS 22.14+)
  2. `npm i -g openclaw@latest`
  3. `openclaw onboard --install-daemon`
  4. SSH tunnel: `ssh -N -L 18789:127.0.0.1:18789 user@host`
  5. Open `http://127.0.0.1:18789/` and authenticate
- **Optional:** Bun (experimental), Nix, Docker.
- **Service:** systemd user service (`openclaw-gateway[-<profile>].service`). For shared/always-on servers, use a system service.
- **Systemd service file:** `~/.config/systemd/user/openclaw-gateway[-<profile>].service` with `After=network-online.target`, `Restart=always`, `RestartSec=5`.

### Windows (WSL2 — recommended)

1. Install WSL2 + Ubuntu: `wsl --install` or `wsl --install -d Ubuntu-24.04`
2. Enable systemd inside WSL: add `[boot] systemd=true` to `/etc/wsl.conf`, then `wsl --shutdown`
3. Inside WSL: follow Linux install steps (`git clone`, `pnpm install`, `openclaw onboard`)
4. For headless auto-start: `sudo loginctl enable-linger "$(whoami)"` + `openclaw gateway install` + WSL auto-start via Scheduled Task
5. Expose WSL services over LAN via `netsh interface portproxy` (WSL IP changes on restart — needs refresh script)

**Native Windows (caveats):**
- Website installer via `install.ps1` works.
- Core CLI (`--version`, `doctor`, `plugins list --json`, local agent smoke test) works.
- `openclaw onboard --non-interactive --install-daemon` and `gateway install` try Scheduled Tasks first; fallback to per-user Startup folder.
- If `schtasks` hangs, it now aborts quickly and falls back.
- WSL2 is still the recommended path for full experience.

### iOS (Node)

- **Requirements:** Gateway running on another device (macOS/Linux/Windows WSL2). Network path: same LAN via Bonjour (`_openclaw-gw._tcp.local.`), or Tailnet via unicast DNS-SD, or manual host/port fallback.
- **Quick start:** Start gateway → open iOS app → pick discovered gateway (or manual) → approve pairing on host with `openclaw devices approve <requestId>` → verify with `openclaw nodes status`.
- **APNs push (relay-backed for official builds):** Gateway needs `gateway.push.apns.relay.baseUrl`. App uses App Attest + Apple receipt for relay proof. Gateway stores relay handle (not raw APNs token). Local/dev builds use direct APNs credentials via env vars.
- **Node capabilities:** Canvas (WKWebView), Screen snapshot, Camera capture, Location, Voice wake + talk mode (best-effort background).
- **Discovery:** Bonjour on LAN; Wide-Area Bonjour via Tailscale split DNS for cross-network.
- **Common errors:** `NODE_BACKGROUND_UNAVAILABLE` (foreground required), `A2UI_HOST_NOT_CONFIGURED` (Gateway must advertise canvas host URL).

### Android (Node)

- **Requirements:** Gateway on "master" machine. Android reaches gateway via mDNS/NSD (same LAN) or Tailscale Serve/Funnel (`wss://` required for remote; raw `ws://` tailnet IP not sufficient).
- **Quick start:** Start gateway with `openclaw gateway --port 18789` → open Android app → Connect tab → Setup Code or Manual mode → approve pairing with `openclaw devices approve <requestId>`.
- **Foreground service:** Keeps gateway connection alive with persistent notification.
- **Auto-reconnect:** Uses last manual endpoint or last discovered gateway on launch.
- **Node capabilities:**
  - Canvas + A2UI (`canvas.navigate`, `canvas.eval`, `canvas.snapshot`)
  - Camera (`camera.snap`, `camera.clip`) — foreground + permission-gated
  - Voice (single mic on/off with transcript capture; `talk.speak` playback)
  - Device: `device.status`, `device.info`, `device.permissions`, `device.health`
  - Notifications: `notifications.list`, `notifications.actions` (Notification Listener permission required)
  - Photos, Contacts, Calendar, Call Log, SMS, Motion/Pedometer
- **Notification forwarding config:** `notifications.allowPackages`, `notifications.denyPackages`, `notifications.quietHours`, `notifications.rateLimit`.
- **Assistant entrypoints:** Google Assistant / App Actions — no gateway config needed.
- **Canvas host:** Navigate to `http://<gateway-host>:18789/__openclaw__/canvas/` or `http://<gateway-host>:18789/__openclaw__/a2ui/`.

### GCP (Compute Engine — Docker)

- **VM:** Debian 12, e2-small (2 vCPU, 2GB RAM), 20GB boot disk. e2-micro free tier eligible but often OOMs on Docker builds.
- **Persistence:** Mount `~/.openclaw` and `~/.openclaw/workspace` from host into container.
- **Access:** SSH tunnel from laptop (`gcloud compute ssh ... -- -L 18789:127.0.0.1:18789`).
- **Environment:** `OPENCLAW_GATEWAY_BIND=lan`, `OPENCLAW_GATEWAY_PORT=18789`, `OPENCLAW_GATEWAY_TOKEN`, `GOG_KEYRING_PASSWORD`, `XDG_CONFIG_HOME`.
- **Auth:** Approve browser device via `openclaw devices approve <requestId>`.
- **State:** Docker containers are ephemeral — all persistent data must be on host mounts.

### Azure (Linux VM)

- **VM:** Ubuntu 24.04 LTS, Standard_B2as_v2, no public IP (Bastion-only SSH).
- **Security:** NSG rules — SSH allowed only from Bastion subnet; deny from internet and other VNet sources.
- **Access:** `az network bastion ssh` (requires `az extension add -n ssh`).
- **Install:** `curl -fsSL https://openclaw.ai/install.sh -o /tmp/install.sh && bash /tmp/install.sh`.
- **Cost:** ~$55/mo VM + ~$140/mo Bastion. Can deallocate VM when not in use to stop compute billing.
- **Service account:** For automation, create dedicated service account with minimal IAM permissions (not Owner).

### Hetzner (Docker)

- **VPS:** Ubuntu/Debian, ~$5/mo.
- **Docker:** `curl -fsSL https://get.docker.com | sh`
- **Persistence:** `chown -R 1000:1000 /root/.openclaw` (container user UID 1000).
- **Access:** `ssh -N -L 18789:127.0.0.1:18789 root@VPS_IP`.
- **Infrastructure as Code:** Community Terraform modules at `openclaw-terraform-hetzner` + `openclaw-docker-config`.
- **Security reminder:** Strict separation — dedicated VPS + accounts; no personal profiles on the host.

### Fly.io

- **App:** `fly apps create`, `fly volumes create openclaw_data --size 1`.
- **Config:** `fly.toml` with `NODE_ENV=production`, `OPENCLAW_STATE_DIR=/data`, `OPENCLAW_GATEWAY_BIND=lan`, port 3000 (not 18789), 2GB RAM minimum.
- **Secrets:** `fly secrets set OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)`, plus provider API keys.
- **Persistence:** `/data` volume (not container filesystem).
- **Private deployment:** `fly.private.toml` — no public IPs; access via `fly proxy`, WireGuard VPN, or SSH only.
- **Troubleshooting:** OOM at 512MB (use 2GB); delete lock files on restart (`rm -f /data/gateway.*.lock`); `fly ssh console -C "tee /data/openclaw.json"` for config writes.
- **Architecture:** x86 only.
- **Cost:** ~$10-15/mo with recommended config.

### exe.dev

- **Auto-install:** Shelley (exe.dev agent) can install OpenClaw instantly via a standardized prompt.
- **Manual install:** `curl -fsSL https://openclaw.ai/install.sh | bash`, then configure nginx to proxy port 18789 to `/`.
- **Nginx config:** Must enable `proxy_http_version 1.1`, `Upgrade $http_upgrade`, `Connection "upgrade"`, `proxy_read_timeout 86400s` for WebSocket support.
- **Access:** `https://<vm-name>.exe.xyz/` — exe.dev handles HTTPS forwarding from port 8000.
- **Updates:** `npm i -g openclaw@latest && openclaw doctor && openclaw gateway restart`.

---

## Mobile Nodes

### Overview

Both iOS and Android are **companion node apps** — they do NOT host the Gateway. The Gateway must run on a separate machine (macOS, Linux, or Windows WSL2). Mobile devices connect to the remote Gateway over WebSocket.

### Connection Architecture

```
Mobile Node ⇄ (mDNS/NSD + WebSocket) ⇄ Gateway (on another machine)
Mobile Node ⇄ (Tailscale Serve/Funnel + WebSocket) ⇄ Gateway (remote)
```

### Key Differences: iOS vs Android

| Feature | iOS | Android |
|---------|-----|---------|
| Public distribution | ❌ Internal preview only | ❌ Source only |
| Pairing | `openclaw devices approve` | `openclaw devices approve` |
| mDNS/Bonjour | ✅ LAN | ✅ NSD |
| Tailscale cross-network | ✅ Unicast DNS-SD | ✅ Wide-Area Bonjour |
| Push notifications | APNs (relay-backed for official builds) | FCM not mentioned |
| Canvas | WKWebView | WebView |
| Voice wake | ✅ (Settings toggle) | ❌ (removed) |
| Notification forwarding | N/A | ✅ (Notification Listener) |
| Google Assistant | N/A | ✅ App Actions |
| Camera | ✅ | ✅ |
| Contacts/Calendar | N/A | ✅ |
| SMS/Call Log | N/A | ✅ |
| Background audio | ⚠️ Best-effort | ⚠️ App leaves foreground = stops |

### Pairing Workflow (Both)

1. Start Gateway on host machine.
2. Open mobile app → Connect tab → discover gateway or enter manual host/port.
3. On host: `openclaw devices list` → `openclaw devices approve <requestId>`.
4. Verify: `openclaw nodes status` or `openclaw gateway call node.list`.

---

## Key Insights for Auto-Deployment

### Runtime & Environment

- **Node is the only recommended runtime** across all platforms. Bun is explicitly excluded due to WhatsApp/Telegram bugs.
- **Node 24 recommended; Node 22 LTS (22.14+) still works** for compatibility.
- **State directory:** `OPENCLAW_STATE_DIR` controls where `~/.openclaw` lives. Always use a local non-cloud-synced path.
- **Auth:** Gateway requires either `gateway.auth.token` (recommended) or `gateway.auth.password`. Tokens can be set via `OPENCLAW_GATEWAY_TOKEN` env var (preferred for secrets — keeps them out of `openclaw.json`).

### Persistence Architecture

```
Host filesystem ─┬─ ~/.openclaw/          → agent configs, auth-profiles.json, sessions
                 └─ ~/.openclaw/workspace → agent workspace files
```

In Docker deployments, these directories MUST be mounted from the host. Containers are ephemeral — everything written inside the container is lost on restart.

### Service Installation Commands (all platforms)

```bash
# Recommended (wizard)
openclaw onboard --install-daemon

# Direct
openclaw gateway install

# Interactive configure
openclaw configure  # → select "Gateway service"

# Repair/migrate
openclaw doctor
```

### Service Manager by Platform

| Platform | Service Manager | Service Name |
|----------|----------------|--------------|
| macOS | LaunchAgent | `ai.openclaw.gateway` (or `ai.openclaw.<profile>`) |
| Linux / WSL2 | systemd user service | `openclaw-gateway[-<profile>].service` |
| Native Windows | Scheduled Task (primary), Startup folder (fallback) | `OpenClaw Gateway` |

### Network & Discovery

- **Gateway default port:** `18789`.
- **Discovery:** `_openclaw-gw._tcp` via Bonjour/mDNS on LAN; Wide-Area Bonjour via Tailscale split DNS for cross-network.
- **Tailscale:** Preferred for cross-network. Use `openclaw gateway --tailscale serve` for `wss://` endpoint (required for Android remote pairing).
- **Cloud VMs:** Bind to `lan` (`0.0.0.0`) or `auto`; access via SSH tunnel from laptop. Never expose gateway port directly to internet without auth.
- **Fly.io:** Uses `--bind lan` internally; Fly's proxy handles HTTPS externally.

### Cloud Deployment Cost Summary

| Provider | Minimum Config | Monthly Cost |
|----------|---------------|-------------|
| Hetzner | VPS ~$5 | ~$5 |
| GCP | e2-small | ~$12 |
| GCP | e2-medium | ~$25 |
| Fly.io | shared-cpu-2x, 2GB | ~$10-15 |
| Azure | Standard_B2as_v2 + Bastion Standard | ~$195 (deallocate to save) |

### Dockerfile Compatibility

- Tested on GCP (Debian), Hetzner (Ubuntu/Debian), Fly.io (x86).
- Fly.io explicitly x86 only (not ARM).
- Docker build OOM is a common failure mode on small VMs (e2-micro, ~$5 VPS) — use e2-small or larger.
- For custom images that need binaries baked in (e.g., for `system.run` tools), see the Docker VM Runtime guide.

### Security Notes

- **State dir on macOS:** Never use iCloud or cloud-synced paths — file-lock/sync races can corrupt sessions and credentials.
- **Azure:** SSH only via Bastion; NSG denies all direct internet SSH.
- **Hetzner:** Use dedicated VPS with dedicated accounts; no personal browser/password profiles on the host.
- **Fly.io private deployment:** No public IPs; hidden from Shodan/Censys; access via proxy, WireGuard, or SSH only.
- **`system.run` on macOS:** Controlled by `~/.openclaw/exec-approvals.json` with allowlist patterns. Raw shell syntax (`&&`, `||`, `;`, `|`, backticks, `$`, etc.) triggers approval prompts.
- **Environment overrides** in `system.run` are filtered (drops `PATH`, `DYLD_*`, `LD_*`, `NODE_OPTIONS`, `PYTHON*`, `PERL*`, `RUBYOPT`, `SHELLOPTS`, `PS4`).

### Common Auto-Deployment Checklist

- [ ] Node 24 (or Node 22 LTS) installed
- [ ] `npm i -g openclaw@latest` or `git clone` + build
- [ ] `OPENCLAW_STATE_DIR` set to persistent host path
- [ ] `OPENCLAW_GATEWAY_TOKEN` set (strong secret via env var)
- [ ] Gateway service installed (`openclaw onboard --install-daemon`)
- [ ] Service running: `openclaw gateway status`
- [ ] SSH tunnel or secure `wss://` endpoint configured for remote access
- [ ] Firewall/NSG restricts gateway port to trusted sources
- [ ] Mobile node pairing approved: `openclaw devices approve <requestId>`
- [ ] Provider credentials (API keys, OAuth tokens) set via env vars or `openclaw config set`
- [ ] Update mechanism: `npm i -g openclaw@latest` (Linux/macOS) or `fly deploy` (Fly.io)
