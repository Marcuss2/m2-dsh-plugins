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
`dsh.profile.bundles`. Its `cordis.patch.yml` carries all four presets.

That patch is **generated, not hand-edited**:

```sh
node /home/vrbkam/dsh-custom-presets/generate-patch.cjs
```

reads the legacy directories, applies the rc.2 transforms listed below, and
rewrites `cordis.patch.yml`. A copy of the generator is kept in this
repository as `agent-presets/generate-patch.cjs` — byte-identical to the live
one — so the sources here plus that script reproduce the installed bundle
exactly (verified 2026-10-19 and re-verified 2026-11-25 by regenerating in a
scratch directory and diffing against
`/home/vrbkam/dsh-custom-presets/cordis.patch.yml`).

## The four in use

All four source directories live under
`/home/vrbkam/dsh-custom-presets/legacy-agent-presets-pre-rc2/`.

| id | Name | Source (legacy dir) | Files here |
| --- | --- | --- | --- |
| `custom` | **Productivity Mode** | `legacy-agent-presets-pre-rc2/custom/` | `custom-preset.yml`, `custom-agent.cordis.yml` |
| `coding` | Coding mode | `legacy-agent-presets-pre-rc2/coding/` | `coding-preset.yml`, `coding-agent.cordis.yml` |
| `computeruse` | **Computer Use** | `legacy-agent-presets-pre-rc2/computeruse/` | `computeruse-preset.yml`, `computeruse-agent.cordis.yml` |
| `orchestrator` | **Orchestrator** | `legacy-agent-presets-pre-rc2/orchestrator/` | `orchestrator-preset.yml`, `orchestrator-agent.cordis.yml` |

- `custom` was renamed from "Custom mode" to **Productivity Mode** at the
  user's request. Its id stays `custom`, so the registry default and prior
  references keep working.
- `computeruse` (added 2026-10-15) is a copy of `custom` plus two rows before
  the presentation row: `mcp-computer-use-linux`
  (`@deepseek-ai/dsh-mcp-client`, `serverName: cul`, stdio) and
  `dsh-computer-use-linux` (the plugin's JS entry — registers the bundled
  skill, claims the sole computer-use provider slot). Both consume host
  registries and provide nothing, so like the tool rows they need no realm.
  This preset is the ONLY mount of the desktop computer-use capability: the
  web profile does not list the plugin bundle, so no other preset sees the
  `mcp__cul__*` tools. The plugin package stays a profile **dependency**
  because the `!!js` launcher resolution is anchored at the profile's
  `package.json`. Its persona adds the computer-use paragraph
  (`../prompts/computeruse-persona.md`).
- `orchestrator` (added 2026-10-24) is the `custom` composition row for
  row — the same tools, the same `mode: ptc` presentation, the same plan mode
  and delegation group — with a persona that makes delegation the default. It
  differs from `custom` only in the persona `prefix` and `suffix` and in its
  `preset.yml` description. The suffix is **role-aware**: a teammate spawned by
  `spawn_teammate` inherits the parent's preset, so the same text renders for
  the Lead and for every member, and each role gets its own paragraph. See
  `../prompts/orchestrator-persona.md`.
- The generator applies six transforms when freezing, so a source written
  against an older harness still freezes correctly:
  1. `@deepseek-ai/dsh-workflow-worker-thread` (removed in 0.1.7-rc.2) →
     `@deepseek-ai/dsh-workflow-ptc`, keeping `config.provider: spawn`. That
     is the `workflowEngine` provider row the delegation group's isolate realm
     requires.
  2. Drops a `Your working directory is {{cwd}}.` line from the persona suffix
     — rc.2 registers only `provider` and `model` as prompt variables.
  3. Rewrites `mode: both` → `mode: ptc` on the presentation row — rc.2
     accepts only `native` and `ptc`.
  4. Drops the `tool-subagent-list-agents` row. DSH 0.2.2-rc.1 merged the
     globally named `list_agents` tool into `@deepseek-ai/dsh-tool-subagent-control`
     and removed its `/list-agents` subpath export, so a preset that still
     mounts the separate row audits as `never started` and fails the whole
     mount — the symptom was `New session failed: agent-preset/invalid:
     tool-subagent-list-agents ...: never started`.
  5. Rewrites `modelSelectionSettings: true` → `modelSelection: true` plus
     `modelDiscovery: true`, and drops the `backgroundMode` key: 0.2.2-rc.1
     replaced the old switch and removed the old background-mode option.
  6. Collapses the runs of empty lines left where it stripped the legacy
     files' commentary.

  The current sources already carry transforms 2 and 3, so they are no-ops on
  a refresh, and regeneration is idempotent.
- The legacy directories are no longer read by DSH, but they remain the
  **source of truth** the generator freezes from.

