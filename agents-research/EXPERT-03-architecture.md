# Expert 03: OpenClaw Architecture

*Source: https://docs.openclaw.ai/concepts/architecture and related docs (agent-loop, session, memory, queue, plugin-architecture, delegate-architecture)*
*Compiled: 2026-04-06*

---

## Core Components

OpenClaw is organized around a small number of first-class components that must all be present for a working deployment:

| Component | Role | Key File / Process |
|---|---|---|
| **Gateway** | Long-lived daemon; owns all messaging channels and the WebSocket control plane | `openclaw gateway` |
| **pi-agent-core** | Embedded agent runtime that runs model inference and tool execution inside the gateway | In-process |
| **Plugin Registry** | Central registry where all plugins register capabilities | Loaded at gateway startup |
| **Session Manager** | Owns session state, transcripts, and lifecycle per session | `~/.openclaw/agents/<agentId>/sessions/` |
| **Workspace** | Per-agent filesystem directory for agent-owned files (MEMORY.md, SOUL.md, AGENTS.md, etc.) | `~/.openclaw/workspace` (default) |
| **Command Queue** | In-process FIFO that serializes inbound auto-reply runs by session lane | In-process TypeScript |

---

## Gateway Architecture

### Overview

A single **long-lived Gateway daemon** owns all messaging surfaces and the WebSocket control plane. There is exactly one Gateway per host — it is the only process that opens a WhatsApp session (via Baileys) or connects to other channel providers.

### Messaging Surfaces (Channels)

The Gateway owns connections to: WhatsApp (Baileys), Telegram (grammY), Slack, Discord, Signal, iMessage, WebChat. Each channel is implemented as a **channel plugin** (see Plugin Architecture below).

### Control Plane — WebSocket API

All control-plane clients (macOS app, CLI, web admin UI, automations, and **Nodes**) connect to the Gateway over **WebSocket** on the configured bind host, default `127.0.0.1:18789`.

**Protocol Summary:**
- Transport: WebSocket, text frames with JSON payloads.
- First frame **must** be `connect` with auth token or password.
- After handshake:
  - Requests: `{type:"req", id, method, params}` → `{type:"res", id, ok, payload|error}`
  - Events: `{type:"event", event, payload, seq?, stateVersion?}`
- Events emitted: `agent`, `chat`, `presence`, `health`, `heartbeat`, `cron`
- Idempotency keys are required for side-effecting methods (`send`, `agent`) — server keeps a short-lived dedupe cache.

**Auth Modes:**
- `gateway.auth.mode: "token"` — shared-secret via `connect.params.auth.token`
- `gateway.auth.mode: "password"` — shared-secret via `connect.params.auth.password`
- `gateway.auth.mode: "none"` — disables auth (only for private/local ingress — dangerous on public)
- `gateway.auth.allowTailscale: true` — satisfies auth from request headers (Tailscale Serve)
- `gateway.auth.mode: "trusted-proxy"` — for non-loopback trusted ingress

**Pairing + Device Trust:**
- All WS clients include a **device identity** on `connect`.
- New device IDs require pairing approval; the Gateway issues a **device token** for subsequent reconnects.
- Direct local loopback connects can be auto-approved.
- All connects must sign the `connect.challenge` nonce.
- Signature payload `v3` binds `platform` + `deviceFamily`; gateway pins paired metadata on reconnect.

### Canvas Host

The Gateway's HTTP server serves:
- `/__openclaw__/canvas/` — agent-editable HTML/CSS/JS (canvas app)
- `/__openclaw__/a2ui/` — A2UI host
- Same port as WebSocket (default `18789`)

### Nodes (macOS / iOS / Android / Headless)

Nodes connect to the **same WebSocket server** with `role: node` and declare caps/commands/permissions in `connect`. They expose commands like `canvas.*`, `camera.*`, `screen.record`, `location.get`. Pairing for nodes is device-based.

### Remote Access

- **Preferred:** Tailscale or VPN
- **Alternative:** SSH tunnel: `ssh -N -L 18789:127.0.0.1:18789 user@host`
- TLS + optional pinning can be enabled for WebSocket in remote setups.

### Invariants

- Exactly one Gateway controls a single Baileys session per host.
- Handshake is mandatory; any non-JSON or non-connect first frame is a hard close.
- Events are not replayed; clients must refresh on gaps.

### Operations

- **Start:** `openclaw gateway` (foreground, logs to stdout)
- **Health:** `health` over WS (also included in `hello-ok`)
- **Supervision:** launchd/systemd for auto-restart
- **Protocol:** TypeBox schemas define the protocol; JSON Schema generated from those; Swift models generated from JSON Schema.

