# Expert 02: OpenClaw Channels

## Supported Channels

OpenClaw supports **26 chat channels** via its Gateway architecture. All channels can run simultaneously with per-chat routing.

### Full Channel List

| Channel | Type | Protocol/Stack | Notes |
|---|---|---|---|
| Discord | Bot | Discord Bot API + Gateway | Guilds, DMs, threads, forum channels |
| Telegram | Bot | Bot API via grammY (long polling default, webhook optional) | Groups, forum topics, DMs |
| WhatsApp | User | Baileys (WhatsApp Web protocol) | QR pairing required |
| Slack | Bot | Bolt SDK | Workspace apps |
| Microsoft Teams | Bot | Bot Framework | Enterprise |
| Signal | User | signal-cli | Privacy-focused |
| IRC | Bot | Classic IRC servers | DMs + channels |
| Matrix | Bot | Matrix protocol | Bundled plugin |
| Mattermost | Bot | Bot API + WebSocket | Bundled plugin |
| LINE | Bot | LINE Messaging API | Bundled plugin |
| Feishu/Lark | Bot | WebSocket | Bundled plugin |
| Nextcloud Talk | Bot | Nextcloud Talk API | Bundled plugin |
| Nostr | Bot | NIP-04 DMs | Bundled plugin |
| QQ Bot | Bot | QQ Bot API | Bundled plugin |
| Synology Chat | Bot | Webhooks | Bundled plugin |
| Twilio/Signal (Voice) | Plugin | Plivo/Twilio | Separate install |
| WebChat | Web | WebSocket | Built-in |
| BlueBubbles | Bot | BlueBubbles macOS REST API | Recommended for iMessage |
| iMessage (legacy) | User | imsg CLI | Deprecated; use BlueBubbles |
| Tlon | Bot | Urbit messenger | Bundled plugin |
| Twitch | Bot | IRC connection | Bundled plugin |
| WeChat | Bot | Tencent iLink Bot | QR login; private only |
| Zalo | Bot | Zalo Bot API | Bundled plugin |
| Zalo Personal | User | QR login | Bundled plugin |
| Google Chat | Bot | HTTP webhook | |

### Fastest Setup Channels
- **Telegram** — simplest: bot token only, no QR code
- **Discord** — bot token + OAuth2 invite URL
- **WhatsApp** — requires QR pairing, stores state on disk

---

## Configuration Process

### Universal Config Structure

All channels live under `channels` in `openclaw.json` (JSON5 format):

```json5
{
  channels: {
    <channelName>: {
      enabled: true,
      dmPolicy: "pairing",      // "pairing" | "allowlist" | "open" | "disabled"
      allowFrom: ["<id>"],      // sender allowlist (format varies by channel)
      groupPolicy: "allowlist", // "open" | "allowlist" | "disabled"
      groupAllowFrom: ["<id>"], // group sender allowlist
    }
  }
}
```

### Discord — Programmatic Setup

**1. Create bot via Discord Developer Portal:**
- Create Application → add Bot
- Enable **Privileged Gateway Intents**: `Message Content Intent` (required), `Server Members Intent` (recommended)
- Reset Token → save bot token

**2. Generate invite URL:**
- OAuth2 URL Generator → scopes: `bot`, `applications.commands`
- Bot Permissions: View Channels, Send Messages, Read Message History, Embed Links, Attach Files, Add Reactions

**3. Config:**
```json5
{
  channels: {
    discord: {
      enabled: true,
      token: {
        source: "env",
        provider: "default",
        id: "DISCORD_BOT_TOKEN",
      },
      dmPolicy: "pairing",
      groupPolicy: "allowlist",
      guilds: {
        "SERVER_ID": {
          requireMention: true,
          users: ["USER_ID"],
          channels: {
            "general": { allow: true },
            "help": { allow: true, requireMention: true },
          }
        }
      }
    }
  }
}
```

