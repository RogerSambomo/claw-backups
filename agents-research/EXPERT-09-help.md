# Expert 09: OpenClaw Help/Troubleshooting

## Common Issues

### 1. No Replies (Channels Up, Nothing Answers)
- **Root causes:** Pairing pending, group mention gating, channel allowlist mismatch
- **Log signatures:**
  - `drop guild message (mention required)` → group mention blocked message
  - `pairing request` → sender unapproved, waiting for DM pairing approval
  - `blocked` / `allowlist` → sender/channel filtered by policy
- **Debug command:** `openclaw pairing list --channel <channel> [--account <id>]`

### 2. Gateway Will Not Start / Service Not Running
- **Root causes:**
  - Missing `gateway.mode=local` in config (or clobbered config file)
  - Non-loopback bind without valid auth (token/password or trusted-proxy)
  - Port conflict (`EADDRINUSE`, "another gateway instance already listening")
  - Multiple stale gateway services (launchd/systemd/schtasks)
- **Log signatures:**
  - `Gateway start blocked: set gateway.mode=local` → local mode not enabled
  - `refusing to bind gateway ... without auth` → non-loopback bind without auth
  - `another gateway instance is already listening` → port conflict

### 3. Dashboard / Control UI Cannot Connect
- **Root causes:** Wrong URL/port, auth mode mismatch, HTTP without device identity, origin not allowed
- **Log signatures:**
  - `device identity required` → non-secure context cannot complete device auth
  - `origin not allowed` → browser `Origin` not in `gateway.controlUi.allowedOrigins`
  - `AUTH_TOKEN_MISMATCH` with `canRetryWithDeviceToken=true` → token drift
  - `too many failed authentication attempts (retry later)` → browser origin locked out
  - `gateway connect failed:` → wrong host/port/url

### 4. Channel Connected But Messages Not Flowing
- **Root causes:** Mention gating, pairing pending, missing channel API scopes/permissions
- **Log signatures:**
  - `mention required` → group mention policy blocking
  - `pairing` / `pending` → DM sender not approved
  - `missing_scope`, `not_in_channel`, `Forbidden`, `401/403` → channel auth issue

### 5. Cron or Heartbeat Did Not Fire / Did Not Deliver
- **Root causes:** Cron scheduler disabled, outside quiet-hours, accountId unknown
- **Log signatures:**
  - `cron: scheduler disabled; jobs will not run automatically` → cron disabled
  - `heartbeat skipped` with `reason=quiet-hours` → outside active hours
  - `heartbeat skipped` with `reason=empty-heartbeat-file` → `HEARTBEAT.md` is blank/only headers
  - `heartbeat skipped` with `reason=no-tasks-due` → no tasks due in `HEARTBEAT.md`
  - `heartbeat: unknown accountId` → invalid heartbeat target account

### 6. Node Paired But Tools Fail (Camera, Canvas, Screen Exec)
- **Root causes:** App not in foreground, missing OS permissions, exec approval pending, command not on allowlist
- **Log signatures:**
  - `NODE_BACKGROUND_UNAVAILABLE` → bring node app to foreground
  - `*_PERMISSION_REQUIRED` → OS permission denied/missing
  - `SYSTEM_RUN_DENIED: approval required` → exec approval pending
  - `SYSTEM_RUN_DENIED: allowlist miss` → command not on exec allowlist

### 7. Browser Tool Fails
- **Root causes:** Browser plugin excluded by `plugins.allow`, Chrome not installed, CDP URL misconfigured, remote CDP unreachable
- **Log signatures:**
  - `unknown command "browser"` → `plugins.allow` excludes `browser`
  - `Failed to start Chrome CDP on port` → local browser launch failed
  - `browser.executablePath not found` → configured binary path wrong
  - `browser.cdpUrl must be http(s) or ws(s)` → unsupported scheme (e.g., `file:`)
  - `No Chrome tabs found for profile="user"` → Chrome MCP attach profile has no open tabs
  - `Remote CDP for profile "<name>" is not reachable` → remote CDP unreachable

### 8. Exec Suddenly Asks for Approval
- **Root cause:** `tools.exec.host` changed, `security` tightened, or `ask` mode changed
- **Restore default no-approval behavior:**
  ```bash
  openclaw config set tools.exec.host gateway
  openclaw config set tools.exec.security full
  openclaw config set tools.exec.ask off
  openclaw gateway restart
  ```