All four are user-authored copies of the shipped `standard` preset — the full
coding agent — carrying two deliberate changes:

1. **Tool presentation.** The tail row becomes a `tool-presentation` row with
   `mode: ptc`: the model sees only the `run_code` transport plus the generated
   SDK, and native tool schemas are not listed. (`native` and `ptc` are the
   only accepted values; the `both` mode these presets used before DSH
   0.2.1-rc.2 was removed and fails the row's schema.)
2. **The persona suffix.** A short instruction to prefer composing multi-step
   work into a single `run_code` program, a paragraph stating that the `code`
   argument is an async function **body** (no `main()` to declare, with a
   hello-world example — see `../prompts/README.md`) and that the call itself
   needs its own `description` beside `code` (a nested `tools.bash(...)` one
   does not count), the browser-access line
   (`agent-browser` is a CLI on PATH, not a mounted tool — the persona is how
   an agent learns it exists), and the **Ask before you guess** paragraph that
   names `ask_user_question` as the channel for user-owned decisions; `coding`
   extends this into a full engineering contract.

Neither suffix references `{{cwd}}`: the loop registers only `provider` and
`model`, an unresolved variable fails prompt assembly before any model request,
and the working directory arrives as required runtime context.

`coding` differs from `custom` **only** in its persona suffix and its
`preset.yml` description. `orchestrator` likewise adds no tool: it keeps the
`custom` rows untouched and changes only the persona. See `../prompts/` for the
readable text.

The `run_code`-is-a-function-body, `run_code`-description, **Language**, and
**Ask before you guess** paragraphs are carried verbatim by all four presets.
The last exists because models were observed ignoring `ask_user_question` —
answering in prose or guessing silently; the first two exist because models
were observed wrapping the program in `main()` or omitting the envelope's
`description`. The generated PTC SDK describes the calls; the persona reinforces
their shape and when to make them.
Keep the paragraph byte-identical across presets, and keep its wording aligned
with `../prompts/plan-mode.md`, which governs asking while in plan mode.

The `orchestrator` persona also carries the shared `run_code`, **Language**, and
browser-access paragraphs verbatim; its own text is additive (the cost framing, a delegation
ladder, the Lead/teammate split, brief-writing, coordination, and verification),
never a rewrite of the shared rules. When editing those shared paragraphs,
update all four sources together.

### Language rule, and why it is in two places

Every preset carries the same **Language** paragraph (see
`../prompts/README.md`), and the identical rule is repeated in
`$DSH_HOME/AGENTS.md` — the user-global instruction chain that
`dsh-agent-instructions` loads into every session. The duplication is
deliberate: the persona covers preset sessions, the global file covers
everything else (including a preset that predates the paragraph), and the rule
guards against a per-turn competitor — this profile's web-search tool ships
Chinese tool-schema descriptions, so foreign-language text keeps arriving.

When editing the paragraph, change the persona sources and `$DSH_HOME/AGENTS.md`
together, or the two layers will drift.

## Editing a preset

1. Edit the legacy source:
   `/home/vrbkam/dsh-custom-presets/legacy-agent-presets-pre-rc2/<id>/agent.cordis.yml`
   (and `<id>/preset.yml` for the card's `name` / `description`).
2. Re-freeze: `node /home/vrbkam/dsh-custom-presets/generate-patch.cjs`, and
   check the result with `dsh --profile web --dump-config`.
3. Re-copy into this repository (`agent-presets/`) and refresh `prompts/`.
4. Reload `dsh --profile web`. Bundle layers compose at boot; this profile has
   HMR enabled, so a rewritten patch is also picked up by the running host.

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
them behind: shipped preset rows change between versions. Re-checked against
`@deepseek-ai/dsh` **0.2.2-rc.5** (2026-11-25), where the shipped presets still
live as patch files at
`node_modules/@deepseek-ai/dsh-web-app/presets/{standard,ptc,minimal,cordis}.patch.yml`
and `ptc.patch.yml` still mounts `tool-executor-ptc` followed by `present`.
Two divergences from that `standard`/`ptc` pair remain:

- **Tail rows.** Shipped `ptc` now mounts `@deepseek-ai/dsh-tool-executor-ptc`
  directly and ships a bare `present` row; the old `tool-presentation`
  (`mode: ptc`) row is deprecated but still functional. These presets still
  carry `tool-presentation` (`mode: ptc`) and no `present` row — the tail they
  have carried since the 0.1.x copies. Moving to `tool-executor-ptc` is a
  future cleanup, not a requirement.
- **Persona.** The shipped presets carry only `persona.prefix`; these add the
  suffix described above.

After upgrading the harness, diff the copies against those shipped patch files
and re-apply the changes above, rather than copying the shipped file over
wholesale.