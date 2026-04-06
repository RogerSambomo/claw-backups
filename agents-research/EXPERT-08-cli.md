# Expert 08: OpenClaw CLI

## Essential Commands

### Gateway Lifecycle
```
openclaw gateway run              # Start gateway (WS server)
openclaw gateway start            # Start as background service
openclaw gateway stop             # Stop background service
openclaw gateway restart          # Restart service
openclaw gateway status           # Probe gateway RPC health
openclaw gateway install          # Install as system service (launchd/systemd/schtasks)
openclaw gateway uninstall        # Remove system service
```

### Health & Diagnostics
```
openclaw status [--deep]          # Session health + recent recipients; --deep probes gateway live
openclaw health [--verbose]       # Fetch gateway health; --verbose forces live probe
openclaw doctor [--repair]        # Health checks + auto-fix; --deep scans for extra installs
openclaw logs [--follow]          # Tail gateway file logs via RPC
openclaw system event --text <t>  # Enqueue system heartbeat event
```

### Config Management
```
openclaw config get <path>                    # Print a config value (dot/bracket path)
openclaw config set <path> <value>            # Set value (JSON5 or string)
openclaw config set <path> --ref-provider X --ref-source Y --ref-id Z  # Store as SecretRef
openclaw config set --batch-json '<json>'    # Batch mode
openclaw config set --dry-run                 # Validate without writing
openclaw config unset <path>                  # Remove a value
openclaw config file                          # Print active config file path
openclaw config schema                        # Print JSON schema for openclaw.json
openclaw config validate [--json]             # Validate config against schema
```

### Model Configuration
```
openclaw models list [--all|--local|--provider <name>]   # List available models
openclaw models status [--probe]                         # Check auth + model status
openclaw models set <model>                              # Set primary chat model
openclaw models set-image <model>                        # Set primary image model
openclaw models scan [--set-default] [--set-image]      # Scan for available models
openclaw models auth add                                 # Interactive auth helper
openclaw models auth login --provider <name>            # OAuth login flow
openclaw models auth paste-token --provider <name>      # Paste API token
openclaw models auth order get|set|clear                # Auth profile priority order
```

---

## Setup Commands

### `openclaw setup` — Initialize Config + Workspace
The primary automated setup command. Creates config and workspace if absent.

```bash
openclaw setup \
  --workspace <dir>                    # Agent workspace (default ~/.openclaw/workspace)
  --wizard                             # Run onboarding wizard
  --non-interactive                    # Run without prompts
  --mode <local|remote>                # Onboard mode
  --remote-url <url>                   # Remote gateway URL
  --remote-token <token>               # Remote gateway token
```

**Auto-triggers onboarding** when any onboarding flag is present (`--non-interactive`, `--mode`, `--remote-url`, `--remote-token`).

---

### `openclaw onboard` — Full Interactive Onboarding
The comprehensive onboarding command covering gateway, workspace, models, channels, and skills.

```bash
openclaw onboard \
  --workspace <dir>
  --reset                              # Reset config+creds+sessions before onboarding
  --reset-scope <config|config+creds+sessions|full>  # What to reset (default: config+creds+sessions)
  --non-interactive                    # No prompts
  --mode <local|remote>
  --flow <quickstart|advanced|manual>
  --auth-choice <provider>             # See supported auth choices below
  --secret-input-mode <plaintext|ref>  # Store keys as plaintext or SecretRef env var
  --anthropic-api-key <key>
  --openai-api-key <key>
  --mistral-api-key <key>
  --openrouter-api-key <key>
  --ai-gateway-api-key <key>
  --moonshot-api-key <key>
  --gemini-api-key <key>
  --zai-api-key <key>
  --minimax-api-key <key>
  --custom-base-url <url>              # For --auth-choice custom-api-key
  --custom-model-id <id>               # For --auth-choice custom-api-key
  --custom-api-key <key>               # For --auth-choice custom-api-key
  --gateway-port <port>
  --gateway-bind <loopback|lan|tailnet|auto|custom>
  --gateway-auth <token|password>
  --gateway-token <token>
  --gateway-token-ref-env <name>       # Store gateway.auth.token as SecretRef (env var)
  --gateway-password <password>
  --remote-url <url>
  --remote-token <token>
  --tailscale <off|serve|funnel>
  --install-daemon                     # Install gateway as system service
  --no-install-daemon / --skip-daemon
  --daemon-runtime <node|bun>         # Node recommended; bun not recommended (WA/TG bugs)
  --skip-channels                      # Skip channel setup
  --skip-skills                        # Skip skills setup
  --skip-search                        # Skip search setup
  --skip-health                        # Skip health checks
  --skip-ui                            # Skip UI setup
  --node-manager <npm|pnpm|bun>       # Skill node manager (pnpm recommended)
  --json
```