### 9. Plugin Install Fails with Missing `openclaw.extensions`
- **Fix:** Add `openclaw.extensions` array to `package.json` pointing at built runtime files:
  ```json
  {
    "openclaw": { "extensions": ["./dist/index.js"] }
  }
  ```
  Then re-run `openclaw plugins install <package>`.

### 10. Anthropic Long Context 429
- **Error:** `HTTP 429: rate_limit_error: Extra usage is required for long context requests`
- **Fix options:**
  1. Disable `context1m` for that model
  2. Use an eligible Anthropic credential or API key
  3. Configure fallback models

### 11. Post-Upgrade Breakage
- Common after upgrades due to **config drift** or **stricter defaults enforcement**
- Three main areas:
  1. Auth/URL override behavior changed
  2. Bind and auth guardrails stricter (non-loopback binds need valid auth)
  3. Pairing/device identity state changed

---

## Recovery Procedures

### 1. Quick Triage (First 60 Seconds)
Run this exact ladder in order:
```bash
openclaw status
openclaw status --all
openclaw gateway probe
openclaw gateway status
openclaw doctor
openclaw channels status --probe
openclaw logs --follow
```

### 2. `openclaw doctor` — The Primary Repair Tool
This is the **main automated repair command**. It:
- Fixes stale config/state
- Auto-migrates legacy config keys (e.g., `talk.*`, `routing.*`, `agent.*`, `browser.*`, plugin manifest keys)
- Migrates legacy on-disk state (sessions, agent dir, WhatsApp auth)
- Cleans stale session lock files
- Repairs sandbox Docker images
- Detects and repairs supervisor configs (launchd/systemd/schtasks)
- Detects extra/stale gateway services
- Offers gateway restart when unhealthy

**Modes:**
| Flag | Behavior |
|------|----------|
| `openclaw doctor` | Interactive, prompts for repairs |
| `openclaw doctor --yes` | Accept defaults without prompting |
| `openclaw doctor --repair` | Apply recommended repairs without prompting |
| `openclaw doctor --repair --force` | Apply repairs including overwriting custom supervisor configs |
| `openclaw doctor --non-interactive` | Safe migrations only (config normalization, state moves; no restarts) |
| `openclaw doctor --deep` | Also scan system services for extra gateway installs |

### 3. Gateway Service Reinstall
If config and runtime disagree after doctor:
```bash
openclaw gateway install --force
openclaw gateway restart
```

### 4. Stale Lock File Cleanup
```bash
openclaw doctor --fix   # removes stale lock files automatically
```

### 5. Token Drift Recovery
```bash
openclaw devices list
openclaw devices approve <requestId>    # approve pending device
openclaw devices rotate --scope ...    # rotate per-device token
openclaw devices revoke <deviceId>     # revoke stale device
```

### 6. Auth Device Token Rotation
```bash
openclaw devices list
openclaw devices rotate <deviceId>
```

### 7. Browser Stale State (Attach-Only / Remote CDP)
```bash
openclaw browser stop --browser-profile <name>
```

### 8. Missing Local Chrome for MCP Attach
```bash
# Enable Chrome remote debugging: chrome://inspect/#remote-debugging
# Then approve the first attach consent prompt in the browser
openclaw browser start --browser-profile openclaw
openclaw browser profiles
```

---

## Reset Commands

### 1. Full Dev Profile Reset (Fresh Start)
```bash
pnpm gateway:dev:reset
# Or:
OPENCLAW_PROFILE=dev openclaw gateway --dev --reset
```
Wipes config, credentials, sessions, and dev workspace, then recreates default dev setup.

### 2. Restore Default No-Approval Exec Behavior
```bash
openclaw config set tools.exec.host gateway
openclaw config set tools.exec.security full
openclaw config set tools.exec.ask off
openclaw gateway restart
```

### 3. Config-Level Reset via Doctor
```bash
openclaw doctor --repair    # normalize legacy config, migrate state
```

### 4. Token Auth Repair
```bash
openclaw doctor --generate-gateway-token   # generate token when no SecretRef configured
```

### 5. Shell Completion Reinstall
```bash
openclaw completion --write-state    # regenerate completion cache manually
```

### 6. Reset Heartbeat State
Heartbeat skip reasons can be cleared by editing `HEARTBEAT.md`:
- Remove blank lines / markdown headers causing `empty-heartbeat-file` skip
- Mark tasks as due to clear `no-tasks-due` skip

---

