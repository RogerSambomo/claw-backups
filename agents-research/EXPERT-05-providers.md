# Expert 05: OpenClaw Providers

## Supported Providers

OpenClaw supports **50+ AI providers** across text/chat, image generation, video generation, music generation, and transcription.

### Built-in Providers (pi-ai catalog — no config needed, just auth)

| Provider | ID | Auth Env Vars | Example Model |
|---|---|---|---|
| **OpenAI** | `openai` | `OPENAI_API_KEY`, `OPENAI_API_KEYS`, `OPENAI_API_KEY_1/2`, `OPENCLAW_LIVE_OPENAI_KEY` | `openai/gpt-5.4` |
| **Anthropic** | `anthropic` | `ANTHROPIC_API_KEY`, `ANTHROPIC_API_KEYS`, `ANTHROPIC_API_KEY_1/2`, `OPENCLAW_LIVE_ANTHROPIC_KEY` | `anthropic/claude-opus-4-6` |
| **OpenAI Codex** | `openai-codex` | OAuth (ChatGPT sign-in) | `openai-codex/gpt-5.4` |
| **Google Gemini** | `google` | `GEMINI_API_KEY`, `GEMINI_API_KEYS`, `GEMINI_API_KEY_1/2`, `GOOGLE_API_KEY`, `OPENCLAW_LIVE_GEMINI_KEY` | `google/gemini-3.1-pro-preview` |
| **Google Vertex** | `google-vertex` | gcloud ADC | (Claude on Vertex) |
| **Google Gemini CLI** | `google-gemini-cli` | OAuth (PKCE) | `google-gemini-cli/gemini-3.1-pro-preview` |
| **DeepSeek** | `deepseek` | `DEEPSEEK_API_KEY` | `deepseek/deepseek-chat`, `deepseek/deepseek-reasoner` |
| **Z.AI (GLM)** | `zai` | `ZAI_API_KEY` | `zai/glm-5` |
| **Vercel AI Gateway** | `vercel-ai-gateway` | `AI_GATEWAY_API_KEY` | `vercel-ai-gateway/anthropic/claude-opus-4.6` |
| **Kilo Gateway** | `kilocode` | `KILOCODE_API_KEY` | `kilocode/kilo/auto` |
| **Mistral** | `mistral` | `MISTRAL_API_KEY` | `mistral/mistral-large-latest` |
| **Groq** | `groq` | `GROQ_API_KEY` | — |
| **Cerebras** | `cerebras` | `CEREBRAS_API_KEY` | `zai-glm-4.7`, `zai-glm-4.6` |
| **xAI** | `xai` | `XAI_API_KEY` | `xai/*` |
| **OpenRouter** | `openrouter` | `OPENROUTER_API_KEY` | `openrouter/auto` |
| **Together AI** | `together` | `TOGETHER_API_KEY` | `together/moonshotai/Kimi-K2.5` |
| **NVIDIA** | `nvidia` | `NVIDIA_API_KEY` | `nvidia/nvidia/llama-3.1-nemotron-70b-instruct` |
| **Venice** | `venice` | `VENICE_API_KEY` | — |
| **Xiaomi** | `xiaomi` | `XIAOMI_API_KEY` | `xiaomi/mimo-v2-flash` |
| **Hugging Face Inference** | `huggingface` | `HUGGINGFACE_HUB_TOKEN` or `HF_TOKEN` | `huggingface/deepseek-ai/DeepSeek-R1` |
| **Cloudflare AI Gateway** | `cloudflare-ai-gateway` | `CLOUDFLARE_AI_GATEWAY_API_KEY` | — |
| **GitHub Copilot** | `github-copilot` | `COPILOT_GITHUB_TOKEN` / `GH_TOKEN` / `GITHUB_TOKEN` | — |
| **Qianfan** | `qianfan` | `QIANFAN_API_KEY` | `qianfan/deepseek-v3.2` |
| **Qwen Cloud** | `qwen` | `QWEN_API_KEY`, `MODELSTUDIO_API_KEY`, `DASHSCOPE_API_KEY` | `qwen/qwen3.5-plus` |
| **StepFun** | `stepfun` / `stepfun-plan` | `STEPFUN_API_KEY` | `stepfun/step-3.5-flash` |
| **Volcengine** | `volcengine` / `volcengine-plan` | `VOLCANO_ENGINE_API_KEY` | `volcengine-plan/ark-code-latest` |
| **BytePlus** | `byteplus` / `byteplus-plan` | `BYTEPLUS_API_KEY` | `byteplus-plan/ark-code-latest` |
| **Moonshot AI** | `moonshot` | `MOONSHOT_API_KEY` | `moonshot/kimi-k2.5` |
| **Kimi Coding** | `kimi` | `KIMI_API_KEY` or `KIMICODE_API_KEY` | `kimi/kimi-code` |
| **MiniMax** | `minimax` / `minimax-portal` | `MINIMAX_API_KEY`, `MINIMAX_OAUTH_TOKEN` | `minimax/MiniMax-M2.7` |
| **Synthetic** | `synthetic` | `SYNTHETIC_API_KEY` | `synthetic/hf:MiniMaxAI/MiniMax-M2.5` |
| **Alibaba Model Studio** | `alibaba` | — | — |
| **Amazon Bedrock** | `amazon-bedrock` | AWS SDK default chain | — |
| **Chutes** | `chutes` | — | — |
| **ComfyUI** | `comfy` | — | — |
| **fal** | `fal` | — | — |
| **Fireworks** | `fireworks` | — | — |
| **OpenCode** | `opencode` | `OPENCODE_API_KEY` or `OPENCODE_ZEN_API_KEY` | `opencode/claude-opus-4-6` |
| **OpenCode Go** | `opencode-go` | `OPENCODE_API_KEY` | `opencode-go/kimi-k2.5` |
| **Perplexity** | `perplexity-provider` | — | — |
| **Runway** | `runway` | — | `runway/gen4.5` |
| **SGLang** | `sglang` | Optional `SGLANG_API_KEY` | (local models) |
| **vLLM** | `vllm` | Optional `VLLM_API_KEY` | (local models) |
| **Ollama** | `ollama` | None required (local) | `ollama/llama3.3` |

