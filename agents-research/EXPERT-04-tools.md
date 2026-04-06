# Expert 04: OpenClaw Tools

*Source: https://docs.openclaw.ai/tools — fetched 2026-04-06*

---

## Available Tools

OpenClaw ships **built-in tools** (no plugin required) plus **plugin-provided tools**.

### Built-in Tool Summary

| Tool | What it does |
|------|-------------|
| `exec` / `process` | Run shell commands; foreground, background, PTY, send-keys |
| `code_execution` | Sandboxed remote Python analysis |
| `browser` | Control a Chromium browser (navigate, click, screenshot) |
| `web_search` / `x_search` / `web_fetch` | Search web, search X posts, fetch page content |
| `read` / `write` / `edit` | File I/O in the workspace |
| `apply_patch` | Multi-hunk structured file patches |
| `message` | Send messages across all channels |
| `canvas` | Drive node Canvas (present, eval, snapshot) |
| `nodes` | Discover and target paired devices |
| `cron` / `gateway` | Scheduled jobs; gateway inspect/patch/restart/update |
| `image` / `image_generate` | Analyze or generate images |
| `music_generate` | Generate music tracks |
| `video_generate` | Generate videos |
| `tts` | One-shot text-to-speech |
| `sessions_*` / `subagents` / `agents_list` | Session management and sub-agent orchestration |
| `session_status` | Lightweight `/status` readback; per-session model override |

### Plugin System

Plugins can register: channels, model providers, tools, skills, speech, realtime transcription, realtime voice, media understanding, image generation, video generation, web fetch, and web search.

- **Core bundled plugins** (enabled by default): `anthropic`, `google`, `openai`, `openrouter`, `minimax`, `mistral`, `kimi`, `moonshot`, `qwen`, and many more model providers; `elevenlabs`/`microsoft` for speech; `browser` for automation.
- **Installable npm plugins**: Matrix, Microsoft Teams, Nostr, Voice Call, Zalo, etc.
- **Install via**: `openclaw plugins install <pkg>` or `/plugin install clawhub:<pkg>`
- **Plugin slots** (exclusive): `memory` (default `memory-core`; swap for `memory-lancedb`), `contextEngine`

### Tool Configuration

- `tools.allow` / `tools.deny` — per-tool allowlists and blocklists (deny wins)
- `tools.profile` — base preset: `full`, `coding`, `messaging`, `minimal`
- `tools.byProvider` — per-model-provider tool restrictions
- Tool groups available in allow/deny:

| Group | Includes |
|-------|---------|
| `group:runtime` | exec, process, code_execution |
| `group:fs` | read, write, edit, apply_patch |
| `group:sessions` | sessions_list/history/send/spawn/yield, subagents, session_status |
| `group:memory` | memory_search, memory_get |
| `group:web` | web_search, x_search, web_fetch |
| `group:ui` | browser, canvas |
| `group:automation` | cron, gateway |
| `group:messaging` | message |
| `group:nodes` | nodes |
| `group:agents` | agents_list |
| `group:media` | image, image_generate, music_generate, video_generate, tts |
| `group:openclaw` | All built-in OpenClaw tools (excludes plugins) |

---

## Browser Automation

OpenClaw runs a **dedicated Chrome/Brave/Edge/Chromium profile** controlled by the agent, isolated from the user's personal browser.

### Profiles

- **`openclaw`** (default): managed, isolated browser — no extension required, separate user data dir
- **`user`**: attaches to the user's real signed-in Chrome via Chrome DevTools MCP
- **Custom profiles**: `work`, `remote`, `brave`, etc. — named configs with own CDP port or remote URL
- Multi-profile support with per-profile color tinting

### Key Capabilities

- **Navigate, click, type, hover, drag, select, scroll**
- **Snapshots** (AI-format with numeric refs, ARIA tree, role-based)
- **Screenshots** (full page, element via CSS selector or ref, existing-session)
- **PDF export** (managed browser only)
- **Tab control** (list/open/focus/close)
- **Downloads / file upload**
- **Dialog handling** (accept/dismiss)
- **Network interception**: response body capture (`/response/body`), request filtering
- **Console/error inspection**
- **Tracing** (start/stop)
- **State**: cookies, local/session storage, credentials, geolocation, timezone, locale, headers, media type, device emulation
- **Offline mode**
- **Evaluate JS** on element refs