## Key Insights for Auto-Deployment

### 1. `openclaw doctor` is the Swiss Army Knife
For **auto-deployment**, the most important command is `openclaw doctor --repair --force`:
- Runs all safe migrations automatically
- Applies config normalization without prompts
- Repairs service metadata
- Cleans stale locks
- Handles legacy state migrations idempotently

### 2. The First-60-Seconds Ladder is Machine-Executable
All 7 commands in the triage ladder produce structured, machine-parseable output:
```bash
openclaw status              # → exit 0 + channel summary
openclaw status --all        # → full shareable report
openclaw gateway probe       # → JSON with Reachable/RPC probe fields
openclaw gateway status      # → Runtime + RPC probe status
openclaw doctor              # → blocking/non-blocking issues
openclaw channels status --probe   # → per-account transport state
openclaw logs --follow       # → live tail, JSON or pretty
```
A script can parse `Runtime: running`, `RPC probe: ok`, and `works`/`audit ok` strings to determine health.

### 3. Doctor Auto-Runs Migrations on Gateway Startup
The Gateway **auto-runs doctor migrations on startup** when it detects legacy config. This means:
- Config is self-healing on upgrade
- Auto-deployment doesn't need to manually run doctor after upgrade (though `--repair` is still safe to run)

### 4. Log Files are Structured JSONL
File logs at `/tmp/openclaw/openclaw-YYYY-MM-DD.log` are JSONL — easy to parse for automation:
- Set `logging.level: debug` or `trace` via `OPENCLAW_LOG_LEVEL` env var for more detail
- Use `openclaw logs --json --follow` for machine-readable live tail
- Tool summary redaction is console-only; file logs retain full detail

### 5. Config Migration Mappings for Auto-Upgrade
Doctor handles ~25+ legacy config key migrations. Key ones for auto-deployment:
| Legacy Key | → New Key |
|-----------|-----------|
| `routing.allowFrom` | `channels.whatsapp.allowFrom` |
| `routing.groupChat.requireMention` | `channels.*.groups.*.requireMention` |
| `talk.voiceId` / `talk.modelId` | `talk.provider` + `talk.providers.<provider>` |
| `channels.discord.voice.tts.openai` | `channels.discord.voice.tts.providers.openai` |
| `browser.ssrfPolicy.allowPrivateNetwork` | `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork` |
| `browser.profiles.*.driver: "extension"` | `"existing-session"` |
| `identity` | `agents.list[].identity` |
| `agent.*` | `agents.defaults` + `tools.*` |

### 6. Env Var Overrides for Automation
For auto-deployment, use env vars over config edits:
- `OPENCLAW_LOG_LEVEL=debug` → raise verbosity without editing config
- `OPENCLAW_PROFILE=dev` → isolate state for testing
- `OPENCLAW_STATE_DIR`, `OPENCLAW_HOME`, `OPENCLAW_CONFIG_PATH` → control paths from env
- `OPENCLAW_DIAGNOSTICS=telegram.http` → targeted debug flags without full debug level

### 7. Health Signals for Automation
Parse these exact strings to determine state:
| Check | Healthy Signal | Unhealthy Signal |
|-------|---------------|-----------------|
| `openclaw gateway status` | `Runtime: running` | `Runtime: stopped` |
| `openclaw gateway probe` | `Reachable: yes` / `RPC probe: ok` | `RPC probe: failed` |
| `openclaw doctor` | no blocking errors | `blocking` items present |
| `openclaw channels status --probe` | `works` / `audit ok` | channel not reachable |

### 8. Supervisor Config Audit
`openclaw doctor --repair` rewrites supervisor configs (systemd/launchd/schtasks) to current defaults. In auto-deployment:
- Run with `--repair --force` to overwrite custom supervisor configs
- Token SecretRef is validated but never persisted as plaintext in service environment

### 9. Pairing and Device Approvals
For automated channel recovery:
```bash
openclaw pairing list --channel <channel> [--account <id>]
# Approve pending: look for "pairing request" in logs
openclaw devices list   # for device-level approvals
```
Pairing state survives restarts but can drift after upgrades — re-check after major version upgrades.

### 10. Browser Tool Recovery
Browser failures are often recoverable without restart:
```bash
openclaw browser stop --browser-profile <name>   # release stale CDP state
openclaw browser start --browser-profile openclaw  # restart
```
This avoids a full gateway restart, critical for zero-downtime auto-deployment.