### Special-Purpose Bundled Plugins

| Plugin | Purpose |
|---|---|
| `openai` | Image gen (`gpt-image-1`), video gen (`sora-2`) |
| `google` | Image gen (`gemini-3.1-flash-image-preview`), video gen (`veo-3.1-fast-generate-preview`), music gen (`lyria-3-clip-preview`) |
| `deepgram` | Audio transcription |
| `claude-max-api-proxy` | Community proxy for Claude subscription credentials |

---

## API Configuration

### Environment Variable Pattern

All API keys are set via environment variables. The primary pattern is:

```json5
{
  env: {
    ANTHROPIC_API_KEY: "sk-ant-...",
    OPENAI_API_KEY: "sk-...",
    GEMINI_API_KEY: "...",
    DEEPSEEK_API_KEY: "...",
    // ... per-provider key
  }
}
```

### API Key Rotation

OpenClaw supports **multi-key rotation** for rate-limit handling:

```
Priority order (highest first):
1. OPENCLAW_LIVE_<PROVIDER>_KEY   ← single live override
2. <PROVIDER>_API_KEYS            ← comma/semicolon-separated list
3. <PROVIDER>_API_KEY             ← single primary key
4. <PROVIDER>_API_KEY_1, _2, ...  ← numbered list
```

For Google providers, `GOOGLE_API_KEY` is also checked as fallback.

Key rotation triggers only on **rate-limit errors**: `429`, `rate_limit`, `quota`, `resource exhausted`, `Too many concurrent requests`, `ThrottlingException`, `concurrency limit reached`, `workers_ai ... quota limit exceeded`, or periodic usage-limit messages.

Non-rate-limit failures fail immediately — no rotation attempted.

### Provider Auth Methods

| Auth Type | Providers | How |
|---|---|---|
| **API Key (env var)** | Most providers | Set `<PROVIDER>_API_KEY` in `env` |
| **OAuth** | OpenAI Codex, MiniMax Portal, Google Gemini CLI | CLI: `openclaw onboard --auth-choice <provider>` or `openclaw models auth login --provider <provider>` |
| **AWS SDK chain** | Amazon Bedrock | Uses AWS default credential chain (env, EC2 role, etc.) |
| **gcloud ADC** | Google Vertex | `gcloud auth application-default login` |
| **No auth** | Ollama, vLLM, SGLang (local) | Just set `OLLAMA_API_KEY="any-value"` to enable discovery |
| **Token reuse** | Claude CLI (`anthropic`) | OpenClaw reuses existing `claude -p` login |