---

## Agent System

### Agent Loop (pi-agent-core)

The agent loop is the authoritative path that turns a message into actions and a final reply. It is implemented by `pi-agent-core` running **embedded** inside the Gateway process.

**Entry Points:**
- Gateway RPC: `agent` and `agent.wait`
- CLI: `agent` command

**Full Loop Steps:**

1. `agent` RPC validates params, resolves session (sessionKey/sessionId), persists session metadata, returns `{ runId, acceptedAt }` immediately.
2. `agentCommand` resolves model + thinking/verbose defaults, loads skills snapshot, calls `runEmbeddedPiAgent`.
3. `runEmbeddedPiAgent`:
   - Serializes runs via per-session + global queues
   - Resolves model + auth profile and builds the pi session
   - Subscribes to pi events and streams assistant/tool deltas
   - Enforces timeout → aborts run if exceeded
   - Returns payloads + usage metadata
4. `subscribeEmbeddedPiSession` bridges pi-agent-core events to OpenClaw `agent` stream:
   - Tool events → `stream: "tool"`
   - Assistant deltas → `stream: "assistant"`
   - Lifecycle events → `stream: "lifecycle"` (`phase: "start" | "end" | "error"`)
5. `agent.wait` waits for **lifecycle end/error** for `runId`, returns `{ status, startedAt, endedAt, error? }`

### Prompt Assembly + System Prompt

- System prompt is built from: OpenClaw base prompt + skills prompt + bootstrap context + per-run overrides.
- Model-specific limits and compaction reserve tokens are enforced.
- Bootstrap files are resolved and injected before system prompt is finalized (`agent:bootstrap` hook point).

### Workspace Preparation

- Workspace is resolved and created; sandboxed runs may redirect to a sandbox workspace root.
- Skills are loaded (or reused from a snapshot) and injected into env and prompt.
- Bootstrap/context files are resolved and injected.

### Streaming + Partial Replies

- Assistant deltas streamed from pi-agent-core as `assistant` events.
- Block streaming emits partial replies on `text_end` or `message_end`.
- Reasoning streaming can be emitted as separate stream or as block replies.

### Tool Execution

- Tool start/update/end events emitted on the `tool` stream.
- Tool results sanitized for size and image payloads before logging/emitting.
- Messaging tool sends tracked to suppress duplicate assistant confirmations.

### Reply Shaping + Suppression

- Final payloads assembled from: assistant text (and optional reasoning), inline tool summaries (verbose), assistant error text.
- Exact `NO_REPLY` / `no_reply` token filtered from outgoing payloads.
- Messaging tool duplicates removed from final payload list.
- Fallback tool error reply emitted if no renderable payloads remain and a tool errored.

### Compaction + Retries

- Auto-compaction emits `compaction` stream events and can trigger a retry.
- On retry, in-memory buffers and tool summaries reset to avoid duplicate output.

### Timeouts

- `agent.wait` default: 30s; `timeoutMs` param overrides.
- Agent runtime: `agents.defaults.timeoutSeconds` default 172800s (48 hours); enforced in `runEmbeddedPiAgent` abort timer.

### Hook Points

**Internal hooks (Gateway hooks):**
- `agent:bootstrap` — runs while building bootstrap files before system prompt is finalized. Use to add/remove bootstrap context files.
- Command hooks: `/new`, `/reset`, `/stop`, and other command events.

**Plugin hooks (agent + gateway lifecycle):**
- `before_model_resolve` — pre-session (no `messages`) override of provider/model before resolution.
- `before_prompt_build` — post-session load (with `messages`) to inject `prependContext`, `systemPrompt`, `prependSystemContext`, or `appendSystemContext` before prompt submission.
- `before_agent_reply` — after inline actions and before LLM call; plugin can claim the turn or silence it entirely.
- `agent_end` — inspect final message list and run metadata after completion.
- `before_compaction` / `after_compaction` — observe or annotate compaction cycles.
- `before_tool_call` / `after_tool_call` — intercept tool params/results. `{ block: true }` is terminal.
- `before_install` — inspect built-in scan findings; `{ block: true }` is terminal.
- `tool_result_persist` — synchronously transform tool results before writing to session transcript.
- `message_received` / `message_sending` / `message_sent` — inbound + outbound message hooks.
- `session_start` / `session_end` — session lifecycle boundaries.
- `gateway_start` / `gateway_stop` — gateway lifecycle events.

### Event Streams

