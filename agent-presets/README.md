# Agent presets

## What an agent preset is

A named agent-plane composition. It decides which model-facing tools an agent
gets, whether they are presented as native tool schemas or through the PTC
`run_code` SDK, and what persona (system prompt) the agent runs under.

## How they are declared now

**DSH 0.1.7-rc.2 stopped reading the legacy `$DSH_HOME/.agent-presets/<id>/`
directories.** Presets are now declared as `@deepseek-ai/dsh-agent-preset` rows
in a bundle patch.

On this machine that is the local plugin **`@local/dsh-custom-presets`**,
installed at `/home/vrbkam/dsh-custom-presets` and linked into the profile as
the dependency `link:/home/vrbkam/dsh-custom-presets`, listed in
`dsh.profile.bundles`. Its `cordis.patch.yml` carries both presets.

That patch is **generated, not hand-edited**:

```sh
node /home/vrbkam/dsh-custom-presets/generate-patch.cjs
```

reads the legacy directories, applies one substitution, and rewrites
`cordis.patch.yml`. A copy of the generator is kept in this repository as
`agent-presets/generate-patch.cjs` — so the legacy files here plus that script
reproduce the live bundle exactly.

## The two in use

| id | Name | Source (legacy dir) | Files here |
| --- | --- | --- | --- |
| `custom` | **Productivity Mode** | `$DSH_HOME/.agent-presets/custom/` | `custom-preset.yml`, `custom-agent.cordis.yml` |
| `coding` | Coding mode | `$DSH_HOME/.agent-presets/coding/` | `coding-preset.yml`, `coding-agent.cordis.yml` |

- `custom` was renamed from "Custom mode" to **Productivity Mode** at the
  user's request. Its id stays `custom`, so the registry default and prior
  references keep working.
- The generator applies one substitution when freezing:
  `@deepseek-ai/dsh-workflow-worker-thread` (removed in 0.1.7-rc.2) →
  `@deepseek-ai/dsh-workflow-ptc`, keeping `config.provider: spawn`. That is
  the `workflowEngine` provider row the delegation group's isolate realm
  requires.
- The legacy directories are no longer read by DSH, but they remain the
  **source of truth** the generator freezes from.

Both are user-authored copies of the shipped `standard` preset — the full
coding agent — carrying two deliberate changes:

1. **Tool presentation.** The tail row becomes a `tool-presentation` row with
   `mode: both`: the native tool catalog *and* the PTC `run_code` surface are
   published together, so the model can pick per task.
2. **The persona suffix.** A short instruction to prefer composing multi-step
   work into a single `run_code` program; `coding` extends this into a full
   engineering contract.

`coding` differs from `custom` **only** in its persona suffix and its
`preset.yml` description. See `../prompts/` for the readable text.

## Editing a preset

1. Edit the legacy source: `$DSH_HOME/.agent-presets/<id>/agent.cordis.yml`.
2. Re-freeze: `node /home/vrbkam/dsh-custom-presets/generate-patch.cjs`.
3. Re-copy into this repository (`agent-presets/`) and refresh `prompts/`.
4. Restart `dsh --profile web` — bundle layers compose at boot.

Restating the whole `plugins` entry list matters: Web-editor edits override
`config.plugins` by id from the profile patch, while the frozen file is
loader-edited by decl id.

## Selecting

Default for new sessions, from the `agent-preset-registry` row in
`$DSH_HOME/profiles/web/cordis.patch.yml` (this replaced the old
`settings.yaml` → `agent-presets.default`):

```yaml
- id: agent-preset-registry
  config:
    default: custom
```

Per session: **Settings → General → Agent preset** (also reachable from the
new-session hero chip).

## Maintenance

These are copies of a preset the harness ships, so a DSH upgrade can leave
them behind: shipped preset rows change between versions. Their one structural
divergence from the shipped presets is the tail row — shipped `standard` ends
with `- id: present` / `@deepseek-ai/dsh-tool-present`, and shipped `ptc` pairs
`- id: tool-presentation` (`mode: ptc`) with a separate `- id: present` row,
whereas these presets carry a single `- id: tool-presentation` row with
`mode: both` and no `present` row. (Compared against the shipped presets of
`@deepseek-ai/dsh` 0.1.5-rc.2; re-check after further upgrades.)

After upgrading the harness, diff the copies against
`@deepseek-ai/dsh-agent-presets/presets/standard/agent.cordis.yml` and re-apply
the two changes above, rather than copying the shipped file over wholesale.