### CLI Onboarding Commands

```bash
# Interactive onboarding (selects provider + sets up auth)
openclaw onboard

# Non-interactive with specific provider
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice anthropic-api-key \
  --anthropic-api-key "$ANTHROPIC_API_KEY"

# Auth login only
openclaw models auth login --provider openai-codex --set-default

# Check auth status
openclaw models status
openclaw models status --json

# List available models
openclaw models list

# Set default model
openclaw models set anthropic/claude-opus-4-6
```

---

## Model Setup

### The `provider/model` Naming Convention

All models are referenced as `provider/model` (e.g., `anthropic/claude-opus-4-6`, `openai/gpt-5.4`).

### Setting the Default Model

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-opus-4-6",
        fallbacks: ["openai/gpt-5.4", "deepseek/deepseek-chat"]
      }
    }
  }
}
```

### Built-in Provider Config (no `models.providers` needed)

For built-in `pi-ai` catalog providers, just set the model + auth:

```json5
{
  env: { ANTHROPIC_API_KEY: "sk-ant-..." },
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } }
}
```

```json5
{
  env: { OPENAI_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "openai/gpt-5.4" } } }
}
```

```json5
{
  env: { GEMINI_API_KEY: "..." },
  agents: { defaults: { model: { primary: "google/gemini-3.1-pro-preview" } } }
}
```

```json5
{
  env: { DEEPSEEK_API_KEY: "..." },
  agents: { defaults: { model: { primary: "deepseek/deepseek-chat" } } }
}
```

### Custom/Proxy Provider Config (`models.providers`)

For **custom OpenAI-compatible or Anthropic-compatible endpoints**, use `models.providers`:

```json5
{
  models: {
    mode: "merge",   // recommended: merge with built-in catalog
    providers: {
      my-proxy: {
        baseUrl: "https://api.example.com/v1",
        apiKey: "${MY_PROXY_API_KEY}",
        api: "openai-completions",  // or "anthropic-messages", "ollama", etc.
        models: [
          {
            id: "my-model-id",           // required
            name: "My Model",            // optional
            reasoning: false,            // default: false
            input: ["text"],              // default: ["text"]
            cost: {                       // default: all 0
              input: 0,
              output: 0,
              cacheRead: 0,
              cacheWrite: 0
            },
            contextWindow: 200000,        // default: 200000
            maxTokens: 8192               // default: 8192
          }
        ]
      }
    }
  },
  agents: {
    defaults: {
      model: { primary: "my-proxy/my-model-id" }
    }
  }
}
```

#### Supported `api` Types

| API Type | Description |
|---|---|
| `openai-completions` | OpenAI `/v1/chat/completions` compatible |
| `anthropic-messages` | Anthropic `/v1/messages` compatible |
| `ollama` | Ollama native `/api/chat` (tool calling + streaming) |
| `openai-responses` | OpenAI Responses API (WebSocket-first) |

#### Complete Custom Provider Examples

**Moonshot AI (Kimi):**
```json5
{
  models: {
    mode: "merge",
    providers: {
      moonshot: {
        baseUrl: "https://api.moonshot.ai/v1",
        apiKey: "${MOONSHOT_API_KEY}",
        api: "openai-completions",
        models: [{ id: "kimi-k2.5", name: "Kimi K2.5" }]
      }
    }
  },
  agents: { defaults: { model: { primary: "moonshot/kimi-k2.5" } } }
}
```

**Synthetic ( Anthropic-compatible ):**
```json5
{
  models: {
    mode: "merge",
    providers: {
      synthetic: {
        baseUrl: "https://api.synthetic.new/anthropic",
        apiKey: "${SYNTHETIC_API_KEY}",
        api: "anthropic-messages",
        models: [{ id: "hf:MiniMaxAI/MiniMax-M2.5", name: "MiniMax M2.5" }]
      }
    }
  },
  agents: { defaults: { model: { primary: "synthetic/hf:MiniMaxAI/MiniMax-M2.5" } } }
}
```

**Local Ollama:**
```json5
{
  models: {
    mode: "merge",
    providers: {
      ollama: {
        baseUrl: "http://ollama-host:11434",
        apiKey: "ollama-local",
        api: "ollama",
        models: [
          {
            id: "glm-4.7-flash",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 200000,
            maxTokens: 8192
          }
        ]
      }
    }
  },
  agents: { defaults: { model: { primary: "ollama/glm-4.7-flash" } } }
}
```

**LM Studio (OpenAI-compatible local):**
```json5
{
  agents: {
    defaults: {
      model: { primary: "lmstudio/my-local-model" },
      models: { "lmstudio/my-local-model": { alias: "Local" } }
    }
  },
  models: {
    providers: {
      lmstudio: {
        baseUrl: "http://localhost:1234/v1",
        apiKey: "LMSTUDIO_KEY",
        api: "openai-completions",
        models: [
          {
            id: "my-local-model",
            name: "Local Model",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 200000,
            maxTokens: 8192
          }
        ]
      }
    }
  }
}
```

### Ollama Auto-Discovery (No Explicit Config)

Ollama supports **zero-config model discovery**:

```bash
export OLLAMA_API_KEY="any-value"  # Any value works; Ollama doesn't enforce auth
```

With just `OLLAMA_API_KEY` set and **no** explicit `models.providers.ollama` entry, OpenClaw auto-discovers models via `/api/tags`, reads context windows via `/api/show`, and marks reasoning models by name heuristics (`r1`, `reasoning`, `think`).

### Per-Model Parameters

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-6": {
          params: {
            cacheRetention: "long",        // "none" | "short" (5min) | "long" (1hr)
            context1m: true,               // enable 1M context window beta
            thinking: "adaptive",         // thinking level override
            fastMode: true,                // /fast toggle
            transport: "auto",             // "auto" | "sse" | "websocket"
            serviceTier: "priority"       // OpenAI priority processing
          }
        },
        "openai/gpt-5.4": {
          params: {
            transport: "auto",
            fastMode: true,
            serviceTier: "priority",
            openaiWsWarmup: true,          // WebSocket warm-up for first-turn latency
            responsesServerCompaction: true,
            responsesCompactThreshold: 120000
          }
        },
        "google/gemini-2.5-pro": {
          params: {
            cachedContent: "cachedContents/prebuilt-context"
          }
        }
      }
    }
  }
}
```