**4. Approve pairing:**
```bash
export DISCORD_BOT_TOKEN="..."
openclaw config set channels.discord.enabled true --strict-json
openclaw gateway
# Then DM the bot in Discord, get pairing code
openclaw pairing list discord
openclaw pairing approve discord <CODE>
```

**Key config fields:**
- `channels.discord.guilds.<id>.requireMention` — default true
- `channels.discord.groupPolicy` — defaults to `allowlist` when block exists
- `channels.discord.streaming` — `off|partial|block|progress` for live previews
- `channels.discord.replyToMode` — `off|first|all|batched`
- `channels.discord.historyLimit` — default 20 for guilds
- `channels.discord.dmHistoryLimit` — for DMs
- `channels.discord.proxy` — HTTP proxy for gateway traffic
- `channels.discord.commands.native` — defaults to `"auto"`
- `channels.discord.ackReaction` — emoji sent while processing
- `channels.discord.configWrites` — allow `/config set|unset` from Discord (default true)

### Telegram — Programmatic Setup

**1. Create bot via @BotFather:**
- `/newbot` → save bot token

**2. Config:**
```json5
{
  channels: {
    telegram: {
      enabled: true,
      botToken: "123:abc",
      dmPolicy: "pairing",          // default
      allowFrom: ["8734062810"],    // numeric Telegram user IDs
      groups: {
        "-1001234567890": {
          requireMention: true,
          allowFrom: ["8734062810"],
        },
        "*": { requireMention: true }
      }
    }
  }
}
```

**Env fallback:** `TELEGRAM_BOT_TOKEN=...`