**Supported `--auth-choice` values:**
`chutes`, `deepseek-api-key`, `openai-codex`, `openai-api-key`, `openrouter-api-key`, `kilocode-api-key`, `litellm-api-key`, `ai-gateway-api-key`, `cloudflare-ai-gateway-api-key`, `moonshot-api-key`, `moonshot-api-key-cn`, `kimi-code-api-key`, `synthetic-api-key`, `venice-api-key`, `together-api-key`, `huggingface-api-key`, `apiKey`, `gemini-api-key`, `google-gemini-cli`, `zai-api-key`, `zai-coding-global`, `zai-coding-cn`, `zai-global`, `zai-cn`, `xiaomi-api-key`, `minimax-global-oauth`, `minimax-global-api`, `minimax-cn-oauth`, `minimax-cn-api`, `opencode-zen`, `opencode-go`, `github-copilot`, `copilot-proxy`, `xai-api-key`, `mistral-api-key`, `volcengine-api-key`, `byteplus-api-key`, `qianfan-api-key`, `qwen-standard-api-key-cn`, `qwen-standard-api-key`, `qwen-api-key-cn`, `qwen-api-key`, `modelstudio-standard-api-key-cn`, `modelstudio-standard-api-key`, `modelstudio-api-key-cn`, `modelstudio-api-key`, `custom-api-key`, `skip`

---

### `openclaw configure` — Interactive Configuration Wizard
```bash
openclaw configure --section <section>   # Limit wizard to specific sections
```

---

### `openclaw update` — Update the CLI
```bash
openclaw update                            # Update CLI to latest
openclaw update --channel <stable|beta|dev>
openclaw update --tag <version|spec>
openclaw update --dry-run
openclaw update --yes
openclaw update status [--json]
openclaw update wizard
```

`openclaw --update` is shorthand for `openclaw update`.

---

## Configuration Commands

### `openclaw channels` — Chat Channel Management
```bash
openclaw channels list [--json]
openclaw channels status [--probe] [--json]
openclaw channels add --channel <name> --account <id> --name <label> --token <token>
openclaw channels remove --channel <name> --account <id> [--delete]
openclaw channels login --channel <name> --account <id>
openclaw channels logout --channel <name> --account <id>
openclaw channels logs [--channel <name>] [--lines <n>] [--json]
openclaw channels capabilities --channel <name> --account <id>
openclaw channels resolve <entries...> --channel <name> --account <id>
```

Supported channels: `whatsapp`, `telegram`, `discord`, `googlechat`, `slack`, `mattermost` (plugin), `signal`, `imessage`, `msteams`

---

### `openclaw skills` — Skill Management
```bash
openclaw skills search [query...] [--limit <n>] [--json]
openclaw skills install <slug> [--version <v>] [--force]
openclaw skills update <slug|--all>
openclaw skills list [--json] [--verbose]
openclaw skills info <name> [--json]
openclaw skills check [--json] [--eligible]
```

---

### `openclaw plugins` — Plugin Management
```bash
openclaw plugins list [--json]
openclaw plugins inspect <id>
openclaw plugins install <path|.tgz|npm-spec|plugin@marketplace> [--force]
openclaw plugins marketplace list <marketplace>
openclaw plugins enable <id>
openclaw plugins disable <id>
openclaw plugins doctor
```

---

