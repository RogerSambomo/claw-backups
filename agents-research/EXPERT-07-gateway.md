# Expert 07: OpenClaw Gateway

## Configuration Options
- **Port resolution order**: `--port` CLI flag → `OPENCLAW_GATEWAY_PORT` env var → `gateway.port` config key → default `18789`.
- **Bind mode**: CLI/override → `gateway.bind` config → default `loopback`.
- **Authentication**: By default `gateway.auth.token` / `gateway.auth.password` (or env `OPENCLAW_GATEWAY_TOKEN` / `OPENCLAW_GATEWAY_PASSWORD`). For reverse‑proxy setups use `gateway.auth.mode: "trusted-proxy"`.
- **Reload behavior**: `gateway.reload.mode` can be `off`, `hot`, `restart`, or `hybrid` (default). `hybrid` hot‑applies safe changes and restarts on required ones. Config reload watches the active config file path (profile/state defaults or `OPENCLAW_CONFIG_PATH`).
- **Secrets management**: Uses the SecretRef contract. `openclaw secrets reload` applies runtime snapshots; `secrets apply` enforces target/path rules and auth‑profile behavior.
- **Environment shortcuts**: `OPENCLAW_CONFIG_PATH`, `OPENCLAW_STATE_DIR`, `OPENCLAW_GATEWAY_PORT`, `OPENCLAW_GATEWAY_TOKEN`, `OPENCLAW_GATEWAY_PASSWORD`.

## Commands
| Command | Purpose |
|---------|---------|
| `openclaw gateway start` (or `openclaw gateway --port <port>`) | Launch the Gateway process. |
| `openclaw gateway status` | Basic health probe (`Runtime: running`, `RPC probe: ok`). |
| `openclaw gateway status --deep` | System‑level service scan (systemd/launchd). |
| `openclaw gateway status --json` | Machine‑readable status output. |
| `openclaw gateway restart` | Restart the running Gateway (uses reload mode). |
| `openclaw gateway stop` | Gracefully stop the service. |
| `openclaw gateway install` | Install a supervised service (launchd, systemd user, system, Windows task). |
| `openclaw secrets reload` | Reload secret snapshots at runtime. |
| `openclaw logs --follow` | Tail the Gateway logs. |
| `openclaw doctor` | Audit and repair service config drift. |
| `openclaw channels status --probe` | Live per‑account channel health check. |
| `openclaw health` | General health endpoint probe. |
| `openclaw gateway probe` | Detect multiple reachable gateways on the host. |
| `openclaw --dev setup` / `openclaw --dev gateway --allow-unconfigured` | Quick dev‑profile launch (isolated state, base port `19001`). |

## Security
- **Auth token/password** is mandatory for non‑loopback binds. Shared‑secret setups use the token/password fields or the corresponding env vars.
- **Remote access** is recommended via Tailscale or a VPN. SSH tunnels can be used (`ssh -N -L 18789:127.0.0.1:18789 user@host`) but **do not bypass** Gateway auth – clients must still send the token/password.
- **Secrets contract** ensures secret references are validated at load time; `secrets apply` enforces strict path rules.
- **Trusted‑proxy mode** (`gateway.auth.mode: "trusted-proxy"`) allows reverse‑proxy front‑ends to forward authentication without exposing the token to the public internet.
- **Port binding** defaults to loopback; exposing the port externally requires explicit auth configuration.

## Service Management
- **macOS (launchd)**
  ```bash
  openclaw gateway install          # creates ai.openclaw.gateway agent (or profile‑named)
  openclaw gateway status
  openclaw gateway restart
  openclaw gateway stop
  ```
- **Linux (systemd user unit)**
  ```bash
  openclaw gateway install
  systemctl --user enable --now openclaw-gateway.service
  openclaw gateway status
  # enable lingering for persistence after logout
  sudo loginctl enable-linger <user>
  ```
- **Linux (systemd system unit)**
  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable --now openclaw-gateway.service
  ```
- **Windows (native)**
  ```powershell
  openclaw gateway install   # creates a Scheduled Task named "OpenClaw Gateway"
  openclaw gateway status --json
  openclaw gateway restart
  openclaw gateway stop
  ```
- **Supervised runs**: The `install` command sets up a watchdog (launchd, systemd, or Windows task) that restarts the process on failure. `openclaw doctor` can audit and repair the supervision configuration.
- **Multiple gateways on one host**: Use unique ports, config paths (`OPENCLAW_CONFIG_PATH`), state dirs (`OPENCLAW_STATE_DIR`), and workspace defaults. Example:
  ```bash
  OPENCLAW_CONFIG_PATH=~/.openclaw/a.json OPENCLAW_STATE_DIR=~/.openclaw-a openclaw gateway --port 19001
  OPENCLAW_CONFIG_PATH=~/.openclaw/b.json OPENCLAW_STATE_DIR=~/.openclaw-b openclaw gateway --port 19002
  ```

## Key Insights for Auto‑Deployment
1. **Programmatic start** – `openclaw gateway --port $PORT --verbose` can be invoked from CI/CD pipelines. Use env vars for port and auth token to avoid hard‑coding.
2. **Hot‑reload strategy** – Keep `gateway.reload.mode=hybrid` (default). After a config change, run `openclaw gateway status` to verify the snapshot; the process will hot‑apply safe changes and restart only when required.
3. **Service installation automation** – Detect OS via `$OSTYPE` and run the appropriate `install` sub‑command. For Linux user units, add `systemctl --user enable --now openclaw-gateway.service`; for macOS, rely on `launchctl load` via the `install` script.
4. **Secure remote access** – Deploy a Tailscale node, then forward the local gateway port. Clients still authenticate with the token, preserving security boundaries.
5. **Port conflict handling** – Before starting, probe the desired port (`lsof -iTCP:$PORT -sTCP:LISTEN`). If in use, either pick a different port or stop the existing gateway (`openclaw gateway stop`).
6. **Monitoring** – Use `openclaw gateway status --json` and pipe to a monitoring system (Prometheus exporter, Grafana). The JSON includes `uptimeMs`, `presence`, `health`, and `stateVersion`.
7. **Multiple‑gateway isolation** – When isolation is required (e.g., rescue bot), give each instance its own `OPENCLAW_STATE_DIR` and `OPENCLAW_CONFIG_PATH`. This prevents cross‑contamination of secrets and agents.

---
*Report generated automatically from the OpenClaw Gateway documentation.*