**3. Approve pairing:**
```bash
openclaw gateway
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

**Key config fields:**
- `channels.telegram.groups` — group ID → config mapping (negative IDs for supergroups)
- `channels.telegram.groupPolicy` — sender policy within groups
- `channels.telegram.groupAllowFrom` — sender IDs (NOT group IDs)
- `channels.telegram.streaming` — default `partial`; edits preview message in-place
- `channels.telegram.webhookUrl` / `webhookSecret` — switch from long polling to webhook mode
- `channels.telegram.customCommands` — menu entries registered at startup
- `channels.telegram.replyToMode` — `off|first|all`
- `channels.telegram.capabilities.inlineButtons` — `off|dm|group|all|allowlist`
- `channels.telegram.actions.{sendMessage,deleteMessage,reactions,sticker,poll}` — per-action gating
- `channels.telegram.historyLimit` — default 50 for groups
- `channels.telegram.ackReaction` — emoji while processing
- Forum topics: `channels.telegram.groups.<id>.topics.<threadId>` with per-topic `agentId` routing
- `channels.telegram.threadBindings` — `/focus` binds thread to ACP session

### WhatsApp — Programmatic Setup

**Note:** Uses Baileys (WhatsApp Web). Bun runtime is **not supported** — use Node.js.

**1. Link via QR code:**
```bash
openclaw plugins install @openclaw/whatsapp
openclaw channels login --channel whatsapp
openclaw channels login --channel whatsapp --account work  # multi-account
```

**2. Config:**
```json5
{
  channels: {
    whatsapp: {
      dmPolicy: "pairing",
      allowFrom: ["+15551234567"],    // E.164 numbers
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15551234567"],
      groups: {
        "*": { requireMention: true }
      }
    }
  }
}
```

**3. Approve pairing:**
```bash
openclaw pairing list whatsapp
openclaw pairing approve whatsapp <CODE>
```

**Key config fields:**
- `channels.whatsapp.accounts.<id>.authDir` / `mediaMaxMb` / `sendReadReceipts` — per-account overrides
- `channels.whatsapp.textChunkLimit` — default 4000
- `channels.whatsapp.chunkMode` — `length|newline`
- `channels.whatsapp.mediaMaxMb` — default 50 (inbound + outbound)
- `channels.whatsapp.historyLimit` — default 50 (pending messages buffered)
- `channels.whatsapp.reactionLevel` — `off|ack|minimal|extensive`
- `channels.whatsapp.ackReaction` — emoji with `direct` and `group` modes
- `channels.whatsapp.configWrites` — default true
- `channels.whatsapp.selfChatMode` — for personal-number setups
- Credential path: `~/.openclaw/credentials/whatsapp/<accountId>/creds.json`

### Other Channels Quick Config

**Signal:**
```json5
{
  channels: {
    signal: {
      enabled: true,
      dmPolicy: "pairing",
      allowFrom: ["+15551234567"],
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15551234567"]
    }
  }
}
```

**Slack:**
```json5
{
  channels: {
    slack: {
      enabled: true,
      dmPolicy: "pairing",
      // tokens via channels.slack.* env/config
    }
  }
}
```

**Matrix:**
```json5
{
  channels: {
    matrix: {
      enabled: true,
      dmPolicy: "pairing",
      groupPolicy: "allowlist",
      groupAllowFrom: ["@owner:example.org"],
      groups: {
        "!roomId:example.org": { allow: true }
      }
    }
  }
}
```

**Microsoft Teams:**
```json5
{
  channels: {
    msteams: {
      enabled: true,
      dmPolicy: "pairing",
      allowFrom: ["user@org.com"]
    }
  }
}
```

---

## Security/Pairing

### DM Pairing Flow

When `dmPolicy: "pairing"` (default for most channels):
1. Unknown sender sends a message → bot replies with an **8-character pairing code** (uppercase, no ambiguous chars `0O1I`)
2. Code expires after **1 hour**
3. Pending requests capped at **3 per channel**
4. Approve via CLI: `openclaw pairing approve <channel> <CODE>`
5. Or ask the agent on an existing channel: `"Approve this <channel> pairing code: <CODE>"`
6. Approved sender IDs stored in `~/.openclaw/credentials/<channel>-allowFrom.json`

**Supported pairing channels:** bluebubbles, discord, feishu, googlechat, imessage, irc, line, matrix, mattermost, msteams, nextcloud-talk, nostr, openclaw-weixin, signal, slack, synology-chat, telegram, twitch, whatsapp, zalo, zalouser

### DM Policy Options

| Policy | Behavior |
|---|---|
| `pairing` (default) | Unknown senders get pairing code; must be approved |
| `allowlist` | Only allowlisted sender IDs can message |
| `open` | Anyone can message (requires `allowFrom: ["*"]`) |
| `disabled` | Block all DMs |

**Important:** DM pairing approval ≠ group authorization. Pairing grants DM access only. Group sender authorization is always **explicit** via `groupAllowFrom` or channel-specific config.

### Group Policy Options

| Policy | Behavior |
|---|---|
| `open` | Groups bypass allowlists; mention gating still applies |
| `disabled` | Block all group messages |
| `allowlist` (default) | Only allowlisted groups/senders can interact |

**Group message evaluation order:**
1. `groupPolicy` check
2. Group allowlist (`groups`, `groupAllowFrom`)
3. Mention gating (`requireMention`, `/activation`)

### Pairing State Storage

```
~/.openclaw/credentials/
  <channel>-allowFrom.json          # default account approved senders
  <channel>-<accountId>-allowFrom.json  # non-default accounts
  <channel>-pairing.json            # pending pairing requests

~/.openclaw/devices/
  pending.json                      # node device pairing pending
  paired.json                       # paired devices + tokens