### Remote Browser Support

- **Node browser proxy**: zero-config auto-routing to a node host's local browser
- **Remote CDP URL**: explicit `cdpUrl` (HTTP or WebSocket) for any Chromium-based browser
- **Browserless** (hosted): `wss://production-sfo.browserless.io?token=<KEY>`
- **Browserbase** (hosted): `wss://connect.browserbase.com?apiKey=<KEY>`, auto-creates sessions on connect
- Both support `wss://` direct WebSocket connections (no `/json/version` discovery needed)

### Control API

HTTP API on loopback (derived port = gateway port + 2):

```
GET  /                    — status
POST /start, /stop        — lifecycle
GET  /tabs, POST /tabs/open, /tabs/focus, DELETE /tabs/:targetId
GET  /snapshot, POST /screenshot
POST /navigate, /act
POST /hooks/file-chooser, /hooks/dialog
POST /download, /wait/download
GET  /console, /errors, /requests
POST /trace/start, /trace/stop, /highlight
POST /response/body
GET  /cookies, POST /cookies/set, /cookies/clear
GET  /storage/:kind, POST /storage/:kind/set, /storage/:kind/clear
POST /set/offline, /set/headers, /set/credentials, /set/geolocation, /set/media, /set/timezone, /set/locale, /set/device
```

### Security

- Loopback-only by default; bind derived from `gateway.port`
- Shared-secret auth (gateway token bearer / `x-openclaw-password` / HTTP Basic)
- SSRF protection: URL checked before navigation and re-checked after
- `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork: true` (default, trusted-network model); set `false` for strict public-only
- Hostname allowlist option for strict SSRF
- Remote CDP: prefer HTTPS/WSS + short-lived tokens; keep Gateway + node hosts on private network (Tailscale)

---

## Exec/File Operations

### Exec Tool (`exec` / `process`)

Runs shell commands with these execution targets:

| Host | Description |
|------|-------------|
| `auto` (default) | Sandbox if sandbox runtime active; otherwise gateway |
| `sandbox` | Sandboxed container execution |
| `gateway` | Direct host execution (YOLO by default without approvals) |
| `node` | Execute on a paired device (companion app or headless node host) |

Key parameters:

- `command`, `workdir`, `env` (key/value overrides)
- `yieldMs` (default 10000): auto-background after delay
- `background`: start immediately in background
- `timeout`: kill after N seconds (default 1800)
- `pty`: pseudo-terminal for TTY CLIs, coding agents, terminal UIs
- `elevated`: escape sandbox onto host (requires `elevated` access enabled)

**Authorization**: `/exec` session overrides are for authorized senders only (channel allowlists/pairing + `commands.useAccessGroups`). Host denies are controlled by `~/.openclaw/exec-approvals.json`.

### Security Modes

| Mode | Behavior |
|------|---------|
| `security=deny` | Sandbox default; closed by default |
| `security=allowlist` | Every pipeline segment must be allowlisted or a safe bin |
| `security=full` | No restrictions (YOLO) |

- `tools.exec.ask`: `off | on-miss | always` — approval prompts for gateway/node
- `tools.exec.strictInlineEval`: inline interpreter eval (`python -c`, `node -e`, etc.) always requires explicit approval
- `tools.exec.safeBins`: stdin-only safe binaries (e.g., `grep`, `awk`, `sed`) — no explicit allowlist needed
- `tools.exec.pathPrepend`: prepend directories to `PATH` for exec runs
- `tools.exec.safeBinTrustedDirs`: explicit trusted directories for safe-bin path checks (defaults: `/bin`, `/usr/bin`)
- `tools.exec.safeBinProfiles`: custom argv policy per safe bin

**Note**: Sandboxing is **off by default**. If sandboxing is off, `host=auto` resolves to `gateway`.

### Process Tool

- `process list` — list background sessions (scoped per agent)
- `process poll` — check status/output
- `process log` — retrieve logs
- `process send-keys` — tmux-style key input (`Enter`, `C-c`, `Up`, `Down`, etc.)
- `process submit` — send CR only
- `process paste` — bracketed paste
- `process write` — write to stdin
- `process kill` — terminate session

### File Operations