- `lifecycle` — emitted by `subscribeEmbeddedPiSession` (and as fallback by `agentCommand`)
- `assistant` — streamed deltas from pi-agent-core
- `tool` — streamed tool events from pi-agent-core

### Subagents / Multi-Agent

The **Delegate Architecture** defines how OpenClaw runs as a named delegate agent on behalf of an organization. Key points:
- Each agent has its own workspace, agentDir, identity, and tool policy.
- Multi-agent routing via `bindings` in config maps channel accounts to agents.
- Subagent runs are tracked as background tasks with session references.
- Delegate agents have isolated auth stores and can be sandboxed separately.

---

## Session Management

### Session Routing

| Source | Behavior |
|---|---|
| Direct messages | Shared session by default |
| Group chats | Isolated per group |
| Rooms/channels | Isolated per room |
| Cron jobs | Fresh session per run |
| Webhooks | Isolated per hook |

### DM Isolation

Default: all DMs share one session. For multi-user deployments, configure:
- `session.dmScope: "per-channel-peer"` (recommended for multi-user)
- Other options: `main`, `per-peer`, `per-account-channel-peer`

### Session Lifecycle

Sessions are reused until they expire:
- **Daily reset** (default) — new session at 4:00 AM local time on gateway host.
- **Idle reset** (optional) — new session after `session.reset.idleMinutes` of inactivity.
- **Manual reset** — `/new` or `/reset` in chat.

### State Storage

All session state is owned by the **Gateway**:
- **Store:** `~/.openclaw/agents/<agentId>/sessions/sessions.json`
- **Transcripts:** `~/.openclaw/agents/<agentId>/sessions/<sessionId>.jsonl`

### Session Maintenance

OpenClaw auto-bounds session storage:
```json5
{
  session: {
    maintenance: {
      mode: "enforce",  // or "warn"
      pruneAfter: "30d",
      maxEntries: 500,
    },
  },
}
```

### Command Queue (Concurrency)

- A lane-aware FIFO queue drains each lane with a configurable concurrency cap.
- `runEmbeddedPiAgent` enqueues by **session key** (lane `session:<key>`) — guarantees only one active run per session.
- Each session run is then queued into a **global lane** (`main` default) — overall parallelism capped by `agents.defaults.maxConcurrent`.
- Additional lanes exist (e.g. `cron`, `subagent`) so background jobs run in parallel without blocking inbound.

**Queue modes per channel:**
- `collect` — coalesce all queued messages into a single followup turn (default)
- `steer` — inject immediately into current run
- `followup` — enqueue for next agent turn after current run ends
- `steer-backlog` — steer now AND preserve for followup
- `interrupt` (legacy) — abort active run, then run newest

Options: `debounceMs` (default 1000), `cap` (default 20), `drop` (`old`|`new`|`summarize`)

---

## Memory System

### Overview

OpenClaw remembers by writing **plain Markdown files** in the agent's workspace. The model only "remembers" what gets saved to disk — no hidden state.

### Files

- **`MEMORY.md`** — long-term memory. Durable facts, preferences, decisions. Loaded at start of every DM session.
- **`memory/YYYY-MM-DD.md`** — daily notes. Running context. Today and yesterday auto-loaded.
- **`DREAMS.md`** (experimental) — Dream Diary and dreaming sweep summaries for human review.

### Memory Tools

- **`memory_search`** — semantic (vector) + keyword hybrid search via the active memory plugin.
- **`memory_get`** — reads a specific memory file or line range.

Both provided by the active memory plugin (default: `memory-core`).

### Memory Backends

| Backend | Type | Notes |
|---|---|---|
| **Builtin** (default) | SQLite | Works out of the box with keyword + vector + hybrid search |
| **QMD** | Local-first sidecar | Reranking, query expansion, can index dirs outside workspace |
| **Honcho** | AI-native | Cross-session memory, user modeling, semantic search, multi-agent awareness |

Auto-detects embedding provider from API keys (OpenAI, Gemini, Voyage, Mistral).

### Automatic Memory Flush

Before compaction summarizes a conversation, OpenClaw runs a silent turn that reminds the agent to save important context to memory files. This is on by default.

### Dreaming (Experimental)

- Optional background consolidation pass — collects short-term signals, scores candidates, promotes qualified items to long-term memory.
- Opt-in, scheduled via `memory-core` cron job.
- Thresholded: promotions must pass score, recall frequency, and query diversity gates.
- Reviewable: summaries written to `DREAMS.md`.

---

## Plugin Architecture

### Overview