### `openclaw backup` — Backup Management
```bash
openclaw backup create [--output <path>] [--verify] [--only-config] [--no-include-workspace] [--dry-run] [--json]
openclaw backup verify <archive> [--json]
```

---

### `openclaw secrets` — Secrets Management
```bash
openclaw secrets reload [--url <url>] [--token <token>] [--timeout <ms>]
openclaw secrets audit [--check] [--allow-exec] [--json]
openclaw secrets configure [--apply] [--yes] [--plan-out <path>] [--json]
openclaw secrets apply --from <path> [--dry-run] [--allow-exec]
```

---

### `openclaw security` — Security Audit
```bash
openclaw security audit           # Audit config + local state
openclaw security audit --deep   # Live gateway probe
openclaw security audit --fix    # Tighten safe defaults + permissions
```

---

### `openclaw memory` — Vector Memory
```bash
openclaw memory status [--deep]   # Show index stats; --fix repairs stale artifacts
openclaw memory index             # Reindex memory files
openclaw memory search "<query>"  # Semantic search over memory
openclaw memory promote           # Rank + promote short-term recalls to MEMORY.md
```

---

## Key Insights for Auto-Deployment

### 1. Non-Interactive Setup is Fully Supported
Every setup command has `--non-interactive` or equivalent flags. The main entry points are:
- `openclaw setup --non-interactive --mode local` (minimal local setup)
- `openclaw onboard --non-interactive --auth-choice <provider> --openai-api-key <key>` (full unattended onboarding)

### 2. Fully Automated Single-Line Setup Pattern
```bash
openclaw onboard \
  --non-interactive \
  --mode local \
  --flow quickstart \
  --auth-choice openai-api-key \
  --openai-api-key "$OPENAI_API_KEY" \
  --install-daemon \
  --daemon-runtime node \
  --skip-channels \
  --skip-skills
```

### 3. Config is JSON-Based and Writable via CLI
`openclaw config set` supports batch JSON, SecretRef building, and dry-run validation — no manual file editing needed.

### 4. Gateway Service Installation
```bash
openclaw gateway install --port 18789 --runtime node --token <token> [--force] [--json]
openclaw gateway start
openclaw gateway status
```

### 5. Secrets Can Be Stored as References (Not Plaintext)
Use `--secret-input-mode ref` during onboard, or:
```bash
openclaw config set gateway.auth.token --ref-provider env --ref-source env --ref-id OPENCLAW_GATEWAY_TOKEN
```

### 6. Remote Gateway Mode
For remote deployments:
```bash
openclaw setup --non-interactive --mode remote --remote-url <url> --remote-token <token>
```

### 7. Node Manager for Skills
When installing skills that need npm packages, specify the node manager:
```bash
openclaw onboard --node-manager pnpm  # pnpm recommended over npm
```

### 8. `openclaw --update` Works as Update Shorthand
For CI/scripts: `openclaw --update` is equivalent to `openclaw update`.

### 9. State Isolation for Multi-Environment Deployments
Use profiles to isolate state:
- `--dev` → `~/.openclaw-dev`
- `--profile <name>` → `~/.openclaw-<name>`
- `--container <name>` → target a named container

### 10. Doctor for Automated Repair
```bash
openclaw doctor --yes --repair  # Auto-fix detected issues
```

### 11. JSON Output for Scripting
Most commands support `--json` for machine-readable output — use this in automation scripts.

### 12. Priority Auth Order for Multi-Provider Setups
```bash
openclaw models auth order set --provider openai --agent main profile1 profile2
```

### 13. Tailscale Integration
```bash
openclaw onboard --tailscale <off|serve|funnel>
openclaw dns setup --domain <domain> --apply
```

### 14. Cron Jobs for Automation
```bash
openclaw cron add --name "backup" --every 1d --system-event --text "backup"
openclaw cron add --name "report" --cron "0 9 * * *" --message --target <dest> --message "Daily report"
```

### 15. Reset/Uninstall for Clean Re-provisioning
```bash
openclaw reset --scope full --yes --non-interactive   # Full reset, keeps CLI
openclaw uninstall --all --yes --non-interactive      # Remove everything
```