```

### Node Device Pairing (iOS/Android/macOS/headless nodes)

Nodes connect to Gateway as devices with `role: node`. Two pairing methods:

**1. CLI method:**
```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
```

**2. Telegram (recommended for iOS):**
1. `/pair` in Telegram → bot replies with setup code
2. Open OpenClaw iOS app → Settings → Gateway → paste setup code
3. `/pair pending` in Telegram → review → `/pair approve <requestId>`

Setup code is base64-encoded JSON containing:
- Gateway WebSocket URL
- Short-lived bootstrap token

Bootstrap token carries limited scopes: `operator.approvals`, `operator.read`, `operator.talk.secrets`, `operator.write`

### Security Audit

```bash
openclaw security audit
openclaw security audit --deep    # includes live Gateway probe
openclaw security audit --fix      # auto-fix common issues
openclaw security audit --json
```

What it checks:
- Inbound access (DM/group policies, allowlists)
- Tool blast radius (elevated tools + open rooms)
- Exec approval drift
- Network exposure (bind/auth settings)
- Browser control exposure
- Filesystem permissions
- Plugin security
- Policy drift/misconfig

### Hardened Baseline Config

```json5
{
  gateway: {
    mode: "local",
    bind: "loopback",
    auth: { mode: "token", token: "replace-with-long-random-token" },
  },
  session: {
    dmScope: "per-channel-peer",
  },
  tools: {
    profile: "messaging",
    deny: ["group:automation", "group:runtime", "group:fs", "sessions_spawn", "sessions_send"],
    fs: { workspaceOnly: true },
    exec: { security: "deny", ask: "always" },
    elevated: { enabled: false },
  },
  channels: {
    whatsapp: { dmPolicy: "pairing", groups: { "*": { requireMention: true } } },
  }
}
```

### Context Visibility

Controls supplemental context filtering (quoted text, thread history):

| Setting | Behavior |
|---|---|
| `all` (default) | Keep context as received |
| `allowlist` | Filter to allowlisted senders only |
| `allowlist_quote` | `allowlist` + one explicit quote exception |

Set per channel or per room via `channels.<channel>.contextVisibility`.

---

## Key Insights for Auto-Deployment

### 1. Channel Configuration is Purely Declarative JSON5

All channel settings are in `openclaw.json` under `channels.<name>`. No interactive prompts needed for automation. Tokens can use SecretRef (env/file/exec providers) to avoid plaintext secrets in config.

### 2. Token Management

| Channel | Token Type | Env Fallback |
|---|---|---|
| Discord | Bot token | `DISCORD_BOT_TOKEN` |
| Telegram | Bot token | `TELEGRAM_BOT_TOKEN` |
| WhatsApp | Session (Baileys) | QR link via `openclaw channels login` |
| Signal | signal-cli | Via `channels.signal.*` config |
| Slack | OAuth token | `channels.slack.*` env |

### 3. Fastest Channel to Automate: Telegram

Telegram requires only a bot token — no OAuth flows, no QR codes, no browser automation:
```bash
# 1. Get token from @BotFather
# 2. One-time gateway start with token
export TELEGRAM_BOT_TOKEN="..."
openclaw config set channels.telegram.botToken --ref-source env --ref-id TELEGRAM_BOT_TOKEN
openclaw config set channels.telegram.enabled true --strict-json
openclaw gateway
# 3. Auto-approve first DM pairing programmatically
openclaw pairing approve telegram <CODE>
```

### 4. WhatsApp Requires Interactive QR (Single Point of Friction)

WhatsApp cannot be configured purely programmatically — it requires scanning a QR code via `openclaw channels login --channel whatsapp`. This must happen once per account and produces a session file at `~/.openclaw/credentials/whatsapp/<accountId>/`. For auto-deployment at scale, use a **dedicated number** per instance.

### 5. Multi-Account Support

Most channels support multiple accounts via `channels.<channel>.accounts.<accountId>`:
```json5
{
  channels: {
    telegram: {
      accounts: {
        main: { enabled: true, botToken: "..." },
        work: { enabled: true, botToken: "..." }
      }
    },
    whatsapp: {
      accounts: {
        personal: { enabled: true, authDir: "~/.openclaw/credentials/whatsapp/personal" },
        work: { enabled: true, authDir: "~/.openclaw/credentials/whatsapp/work" }
      }
    }
  }
}
```

### 6. Group Behavior is Fail-Closed by Default

- `groupPolicy: "allowlist"` is the default when a `channels.<channel>` block exists
- If the block is **absent entirely**, runtime falls back to `allowlist` (with a warning log)
- This means **all group access is blocked by default** until explicitly allowlisted

### 7. Pairing Store is DM-Only

Pairing approvals (the `*-allowFrom.json` store) apply **only to DMs**. Group authorization requires explicit `groupAllowFrom` or channel-specific group allowlists. This is a common misconfiguration.

### 8. Discord Guild Config Requires Numeric IDs

- Prefer numeric IDs over names/slugs in `channels.discord.guilds`
- Enable Developer Mode in Discord to copy IDs
- Name/tag matching is disabled by default (`dangerouslyAllowNameMatching: true` for break-glass)

### 9. Telegram: Long Polling vs Webhook

- Default: long polling (grammY runner)
- For production/high-traffic: set `channels.telegram.webhookUrl` + `webhookSecret`
- Webhook binds to `127.0.0.1:8787` by default; use reverse proxy for public URL

### 10. Shared Inbox Pattern

For shared bots where multiple users can DM:
```json5
{
  session: { dmScope: "per-channel-peer" },  // isolate DMs per sender
  channels: {
    telegram: { dmPolicy: "allowlist", allowFrom: ["123456", "789012"] }
  },
  tools: {
    deny: ["group:automation", "group:runtime", "group:fs", "sessions_spawn"]
  }
}
```

### 11. Channel Troubleshooting Checklist

When a channel isn't working:
1. `openclaw channels status` — check link state
2. `openclaw logs --follow` — real-time gateway logs
3. `openclaw doctor` — auto-detect and fix common issues
4. For WhatsApp specifically: Bun runtime warning — must use Node.js

### 12. Role-Based Agent Routing

Discord supports routing to different agents based on Discord role IDs:
```json5
{
  bindings: [
    {
      agentId: "opus",
      match: { channel: "discord", guildId: "...", roles: ["roleId"] }
    }
  ]
}
```

### 13. Forum Topics / Thread Routing

Telegram forum topics and Discord threads get their own session keys. Telegram supports per-topic `agentId` routing for isolation:
```json5
{
  channels: {
    telegram: {
      groups: {
        "-1001234567890": {
          topics: {
            "1": { agentId: "main" },
            "3": { agentId: "coder" },
            "5": { agentId: "research" }
          }
        }
      }
    }
  }
}
```

### 14. Auto-Deployment Script Template

```bash
#!/bin/bash
# 1. Set channel token
export TELEGRAM_BOT_TOKEN="..."