OpenClaw's plugin system has four layers:
1. **Manifest + discovery** — finds candidates from configured paths, workspace roots, global extension roots, bundled extensions. Reads `openclaw.plugin.json` manifests.
2. **Enablement + validation** — decides enabled/disabled/blocked per candidate.
3. **Runtime loading** — native plugins loaded in-process via `jiti`; register capabilities into central registry.
4. **Surface consumption** — rest of OpenClaw reads registry for tools, channels, providers, hooks, routes, CLI commands, services.

### Capability Model

Every native OpenClaw plugin registers against one or more **capability types**:

| Capability | Registration method | Example plugins |
|---|---|---|
| Text inference | `api.registerProvider(...)` | `openai`, `anthropic` |
| CLI inference backend | `api.registerCliBackend(...)` | `openai`, `anthropic` |
| Speech | `api.registerSpeechProvider(...)` | `elevenlabs`, `microsoft` |
| Realtime transcription | `api.registerRealtimeTranscriptionProvider(...)` | `openai` |
| Realtime voice | `api.registerRealtimeVoiceProvider(...)` | `openai` |
| Media understanding | `api.registerMediaUnderstandingProvider(...)` | `openai`, `google` |
| Image generation | `api.registerImageGenerationProvider(...)` | `openai`, `google`, `fal`, `minimax` |
| Music generation | `api.registerMusicGenerationProvider(...)` | `google`, `minimax` |
| Video generation | `api.registerVideoGenerationProvider(...)` | `qwen` |
| Web fetch | `api.registerWebFetchProvider(...)` | `firecrawl` |
| Web search | `api.registerWebSearchProvider(...)` | `google` |
| Channel / messaging | `api.registerChannel(...)` | `msteams`, `matrix` |

### Plugin Shapes

- **plain-capability** — registers exactly one capability type
- **hybrid-capability** — registers multiple capability types (e.g., `openai` = text + speech + media + image)
- **hook-only** — registers only hooks, no capabilities
- **non-capability** — registers tools, commands, services, or routes but no capabilities

### Capability Ownership Model

- **plugin** = ownership boundary (a company or feature)
- **capability** = core contract that multiple plugins can implement or consume

Core capability layer owns orchestration, policy, fallback, config merge rules, delivery semantics, typed contracts. Vendor plugins own vendor-specific APIs, auth, model catalogs. Channel/feature plugins consume core capabilities.

### Execution Model

Native plugins run **in-process** with the Gateway — not sandboxed. Same process-level trust as core. A malicious native plugin = arbitrary code execution inside OpenClaw process.

### Load Pipeline

1. Discover candidate plugin roots
2. Read native or compatible bundle manifests and package metadata
3. Reject unsafe candidates (entry escapes plugin root, path is world-writable, suspicious ownership)
4. Normalize plugin config (`plugins.enabled`, `allow`, `deny`, `entries`, `slots`, `load.paths`)
5. Decide enablement for each candidate
6. Load enabled native modules via jiti
7. Call `register(api)` (or legacy `activate(api)`) hooks — collect registrations into plugin registry
8. Expose registry to commands/runtime surfaces

Safety gates happen **before** runtime execution.

### Registry Model

Plugins register into a **central plugin registry** — they do not mutate core globals directly. The registry tracks: plugin records, tools, hooks (legacy + typed), channels, providers, gateway RPC handlers, HTTP routes, CLI registrars, background services, plugin-owned commands.

One-way: plugin module → registry → core runtime reads from registry.

### Channel Plugins

- Core owns the shared `message` tool host, prompt wiring, session/thread bookkeeping, execution dispatch.
- Channel plugins own scoped action discovery, capability discovery, channel-specific schema fragments, and provider-specific conversation grammar.
- Bundled plugins should keep execution runtime inside their own extension modules — core no longer owns Discord/Slack/Telegram/WhatsApp message-action runtimes.

### Provider Runtime Hooks

Provider plugins have hooks at multiple layers:
- Manifest: `providerAuthEnvVars`, `providerAuthChoices`
- Config-time: `catalog`, `applyConfigDefaults`
- Runtime: `normalizeModelId`, `normalizeTransport`, `normalizeConfig`, `normalizeToolSchemas`, `resolveReasoningOutputMode`, `createStreamFn`, `wrapStreamFn`, `matchesContextOverflowError`, `classifyFailoverReason`, `augmentModelCatalog`, `onModelSelected`, `createEmbeddingProvider`, and many more.

### Workspace Plugins

- `plugins.allow` trusts **plugin ids**, not source provenance.
- A workspace plugin with the same id as a bundled plugin intentionally shadows the bundled copy.
- Treat workspace plugins as development-time code, not production defaults.

---

