# machine-wide-ptc — Code Mode alongside native tools, for every profile

## What it is

One composition row in the DSH **home-level patch layer**
(`$DSH_HOME/cordis.patch.yml`) that turns on **Code Mode** (PTC — programmatic
tool calling) for the whole machine — the capability already shipped inside stock
`dsh` — **alongside** native function calling, by setting `mode: both`:

- `id: tools → mode: both` — agents that declare no presentation of their own
  see the ordinary per-tool schemas **and** the reserved `run_code` transport
  plus its generated TypeScript SDK. The model picks per step: one program with
  `await tools.<name>({...})` bindings for a multi-step sequence, or a plain
  direct call for a single tool. Every binding still re-enters the complete tool
  pipeline (so sandboxing and `ask` approvals still gate risky calls, just
  mid-program). `mode: code` is the stricter variant: it collapses the surface to
  `run_code` alone, so a direct call naming any other tool resolves to
  `UNKNOWN_TOOL` — everything is forced through programs. That was this entry's
  original setting (2026-08-29 → 08-30); it is kept documented as a rollback.

The `code-runtime` worker row is deliberately **not** inserted here. Both
shipped surface bundles — `@deepseek-ai/dsh-web-app` and
`@deepseek-ai/dsh-headless` — already insert the identical
`@deepseek-ai/dsh-code-runtime-worker-thread` row, and in dsh 0.1.1-rc.2 an
`insert:` from the home layer is *concatenated* onto the composed entry list
(`dsh-app-boot` `applyEntryPatches`), so a home-layer insert collides with the
bundle's row and the loader throws `duplicate loader entry id: code-runtime`,
refusing to boot the profile. (Inserts are keyed by nothing; only override
patches target rows by `id`.) A CUSTOM profile that mounts **neither** bundle
MUST insert `- id: code-runtime / name:
'@deepseek-ai/dsh-code-runtime-worker-thread'` in its **own**
`cordis.patch.yml` (or mount `dsh-headless`), otherwise prompt assembly fails
loudly in non-native modes.

The full definition is the verbatim artifact
[`cordis.patch.yml`](cordis.patch.yml) in this directory.

## Why (checked per ground rule 1)

PTC is useful for every agent and saves tokens: one `run_code` round trip
replaces N assistant-turn/tool-result round trips, intermediate results get
filtered inside the program instead of re-projected into model context, and
the fixed prompt is one transport schema plus the SDK block instead of every
tool schema. Reuse-before-reinvention held throughout:

- **No plugin provides PTC itself** — the 2026-08-29 sweep of the dshmarket
  index (`https://awesome-dsh-plugin.com/plugins.json`, 2495 entries on
  2026-08-29, 2628 on 2026-08-30, plus npm) found only *extensions* of the
  builtin (`dsh-ptc-plus` persistent REPL, `dsh-minimal-ptc` preset,
  `dsh-ptc-cordis-preset`, `dsh-agent-preset-router`,
  `dsh-code-runtime-container`, `dsh-fail-logger`); every one assumes Code Mode
  already exists, so nothing is installable *for the mode itself*. One of those
  extensions is now installed on top of this row: `../dsh-ptc-plus/`.
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
applicable). The companion entry `../dsh-ptc-plus/` *does* install an npm
bundle; this row itself needs none.

## Install

1. Target: `$DSH_HOME/cordis.patch.yml` (normally `~/.dsh/cordis.patch.yml`).
   It does **not** exist on a baseline install.
2. If the target does not exist: copy
   `$KIT/plugins/machine-wide-ptc/cordis.patch.yml` verbatim.
3. If the target exists: it is user-authored home-layer content — merge.
   Ensure the `id: tools` row resolves to `mode: both`, preserving every
   other user row. Do NOT merge an `insert: code-runtime` block from an
   older kit copy: on dsh 0.1.1-rc.2 it collides with the surface bundles'
   identical insert and refuses to boot (`duplicate loader entry id`).
4. Do NOT write this into a profile's own `cordis.patch.yml`: that only
   covers one profile and loses the point.

## Activation

Two different activation points, both measured on 2026-08-30:

- **Treat a restart as required.** That is the dependable rule, and the shipped
  note in `setup/verify.sh` says the same.
- **One partial exception, observed but not trusted.** The live home patch was
  rewritten `code` → `both` at 12:34 by a profile process that had booted at 12:10
  under `code`, and direct native calls in the *already running* session began
  succeeding minutes later (they had been rejected with "only `run_code` is
  callable directly") — so presentation mode is not wholly frozen at boot. Later in
  the same window a direct call was rejected again while the row still read `both`,
  which the session's own teardown around 12:46 explains at least as well as a
  hot re-read. The mechanism is unresolved, so the observation is recorded here
  rather than relied on.
- **Bundle layers need a boot; a session's catalog does not.** ptc-plus only mounted
  after a full harness restart (12:47, again at 19:32), but the *same* session that
  predated the install came back with its runtime — cross-cell bindings persisted
  and `run_code` carried the plugin's description. The surface is recomposed per
  request, so no new session is needed once the process has restarted.
- **`edit_run_code` does not appear in this setup at all.** It registers only under
  `mode: code` — every `ensureInstalled` site in `internal/direct-surface-owner.js` is so
  gated (225/238/264 in 0.2.3; 238/251/276 in 0.3.2, under the renamed `ptc` label), so
  choosing `both`
  means rejected cells are resent whole. See `../dsh-ptc-plus/README.md`.

So: flip `mode`, then restart — piggybacking on the Step 4 plugin restart in
`RESTORE.md`. One boot then covers the row and any bundle added alongside it.

## Verify

1. `setup/verify.sh` section 7 compares the live file against the kit copy.
2. `dsh --profile web --dump-config`: the composed `- id: tools` row shows
   `mode: both` under a provenance header naming `$DSH_HOME/cordis.patch.yml`
   (`setup/verify.sh` section 4 asserts the value directly).
   The `code-runtime` row appears exactly once, contributed by the
   `dsh-web-app` bundle layer (not the home layer — see What it is above).
   `dsh --profile web` boots without the duplicate-entry error.
3. Functional (after the restart, in a NEW session): the tool catalog offers
   `run_code` with a TypeScript SDK section **and** the ordinary per-tool
   schemas. Two probes: (a) ask for something two-tool-deep (e.g. "list the
   top-level files and report how many are markdown") — a single program is a
   valid answer; (b) ask for one cheap single-tool fact (e.g. "what files are in
   the top level") — a direct native call must also work. Under the old
   `mode: code`, (b) was structurally impossible.
4. Rollback: set `mode: code` to force everything through `run_code`, or
   `mode: native` (or delete the `tools` row) to drop Code Mode entirely, and
   restart. `mode: native` is **not** compatible with the installed
   `dsh-ptc-plus` bundle while `run_code` is still exposed — see
   `../dsh-ptc-plus/README.md`.

## Interacts with

- Per-preset selection still shadows the default: only the stock `code` preset
  carries its own `@deepseek-ai/dsh-agent-tool-presentation` row (`mode:
  code`), and a locally-authored preset can add one — sessions on such
  presets get the preset's answer, not the deployment default. `standard`,
  `minimal` and `cordis` declare none, so this home-layer row governs them.
  Subagent/workflow children bind to their parent's composition.
- Market extensions install on top of this row *after* it is active. The one in
  use here, `../dsh-ptc-plus/`, adapts to the mode: it rejects direct native
  calls only when the composition is `code`, so `both` keeps both paths open.