### Model Allowlisting

If you set `agents.defaults.models`, it becomes the **allowlist** (only listed models are usable):

```json5
{
  agents: {
    defaults: {
      models: ["anthropic/claude-opus-4-6", "openai/gpt-5.4"]
    }
  }
}
```

### Model Metadata Fields

| Field | Required | Default | Description |
|---|---|---|---|
| `id` | Yes | — | Provider's model ID string |
| `name` | No | same as `id` | Human-readable name |
| `reasoning` | No | `false` | Whether model supports reasoning/thinking |
| `input` | No | `["text"]` | Input modalities: `["text"]`, `["text", "image"]` |
| `cost.input` | No | `0` | Cost per input token |
| `cost.output` | No | `0` | Cost per output token |
| `cost.cacheRead` | No | `0` | Cost per cache-read token |
| `cost.cacheWrite` | No | `0` | Cost per cache-write token |
| `contextWindow` | No | `200000` | Native context window size |
| `maxTokens` | No | `8192` | Max output tokens |
| `contextTokens` | No | — | Runtime cap (separate from native metadata) |

Use `contextWindow` for native metadata declaration/override. Use `contextTokens` to limit the runtime context budget.

---

## Key Insights for Auto-Deployment

### 1. Zero-Config for Major Providers

For **OpenAI, Anthropic, Google Gemini, DeepSeek, and most major providers**, the only required steps are:
1. Set the API key env var (or onboard interactively)
2. Set the default model

```bash
# Non-interactive setup (perfect for scripts/CI)
export ANTHROPIC_API_KEY="sk-ant-..."
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice apiKey \
  --anthropic-api-key "$ANTHROPIC_API_KEY"
```

### 2. Use `models.mode: "merge"` for Custom Providers

When adding custom providers, always use `"mode": "merge"` to avoid accidentally clobbering the built-in pi-ai catalog:

```json5
{
  models: {
    mode: "merge",
    providers: {
      myCustom: { ... }
    }
  }
}
```

### 3. Provider Plugin Architecture

OpenClaw's provider plugins (`registerProvider`) can own:
- **Auth**: `auth[].run` / `auth[].runNonInteractive` for onboarding
- **Model catalog**: `catalog` injects models into `models.providers`
- **Runtime hooks**: `normalizeModelId`, `normalizeTransport`, `normalizeConfig`, `resolveConfigApiKey`, `createStreamFn`, `wrapStreamFn`, `matchesContextOverflowError`, `classifyFailoverReason`, `augmentModelCatalog`, and many more
- **Capability metadata**: provider family quirks, transcript/tooling hints, cache TTL policy