## Key Insights for Auto-Deployment

### 1. Gateway is the Mandatory Core Process

For self-deployment, the **Gateway daemon** (`openclaw gateway`) is the one process you must replicate. It is the single source of truth for:
- All channel connections (WhatsApp, Telegram, etc.)
- WebSocket control plane for all clients and nodes
- Session state and transcripts on disk
- Plugin loading and the agent runtime embedded inside it

**You cannot split the Gateway.** There is exactly one per host.

### 2. WebSocket Control Plane is the Client/Node Interface

All clients (CLI, macOS app, web admin, automations) and all nodes (companion apps) connect via WebSocket on port `18789` (default). For remote access, the preferred method is Tailscale or VPN. SSH tunnels also work.

The protocol is typed with TypeBox/JSON Schema — the gateway validates inbound frames against schemas.

### 3. Workspace and Memory are Filesystem-Based

- Workspace is a directory on disk (`~/.openclaw/workspace` by default).
- `MEMORY.md`, `memory/YYYY-MM-DD.md`, `DREAMS.md` are plain Markdown files.
- Session transcripts are JSONL files.
- This means **backup = `rsync` of `~/.openclaw/`** and **migration = copy of `~/.openclaw/`**.

### 4. Plugin Loading is Local + In-Process

Plugins are discovered from:
- Bundled extensions (ship with OpenClaw)
- Configured plugin paths (`plugins.load.paths`)
- Workspace plugin roots
- Global extension roots

Native plugins load in-process via `jiti`. There is no plugin hosting service — plugins run in the same process as the Gateway.

### 5. Multi-Agent is Config-Based Routing

Multiple agents share one Gateway but each has:
- Own workspace directory
- Own `agentDir` for auth-profiles and state
- Tool allow/deny policy
- Optional sandbox
- Identity binding via `bindings` config

Subagent/deputy runs use the same `agent` RPC with a different `agentId`.

### 6. Session State is Gateway-Owned

- Session store: `~/.openclaw/agents/<agentId>/sessions/sessions.json`
- Transcripts: `~/.openclaw/agents/<agentId>/sessions/<sessionId>.jsonl`
- No database dependency (SQLite is only for the optional builtin memory backend)
- State survives Gateway restarts

### 7. Queue is In-Process (No Redis / Message Broker)

The command queue is pure TypeScript + promises. Runs are serialized per-session lane and through a global lane — no external dependencies.

### 8. Auth is Device + Token Based

- Pairing is device-based with signed challenges
- Auth tokens / passwords for WS clients
- Identity provider delegation for delegate agents (OAuth / Send-on-behalf)
- `plugins.allow` trusts plugin ids

### 9. Idempotency is Required for Send/Agent

Clients must include idempotency keys for `send` and `agent` RPC calls. The server keeps a short-lived dedupe cache.

### 10. Delegate Architecture for Organizational Deployments

For multi-user / organization deployments:
- Each delegate agent has isolated workspace, agentDir, tool policy, and credentials
- Identity provider (Azure AD / Google Workspace) enforces delegation permissions
- Standing orders define autonomous vs. approval-required actions
- Cron jobs drive scheduled autonomous work
- Tool restrictions enforce hard blocks at Gateway level
- Sandbox mode isolates filesystem/network access

---

## Summary: What Needs to Be Replicated for Self-Deployment

| Component | Self-Hosting Requirement |
|---|---|
| Gateway daemon | ✅ Must run `openclaw gateway` — single process per host |
| WebSocket control plane | ✅ Exposed on `127.0.0.1:18789` (or configured bind); TLS can be enabled |
| Channel providers | ✅ All via plugin system; WhatsApp requires Baileys (single session per host) |
| Session store/transcripts | ✅ File-based in `~/.openclaw/agents/<agentId>/sessions/` |
| Workspace files | ✅ `~/.openclaw/workspace/` directory with SOUL.md, AGENTS.md, MEMORY.md, etc. |
| Plugin loading | ✅ From config paths, bundled, or workspace; loaded in-process |
| Command queue | ✅ In-process, no external broker needed |
| Memory backends | ✅ Builtin (SQLite), QMD, or Honcho — all local |
| Auth / pairing | ✅ Device-based pairing + WS token auth |
| Remote access | ✅ Tailscale/VPN preferred; SSH tunnel as fallback |
| pi-agent-core | ✅ Embedded inside Gateway — no separate process |
| Node connections | ✅ WebSocket with `role: node` — same WS server |

**No external dependencies** for the core Gateway: no Redis, no message queue, no Postgres — just Node.js and the filesystem.
