# machine-wide-ptc — Code Mode (PTC) for every profile

## What it is

Two composition rows in the DSH **home-level patch layer**
(`$DSH_HOME/cordis.patch.yml`) that switch the whole machine's deployment
default from native function calling to **Code Mode** (PTC — programmatic tool
calling), the capability already shipped inside stock `dsh`:

- `id: tools → mode: code` — agents that declare no presentation of their own
  see the reserved `run_code` transport plus a generated TypeScript SDK
  instead of per-tool schemas: a multi-step sequence becomes one program with
  `await tools.<name>({...})` bindings, each binding re-entering the complete
  tool pipeline (so sandboxing and `ask` approvals still gate risky calls,
  just mid-program). Under `code`, calling any other tool directly resolves
  to `UNKNOWN_TOOL` by design.
- `insert: code-runtime` — guarantees the `@deepseek-ai/dsh-code-runtime-
  worker-thread` provider (the Code Mode worker) for **every** profile. The
  `web` and `headless` bundles insert the identical row themselves (patch
  composition keys rows by `id`, so no duplicate instance); a custom profile
  mounting neither would otherwise fail prompt assembly in non-native modes.

The full definition is the verbatim artifact
[`cordis.patch.yml`](cordis.patch.yml) in this directory.

## Why (checked per ground rule 1)

PTC is useful for every agent and saves tokens: one `run_code` round trip
replaces N assistant-turn/tool-result round trips, intermediate results get
filtered inside the program instead of re-projected into model context, and
the fixed prompt is one transport schema plus the SDK block instead of every
tool schema. Reuse-before-reinvention held throughout:

- **No plugin provides PTC itself** — the 2026-08-29 sweep of the dshmarket
  index (`https://awesome-dsh-plugin.com/plugins.json`, 2495 entries, plus
  npm) found only *extensions* of the builtin (`dsh-ptc-plus` persistent
  REPL, `dsh-minimal-ptc` preset, `dsh-ptc-cordis-preset`,
  `dsh-agent-preset-router`, `dsh-code-runtime-container`, `dsh-fail-logger`);
  every one assumes Code Mode already exists. Nothing to install.
- The stock install already ships the **`code` agent preset** (roster name
  "PTC 模式") for a per-session switch, and `dsh-web-app` carries a
  TEMPORARY `DSH_TOOLS_MODE` env seam — both are per-something; the home
  patch is the one mechanism that is machine-wide by design ("machine-local
  preferences that apply to every profile", ranked above each profile's own
  layers, below explicit `--patch` overlays).

This entry records only the **override**; the machinery is shipped baseline.

## Dependencies

None beyond a stock DSH install: `dsh-tools`, the `code` preset, and
`@deepseek-ai/dsh-code-runtime-worker-thread` all ride inside the global `dsh`
package. No profile bundle, no pnpm, no machine software — `DEPENDENCIES.md`
is untouched, and nothing can hoist a core duplicate (ground rule 2 not
applicable).

## Install

1. Target: `$DSH_HOME/cordis.patch.yml` (normally `~/.dsh/cordis.patch.yml`).
   It does **not** exist on a baseline install.
2. If the target does not exist: copy
   `$KIT/plugins/machine-wide-ptc/cordis.patch.yml` verbatim.
3. If the target exists: it is user-authored home-layer content — merge.
   Ensure the `insert:` block carries the `code-runtime` row and the
   `id: tools` row resolves to `mode: code`, preserving every other user row.
4. Do NOT write this into a profile's own `cordis.patch.yml`: that only
   covers one profile and loses the point.

## Activation

Layers compose at boot: restart `dsh --profile web` (and any other running
profile process) — running sessions keep their current tool surface until
then, so piggyback this restart on the Step 4 plugin restart in
`RESTORE.md`.

## Verify

1. `setup/verify.sh` section 7 compares the live file against the kit copy.
2. `dsh --profile web --dump-config`: the composed `- id: tools` row shows
   `mode: code` under a provenance header naming `$DSH_HOME/cordis.patch.yml`,
   and the home layer's own section lists the inserted `code-runtime` row.
   Patch composition keys rows by `id`, so the home insert replaces the
   bundle's identical row — one worker instance at runtime, one listing per
   contributing layer in the dump.
3. Functional (after the restart, in a NEW session): the tool catalog offers
   `run_code` with a TypeScript SDK section; ask for something two-tool-deep
   (e.g. "list the top-level files and report how many are markdown") and the
   answer arrives from one program, not two native calls.
4. Rollback: set `mode: native` (or delete the `tools` row) and restart; a
   `both` middle ground exposes native schemas *and* `run_code` if a model
   proves unreliable at writing tool programs.

## Interacts with

- Per-preset selection still shadows the default: only the stock `code` preset
  carries its own `@deepseek-ai/dsh-agent-tool-presentation` row (`mode:
  code`), and a locally-authored preset can add one — sessions on such
  presets get the preset's answer, not the deployment default. `standard`,
  `minimal` and `cordis` declare none, so this home-layer row governs them.
  Subagent/workflow children bind to their parent's composition.
- Market extensions (`dsh-ptc-plus` etc., see Why above) install on top of a
  profile *after* this is active; none of them is required.