This means many providers work **automatically** after setting an API key — no manual model catalog needed.

### 4. Ollama/vLLM/SGLang for Local Models

Local inference requires **no API keys** (just any placeholder value):

```bash
export OLLAMA_API_KEY="ollama-local"   # enables auto-discovery
export VLLM_API_KEY="vllm-local"
export SGLANG_API_KEY="sglang-local"
```

**Warning**: For Ollama, use native URL `http://host:11434` (no `/v1` suffix) for reliable tool calling. The `/v1` path uses OpenAI-compatible mode where tool calling is unreliable.

### 5. API Key Rotation via Env Vars

For production with multiple API keys:

```bash
export OPENAI_API_KEYS="sk-key1,sk-key2,sk-key3"   # rotation list
export ANTHROPIC_API_KEYS="sk-ant-key1;sk-ant-key2"  # semicolon also works
export OPENCLAW_LIVE_ANTHROPIC_KEY="sk-ant-hot-override"  # highest priority
```

### 6. Provider-Owned Capabilities

Some providers bundle extra capabilities beyond text chat:

- **`openai`**: `gpt-image-1` (image gen), `sora-2` (video gen)
- **`google`**: Gemini image preview (image gen), Veo (video gen), Lyria (music gen)
- **`minimax`**: `image-01` (image gen), Hailuo (video gen)
- **`deepgram`**: audio transcription

These are registered via shared tools (`image_generate`, `video_generate`, `music_generate`) and can be set as defaults:

```json5
{
  agents: {
    defaults: {
      imageGenerationModel: { primary: "openai/gpt-image-1" },
      videoGenerationModel: { primary: "google/veo-3.1-fast-generate-preview" }
    }
  }
}
```

### 7. `/fast` Toggle Support

Both `openai/*` and `anthropic/*` support `/fast` for priority processing:

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-sonnet-4-6": { params: { fastMode: true } },
        "openai/gpt-5.4": { params: { fastMode: true } }
      }
    }
  }
}
```

For xAI, `/fast` auto-rewrites `grok-3`, `grok-3-mini`, `grok-4`, `grok-4-0709` to their `*-fast` variants.

### 8. Thinking/Reasoning Defaults

- **Anthropic Claude 4.6**: defaults to `adaptive` thinking
- **DeepSeek Reasoner**: reasoning-enabled surface
- **xAI**: `tool_stream` defaults on
- **MiniMax**: thinking disabled by default (use `/think` to enable)
- Models named with `r1`, `reasoning`, `think` (Ollama) are auto-detected as reasoning-capable

### 9. Daemon/Gateway Deployment Env Var Note

If OpenClaw Gateway runs as a systemd/launchd daemon, API keys must be available to that process. Options:
- `~/.openclaw/.env` file
- `env.shellEnv` in config
- Systemd `Environment=` directive

### 10. Config Format

OpenClaw uses **JSON5** format (comments + trailing commas allowed). All fields are optional — safe defaults apply when omitted.

---

## Minimal Production Config Examples

**Anthropic only:**
```json5
{
  env: { ANTHROPIC_API_KEY: "${ANTHROPIC_API_KEY}" },
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } }
}
```

**Multi-provider with fallback:**
```json5
{
  env: {
    ANTHROPIC_API_KEY: "${ANTHROPIC_API_KEY}",
    OPENAI_API_KEY: "${OPENAI_API_KEY}"
  },
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-opus-4-6",
        fallbacks: ["openai/gpt-5.4"]
      }
    }
  }
}
```

**Custom OpenAI-compatible proxy:**
```json5
{
  env: { MY_PROXY_KEY: "${MY_PROXY_KEY}" },
  models: {
    mode: "merge",
    providers: {
      myProxy: {
        baseUrl: "https://api.my-proxy.com/v1",
        apiKey: "${MY_PROXY_KEY}",
        api: "openai-completions",
        models: [{ id: "my-model" }]
      }
    }
  },
  agents: { defaults: { model: { primary: "myProxy/my-model" } } }
}
```

**Local Ollama:**
```json5
{
  env: { OLLAMA_API_KEY: "ollama-local" },
  agents: { defaults: { model: { primary: "ollama/llama3.3" } } }
}
```