| Tool | Description |
|------|-------------|
| `read` | Read file (text or image); offset/limit pagination for large files |
| `write` | Create or overwrite file; auto-creates parent directories |
| `edit` | Single-file targeted text replacement via `oldText`/`newText` pairs |
| `apply_patch` | Multi-hunk structured patches (OpenAI/OpenAI Codex models only; `workspaceOnly: true` default) |

File path resolution: workspace-relative or absolute.

### apply_patch

Subtool of `exec` for structured multi-file edits:

```json
{ "tools": { "exec": { "applyPatch": { "workspaceOnly": true, "allowModels": ["gpt-5.4"] } } } }
```

- Defaults to `enabled: true` for OpenAI/OpenAI Codex models
- `workspaceOnly: true` prevents writing/deleting outside workspace

---

## API Integrations

### Web Search (`web_search`)

**Auto-detection order** (first ready provider wins):

1. Brave (`BRAVE_API_KEY`)
2. MiniMax Search (`MINIMAX_CODE_PLAN_KEY` / `MINIMAX_CODING_API_KEY`)
3. Gemini (`GEMINI_API_KEY`)
4. Grok (`XAI_API_KEY`)
5. Kimi (`KIMI_API_KEY` / `MOONSHOT_API_KEY`)
6. Perplexity (`PERPLEXITY_API_KEY` / `OPENROUTER_API_KEY`)
7. Firecrawl (`FIRECRAWL_API_KEY`)
8. Exa (`EXA_API_KEY`)
9. Tavily (`TAVILY_API_KEY`)
10. DuckDuckGo (key-free HTML fallback)
11. Ollama Web Search (key-free via local Ollama host)
12. SearXNG (self-hosted, `SEARXNG_BASE_URL`)

Or set `tools.web.search.provider` explicitly.

Results are **cached by query for 15 minutes** (configurable).

Native Codex web search (`openaiCodex` mode) available for Codex-capable models with `mode: "cached"` default.

### x_search

X (Twitter) posts search via xAI. Accepts natural-language queries with filters:

- `allowed_x_handles` / `excluded_x_handles`
- `from_date` / `to_date`
- `enable_image_understanding`, `enable_video_understanding`

Uses `plugins.entries.xai.config.xSearch.*` config.

### Web Fetch (`web_fetch`)

Lightweight URL fetching for static content. Uses Firecrawl as the bundled provider (configured under `plugins.entries.firecrawl.config.webFetch.*`).

**Note**: For JS-heavy sites or logins, use the **Browser tool** instead.

### Model Providers (Plugins)

Core bundled providers (all enabled by default unless overridden):

`anthropic`, `byteplus`, `cloudflare-ai-gateway`, `github-copilot`, `google`, `huggingface`, `kilocode`, `kimi-coding`, `minimax`, `mistral`, `qwen`, `moonshot`, `nvidia`, `openai`, `opencode`, `opencode-go`, `openrouter`, `qianfan`, `synthetic`, `together`, `venice`, `vercel-ai-gateway`, `volcengine`, `xiaomi`, `zai`

### Media Generation

| Tool | Providers |
|------|-----------|
| `image` / `image_generate` | `openai/*`, `google/*`, `fal/*`, and others |
| `music_generate` | `google/*`, `minimax/*` |
| `video_generate` | `qwen/*` |
| `tts` | Bundled TTS providers |

All require the respective API key configured in the provider's plugin config.

### Skills (Agent Instructions)

Skills are `SKILL.md` files (AgentSkills-compatible) that teach the agent when/how to use tools. Locations (highest to lowest precedence):

1. `<workspace>/skills`
2. `<workspace>/.agents/skills`
3. `~/.agents/skills`
4. `~/.openclaw/skills` (shared across all agents)
5. Bundled skills
6. `skills.load.extraDirs`

**Skill gating** (load-time filters via frontmatter metadata):
- `requires.bins` — binary must exist on PATH
- `requires.env` — env var must exist or be in config
- `requires.config` — config path must be truthy
- `os` — platform filter (`darwin`, `linux`, `win32`)
- `always: true` — skip other gates

Install skills: `openclaw skills install <slug>` or `clawhub sync --all`.

---

## Key Insights for Auto-Deployment

### 1. Three-Layer Tool Architecture

