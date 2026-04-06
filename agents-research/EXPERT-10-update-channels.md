# Expert 10: OpenClaw Update & Channels

## Update Mechanism

### Recommended: `openclaw update`
The primary update command. It auto-detects install type (npm or git), fetches the latest version, runs `openclaw doctor`, and restarts the gateway.

```bash
openclaw update
```

### Options
```bash
openclaw update --channel beta    # switch to beta channel
openclaw update --tag main        # target a specific tag
openclaw update --dry-run         # preview without applying
openclaw update --yes             # skip downgrade confirmation
openclaw update --json            # JSON output for scripting
```

### Alternative: Re-run installer
```bash
curl -fsSL https://openclaw.ai/install.sh | bash
# Add --no-onboard to skip onboarding
# For source: --install-method git --no-onboard
```

### Alternative: Direct package managers
```bash
npm i -g openclaw@latest
pnpm add -g openclaw@latest
bun add -g openclaw@latest
```

---

## Channel Switching

OpenClaw ships three update channels:

| Channel  | npm dist-tag | Description |
|----------|-------------|-------------|
| `stable` | `latest`    | Recommended for production. Vetted builds. |
| `beta`   | `beta`      | Pre-release testing. Falls back to `latest` if beta is missing/older. |
| `dev`    | `dev` (when published) | Git `main` branch head. Experimentation only. NOT for production. |

### Switching channels
```bash
openclaw update --channel stable
openclaw update --channel beta
openclaw update --channel dev
```

The `--channel` flag **persists** your choice in `~/.openclaw/openclaw.json` under `update.channel`.

### Channel behavior by install type

**Package installs (npm/pnpm/bun):**
- `stable` → uses npm dist-tag `latest`
- `beta` → prefers npm dist-tag `beta`, falls back to `latest` if beta is missing or older than stable
- `dev` → uses npm dist-tag `dev` (when published)

**Git installs:**
- `stable` → checks out latest stable git tag
- `beta` → prefers latest beta git tag, falls back to stable if beta is missing/older
- `dev` → ensures git checkout, switches to `main`, rebases on upstream, builds, installs CLI from that checkout (default dir `~/openclaw`, override with `OPENCLAW_GIT_DIR`)

### Key insight: `--channel beta` vs `--tag beta`
- `--channel beta` → channel flow that can **fall back** to stable if beta is missing/older
- `--tag beta` → targets raw `beta` dist-tag **one-off** without persisting channel

---

## Version Management

### One-off version/tag targeting with `--tag`
Does NOT persist channel. Next `openclaw update` uses configured channel.

```bash
openclaw update --tag 2026.4.1-beta.1      # specific version
openclaw update --tag beta                 # one-off beta dist-tag
openclaw update --tag main                  # GitHub main branch tarball
openclaw update --tag openclaw@2026.4.1-beta.1  # npm package spec
```

**Note:** `--tag` applies to package installs only. Git installs ignore it.

### Downgrade protection
If target version is older than current version, OpenClaw prompts for confirmation (skip with `--yes`).

### Check current status
```bash
openclaw update status
```
Shows: active channel, install kind (git/package), current version, source (config/git tag/git branch/default)

### Dry run
```bash
openclaw update --dry-run
openclaw update --channel beta --dry-run
openclaw update --tag 2026.4.1-beta.1 --dry-run
openclaw update --dry-run --json
```
Shows: effective channel, target version, planned actions, downgrade confirmation requirement.

### Auto-updater
Off by default. Enable in `~/.openclaw/openclaw.json`:

```json5
{
  update: {
    channel: "stable",
    auto: {
      enabled: true,
      stableDelayHours: 6,
      stableJitterHours: 12,
      betaCheckIntervalHours: 1,
    },
  },
}
```

| Channel  | Auto-update behavior |
|----------|----------------------|
| `stable` | Waits `stableDelayHours`, applies with deterministic jitter across `stableJitterHours` (spread rollout) |
| `beta`   | Checks every `betaCheckIntervalHours` (default: 1h), applies immediately |
| `dev`    | No automatic apply. Use `openclaw update` manually. |

Gateway logs update hint on startup (disable with `update.checkOnStart: false`).

### npm version lookup
```bash
npm view openclaw version   # shows current published version
```

---

## Rollback Procedures

### Pin a version (npm package installs)
```bash
npm i -g openclaw@<version>
openclaw doctor
openclaw gateway restart
```

### Pin a commit (git/source installs)
```bash
git fetch origin
git checkout "$(git rev-list -n 1 --before="2026-01-01" origin/main)"
pnpm install && pnpm build
openclaw gateway restart
```
To return to latest: `git checkout main && git pull`

### After rollback/update checklist
```bash
openclaw doctor              # migrate config, audit DM policies, check gateway health
openclaw gateway restart    # restart the gateway
openclaw health              # verify
```

---

## Plugins and Channels

When switching channels with `openclaw update`, plugins are also synced:
- `dev` → prefers bundled plugins from git checkout
- `stable` and `beta` → restore npm-installed plugin packages
- npm-installed plugins are updated after core update completes

---

## Key Insights for Auto-Deployment

1. **Programmatic channel switch:**
   ```bash
   openclaw update --channel stable   # persists to config
   openclaw update --channel beta
   openclaw update --channel dev
   ```

2. **One-off update without persisting:**
   ```bash
   openclaw update --tag 2026.4.1-beta.1 --yes  # non-interactive
   ```

3. **Dry run for automation safety:**
   ```bash
   openclaw update --dry-run --json   # parseable output for scripts
   ```

4. **Check status programmatically:**
   ```bash
   openclaw update status   # returns channel, install kind, version, source
   ```

5. **Auto-updater config for fleet management:**
   ```json
   {
     "update": {
       "channel": "stable",
       "auto": {
         "enabled": true,
         "stableDelayHours": 6,
         "stableJitterHours": 12
       }
     }
   }
   ```

6. **Rollback via npm pin:**
   ```bash
   npm i -g openclaw@<version> && openclaw doctor && openclaw gateway restart
   ```

7. **Git installs rollback:** Use `git checkout <tag>` then rebuild with `pnpm install && pnpm build`

8. **Gateway restart after any change:**
   ```bash
   openclaw gateway restart
   ```
