# subagent-model-routing (agent preset)

## What it is

Runs **powerful root model + cheaper coding model for delegated children**.
Mechanism (all shipped core, no new plugin):

- `@deepseek-ai/dsh-tool-subagent`'s row config accepts
  `agentOptions: { provider?, model?, maxTokens? }` — "Agent options applied to
  every child". The tool stamps it on each spawn request;
  `dsh-subagent-in-process-driver` resolves the child route via
  `resolveChildAgentOptions(parent, request.agentOptions, depth)`: the parent's
  provider/model/maxTokens **unless overridden** (override wins).
- On Web, the model-facing delegation tools are NOT host rows
  (`dsh-web-app/cordis.patch.yml` disables the base `tool-subagent`/`
  `tool-subagent-fork` rows) — each session composes them from an **agent
  preset**: shipped roots `<dsh-install>/config/agent-presets/{code,cordis,
  minimal,standard}`, writable root `$DSH_HOME/.agent-presets` (same trust;
  default preset per `agent-presets` row config: `standard`).
- Children **inherit the parent's live preset**
  (`applyChildComposition → agentPresets.composeFrom(childCtx, parent.ctx)`),
  so pinning the route in the preset covers grandchildren too.
- Escape hatches that do NOT need a preset change: `workflow` script `agent()`
  opts take per-child `provider`/`model`; `dsh-llm-fallbacks` role chains
  (`fallbacks.roles.list[].chain`) route *failure walks* per declared role.

## Kit artifact

`code-subagent-flash/` — a copy of the shipped `code` preset with
`agentOptions: { provider: qwencloud, model: qwen3.8-flash }` added to both
delegation rows (`subagent` continuable + `subagent_fork`). Materialize at
`$DSH_HOME/.agent-presets/code-subagent-flash/`.

## Install

1. `cp -r $KIT/plugins/subagent-model-routing/code-subagent-flash \
   $DSH_HOME/.agent-presets/`
2. Restart `dsh --profile web` (preset roster rescans at boot).
3. In the GUI: Settings → General → **Agent preset** row → pick **"Code
   (subagents on qwen3.8-flash)"** (the blank-session hero chip opens the same
   picker). The choice is the default for new sessions; a running session
   switches via its header label. Children inherit the parent's LIVE preset.

Adjust `provider`/`model` to the target machine's routes (this machine:
qwencloud offers `qwen3.8-max` / `qwen3.8-flash`; root stays whatever the
session selects — e.g. flash now, max later; only children are pinned).

## Verify

- Spawn any background subagent, then open its child session (sidebar monitor
  "Open chat" or header lineage): its composer model chip shows the pinned
  model while the parent keeps its own.
- Host log line per child creation carries the resolved route.

## Rollback

Delete `$DSH_HOME/.agent-presets/code-subagent-flash` and switch sessions
back to `code`/`standard`.