OpenClaw uses **Tools → Skills → Plugins**:
- **Tools**: typed functions the agent calls (`exec`, `browser`, `read`, etc.)
- **Skills**: markdown instruction files (`SKILL.md`) injected into system prompt — teach the agent *when* and *how* to use tools
- **Plugins**: packages that register channels, providers, tools, skills, and more

For self-deployment automation, you write **plugins** (register tools/services) and **skills** (teach the agent to use them).

### 2. Exec Is the Primary Automation Engine

- `exec` / `process` are the core tools for running shell automation on gateway, sandbox, or paired nodes
- Sandboxing is **off by default** — `host=auto` goes to `gateway` unless sandbox runtime is active
- Approval gating for gateway/node execution via `~/.openclaw/exec-approvals.json`
- `elevated` escapes the sandbox onto the configured host path
- `apply_patch` enables structured multi-file edits (OpenAI/Codex models)

### 3. Browser Automation Is First-Class

- Dedicated isolated browser (`openclaw` profile) — doesn't touch user's personal browser
- Remote browser support via WebSocket CDP — works with Browserless, Browserbase, or any remote Chromium
- Node browser proxy for zero-config routing to a paired device's browser
- Full control API: navigation, clicks, type, snapshots, screenshots, downloads, network inspection, state manipulation
- Playwright-powered for advanced actions (click/type/snapshot/PDF); falls back to CDP-only for basic operations

### 4. Plugin System Is the Extension Point

- Plugins register: tools, model providers, channels, skills, speech, media, web fetch/search, HTTP routes, CLI commands, background services
- Install from npm or ClawHub: `openclaw plugins install <pkg>`
- Plugin slots: exclusive categories like `memory` (swap `memory-core` → `memory-lancedb`)
- Workspace/global extension paths: `~/.openclaw/<plugin-root>/*.ts`
- `before_install` and `before_tool_call` hooks with block/no-op semantics

### 5. Skills System Enables Domain Expertise

- Skills are `SKILL.md` files with YAML frontmatter + markdown instructions
- Gate on binary presence (`requires.bins`), env vars, config values, OS
- Per-agent skill allowlists: `agents.defaults.skills` + `agents.list[].skills`
- Bundled skill override: workspace `skills/` > managed `~/.openclaw/skills` > bundled
- Skills can define installers (brew/node/go/uv/download) with platform filtering

### 6. Multi-Agent and Node Execution

- Multiple agents, each with own workspace, own session-scoped exec, own skills
- `host=node` routes shell commands to paired devices (companion app or headless node host)
- `agents.list[].tools.exec.node` binds an agent to a specific node for all exec calls
- Node browser proxy: browser tool auto-routed to node's local browser without extra config
- Remote CDP: attach to any Chromium-based browser via WebSocket URL

### 7. Security Model

- Tool allow/deny lists (`tools.allow`, `tools.deny`, `tools.profile`, `tools.byProvider`)
- `exec` security modes: `deny` (sandbox default), `allowlist`, `full` (gateway/node default)
- Approval gates for gateway/node exec (`tools.exec.ask`)
- Browser SSRF protection with configurable hostname allowlist
- Remote CDP tokens should use env vars or secrets managers (not config files)
- Skills are **untrusted code** — review before enabling; prefer sandboxed runs for untrusted inputs

### 8. Configuration is Centralized

All config in `~/.openclaw/openclaw.json` (JSON5):

- `tools.*` — tool behavior, profiles, allow/deny, exec settings, web search
- `plugins.*` — enable/disable, per-plugin config, slots
- `browser.*` — profiles, CDP ports, SSRF policy, executable path
- `agents.*` — agent list, per-agent workspace, skills, exec node binding
- `skills.*` — per-skill enable/disable, env injection, config overrides
- `gateway.*` — port, auth, sandboxing

Changes require Gateway restart (or auto-restart if config watch is active).

### 9. Automation Patterns

- **Long-running commands**: use `yieldMs` or `background` → `process` tool for logs/status/keys
- **Scheduled automation**: use `cron` tool (not exec + sleep loops)
- **Multi-step workflows**: skills + sub-agents via `sessions_spawn` / `subagents`
- **Browser-based automation**: `browser` tool with snapshots, actions, downloads
- **Structured file edits**: `apply_patch` (OpenAI/Codex) or `edit` (single file)
- **Plugin tools**: register custom tools via plugin `registerTool()` API
