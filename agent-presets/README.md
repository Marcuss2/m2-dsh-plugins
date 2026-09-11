# Agent presets

## What an agent preset is

A named agent-plane composition. It decides which model-facing tools an agent
gets, whether they are presented as native tool schemas or through the PTC
`run_code` SDK, and what persona (system prompt) the agent runs under.

Presets live at:

```
$DSH_HOME/.agent-presets/<id>/
  preset.yml         # metadata: name, description, order
  agent.cordis.yml   # the composition itself
```

Shipped presets (`minimal`, `ptc`, `standard`, `cordis`) live in
`@deepseek-ai/dsh-agent-presets/presets/` and are listed in the GUI alongside
the user ones.

## The two in use

| id | name | Files here | Role |
| --- | --- | --- | --- |
| `custom` | Custom mode | `custom-preset.yml`, `custom-agent.cordis.yml` | Default for new sessions |
| `coding` | Coding mode | `coding-preset.yml`, `coding-agent.cordis.yml` | The same agent plus an engineering contract in its persona |

The files are stored flat with the preset id as a prefix; drop the prefix when
installing, so `custom-preset.yml` becomes `custom/preset.yml`.

Both are user-authored copies of the shipped `standard` preset — the full
coding agent — carrying two deliberate changes:

1. **Tool presentation.** The tail row becomes a `tool-presentation` row with
   `mode: both`: the native tool catalog *and* the PTC `run_code` surface are
   published together, so the model can pick per task — plain native calls for
   simple steps, one model-authored TypeScript program to compose multi-step
   work into a single round trip.
2. **The persona suffix.** A short instruction to prefer composing multi-step
   work into a single `run_code` program; `coding` extends this into a full
   engineering contract.

`coding` differs from `custom` **only** in its persona suffix and its
`preset.yml` description. The extra text adds a phased workflow — Scope,
Research, Decompose, Implement, Verify, Cleanup — and a `Verify` section that
requires deliverable proof (named commands and their output) before any
non-trivial work may be reported done.

## Install

```sh
mkdir -p "$DSH_HOME/.agent-presets/custom" "$DSH_HOME/.agent-presets/coding"
cp agent-presets/custom-preset.yml       "$DSH_HOME/.agent-presets/custom/preset.yml"
cp agent-presets/custom-agent.cordis.yml "$DSH_HOME/.agent-presets/custom/agent.cordis.yml"
cp agent-presets/coding-preset.yml       "$DSH_HOME/.agent-presets/coding/preset.yml"
cp agent-presets/coding-agent.cordis.yml "$DSH_HOME/.agent-presets/coding/agent.cordis.yml"
```

`DSH_HOME` defaults to `~/.dsh`. No restart is needed to *see* a new preset;
it is picked up when a session starts.

## Selecting

Per session: **Settings → General → Agent preset** (also reachable from the
new-session hero chip).

As the default for new sessions, in `$DSH_HOME/settings.yaml`:

```yaml
agent-presets:
  default: custom
```

## Maintenance

These are copies of a preset the harness ships, so a DSH upgrade can leave
them behind: shipped preset rows change between versions. On 0.1.5-rc.1, for
example, the shipped `standard` preset ends with `- id: present` /
`@deepseek-ai/dsh-tool-present`, and the shipped `ptc` preset shows the
grouped `tool-presentation` form — neither matches these files exactly.

After upgrading the harness, diff the copies against
`@deepseek-ai/dsh-agent-presets/presets/standard/agent.cordis.yml` and re-apply
the two changes above, rather than copying the shipped file over wholesale.

The prompt text these presets carry is also recorded, readably, in
`../prompts/`.