# 2. Write channel config
cat >> /home/ubuntu/.openclaw/openclaw.json << 'EOF'
{
  channels: {
    telegram: {
      enabled: true,
      botToken: { source: "env", provider: "default", id: "TELEGRAM_BOT_TOKEN" },
      dmPolicy: "allowlist",
      allowFrom: ["OWNER_ID"],
      groups: { "*": { requireMention: true } },
      groupPolicy: "allowlist"
    }
  }
}
EOF

# 3. Start gateway
openclaw gateway &

# 4. Wait for pairing request
sleep 5
CODE=$(openclaw pairing list telegram 2>/dev/null | grep -o '[A-Z]\{8\}' | head -1)
if [ -n "$CODE" ]; then
  openclaw pairing approve telegram "$CODE"
fi
```

---

## Summary: Programmatically Configure Channels

1. **Telegram/Discord**: Set bot token in env → `openclaw config set` → `openclaw gateway` → auto-works
2. **WhatsApp**: Requires `openclaw channels login --channel whatsapp` for QR scan (once per account)
3. **All channels**: Configure `dmPolicy` + `allowFrom` for DM access, `groupPolicy` + `groupAllowFrom` for group access
4. **Pairing**: `openclaw pairing approve <channel> <CODE>` or approve via agent on another channel
5. **Fail-closed**: All group access defaults to `allowlist` — must explicitly configure groups
6. **Security**: Run `openclaw security audit --fix` as part of deployment to auto-lock down policies
