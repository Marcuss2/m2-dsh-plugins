# dsh-subagent-router

## What it is

A **model-routed subagent delegation** plugin for DeepSeek Harness (npm
`dsh-subagent-router`, author NinjaSln-labs, MIT). Adds three tools that let
the main agent — or the user via a **Settings UI card** — pick a cheaper /
faster model for every subagent, per call or automatically:

| Tool | Purpose |
|------|---------|
| `subagent_model` | Delegate a task with per-call `provider` / `model` / `max_tokens` overrides. Pass `model: "auto"` to use the built-in routing policy. |
| `subagent_models` | Read-only catalog: lists registered provider routes and their advertised models with derived metadata (cost / speed / strength / specialty / context window) plus health status. |
| `subagent_recommend` | Task description → ranked provider/model suggestions (top-n). Uses a lightweight LLM classification anchored to the parent model; falls back to naming heuristics on failure. |

The stock `subagent` tool inherits the parent's model route. This plugin adds
a **sister tool** where the delegation model picks the child's LLM route —
while everything else (depth accounting, continuable background children,
result collection) still goes through the standard `ctx.subagents` channel.

### Settings UI

The plugin ships a client half (`dsh.client.platform: web`) that injects into
`@deepseek-ai/dsh-client-ui-settings`. A **`subagent-router` card** appears in
Settings → Plugin Configuration with live-editable fields:

| Field | Default | Meaning |
|-------|---------|---------|
| `autoEscalate` | `true` | Retry with a higher tier on transient failure (foreground only). |
| `autoReroute` | `true` | Switch to a healthy provider on terminal failure (quota/auth). |
| `autoEscalationTiers` | `1` | Max escalation retries on the same provider. |
| `autoProviderOrder` | — | Provider priority list for `model: "auto"`. Unlisted providers sort after. |
| `autoTierPolicy` | — | Per-tier selection mode: `{ trivial|standard|complex: 'anchor'|'cheapest'|'strongest' }`. |
| `autoTierPicks` | — | Per-tier explicit candidate order: `{ trivial|standard|complex: [modelId, ...] }`. |
| `recommendTimeoutMs` | `8000` | Timeout for the LLM classification call in `subagent_recommend` (1000–60000). |

All fields are **live**: edits write to the user settings layer
(`~/.dsh/settings.yaml` → `subagent-router` section) and take effect on the
next `subagent_model` call — no restart needed. Clearing a field falls back to
the composition-row config.

### Auto-routing (`model: "auto"`)

A deterministic, auditable strategy — no extra LLM call unless using
`subagent_recommend`:

1. **Provider resolution**: explicit `provider` param wins; otherwise the
   caller agent's own route.
2. **Task tiering**: `trivial` (≤160 chars, no heavy markers), `complex`
   (≥1200 chars or code blocks / reasoning verbs), else `standard`.
3. **Anchor to parent model**: if the caller named a model on the resolved
   provider, use it for `trivial`/`standard`; for `complex`, keep it only if
   it's already a strong model (`pro`/`max`/`reason`/`think`/`ultra`/`code`/
   `turbo`/`large`/`deep`). Otherwise fall back to catalog scoring.
4. **Auditable**: every auto call records `{ provider, model, tier, reason,
   anchored?, escalatedFrom?, reroutedFrom? }` in the tool result.
5. **Failure recovery** (foreground only): transient failures escalate one
   tier (never downgrades an anchored strong model); terminal failures
   (quota/auth) reroute to the first healthy provider.
6. **Health-aware**: tracks per-provider failure classes in-session; once a
   route is unhealthy, stops anchoring to it.

## Why this plugin (checked per ground rule 1)

The existing entry 13 (`subagent-model-routing/`) uses an **agent preset** to
pin children to a fixed cheaper model. That works but has no GUI, no per-call
override, no auto-routing, and no catalog/recommend tools. This plugin
complements it: the preset sets a baseline default; `subagent_model` lets the
model (or the user via Settings) override per call. They compose — keep the
preset as the floor and use this plugin for dynamic routing.

No shipped DSH plugin offers a visual subagent model picker with auto-routing.
Checked the ecosystem (2628+ entries); closest alternatives
(`dsh-subagent-model-picker` by ringoage) were renamed to this package.

## Dependencies

- All `@deepseek-ai/*` packages are **peerDependencies** only — ground rule 2
  satisfied. One regular dependency: `@deepseek-ai/schemastery` (already
  hoisted at the installed version by 7+ existing plugins; not a core
  singleton, covered by the profile's `overrides` pin).
- Client half injects `@deepseek-ai/dsh-client-runtime` and
  `@deepseek-ai/dsh-client-ui-settings` (both peers).
- No machine-level software required.

## Install

```sh
cd ~/.dsh/profiles/web && PATH=/usr/bin:$PATH pnpm add dsh-subagent-router
```

Then add `"dsh-subagent-router"` to `dsh.profile.bundles` in the profile's
`package.json`. Restart `dsh --profile web` to activate.

Or in one step via the DSH CLI (when its bundled pnpm wrapper works):

```sh
dsh plugin --profile web add dsh-subagent-router
```

## Verify

1. `setup/verify.sh` reports the bundle layer in §3 and §4.
2. In a new session after restart: `subagent_models` returns the provider
   catalog; `subagent_model` with explicit `provider`/`model` spawns a child
   on that route.
3. Settings → Plugin Configuration shows the `subagent-router` card; edits
   take effect without restart.
4. Ground rule 2: `~/.dsh/profiles/web/node_modules/@deepseek-ai/` should
   still contain only `cosmokit` and `schemastery` (no new core shadows).

## Rollback

```sh
cd ~/.dsh/profiles/web && PATH=/usr/bin:$PATH pnpm remove dsh-subagent-router
```

Remove `"dsh-subagent-router"` from `dsh.profile.bundles` and restart.
