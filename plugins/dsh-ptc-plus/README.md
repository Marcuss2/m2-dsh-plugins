# dsh-ptc-plus — session-bound persistent REPL for PTC mode

> **REMOVED 2026-09-05.** Superseded by [`../better-dsh/`](../better-dsh/)
> (Dashr): a persistent IPython kernel whose `eval` tool exposes a
> model-settable per-call `timeout` plus fully configurable budgets — the
> capability this plugin structurally refused (`run_code`'s schema must stay
> two strings). Uninstalled with:
> `dsh plugin --profile web remove dsh-ptc-plus` (after unregistering its pnpm
> patch and release-age entries from the profile's `pnpm-workspace.yaml`, or
> pnpm fails with `ERR_PNPM_UNUSED_PATCH`). The qwencloud root-`oneOf`
> finding below stays valid and is re-applied in the Dashr entry. Everything
> under this header documents the old state and remains the rollback recipe.

## What it is

Community plugin `dsh-ptc-plus` (npm, MIT; **0.3.2 installed** on 2026-09-04, having been
0.2.3 on 2026-08-30) that takes
over the Code Mode (`run_code`) surface and replaces the built-in stateless behavior with
a **session-bound persistent TypeScript REPL**. It is the only published extension that
claims that surface at all — sweeps of the dshmarket index found just two descriptions
mentioning `run_code` (`dsh-ptc-plus` and `dsh-fail-logger`, the latter only logging
failures). The index itself is moving fast: 2628 entries on 2026-08-30, 3019 on the
2026-09-04 re-check, and npm had taken the plugin from 0.2.3 to 0.3.2 in between
(0.2.4 and 0.3.1 in the middle).

From the model's point of view `run_code` keeps its name and its two parameters, but its
meaning changes:

| | stock Code Mode | with dsh-ptc-plus |
| --- | --- | --- |
| state | every program starts from an empty scope | top-level bindings, imports and results stay live across calls |
| fixes | resend the whole block | `edit_run_code({ edits: [{ old_string, new_string }] })` sends one diff — **`code` mode only**, see "Interaction with `mode: both`" |
| module syntax | `import` / `export` illegal in the function body | rewritten by AST before execution (`@babel/parser` / `acorn`) |
| budgets | patch-layer config, restart to change | **live Web settings card**, per session |
| special values | JSON round-trip flattens them | preserved; bounded output trimming and row-accurate diagnostics |

It runs its own kernel (`internal/kernel-worker.js`, `internal/worker-client.js`) and its
own composition row — it does **not** override `id: tools` or `id: code-runtime`, so it
composes with `../machine-wide-ptc/` without colliding.

## Why it exists in this kit

1. **Repetitive-setup cost.** Under stock Code Mode every program re-sends its imports
   and scratch state, and a one-character mistake re-sends the whole block. The plugin's
   own paired measurement (18 sessions/arm, `opencode-go/deepseek-v4-flash`, identity
   blinded) reports −25 % model requests, −36.7 % tool calls, −22.6 % token flow and
   +12.3 points on a blind rubric. Treat that as a noisy observation, not a guarantee —
   the same matrix failed machine acceptance (2/18 sessions exceeded the arm's compute
   budget).
2. **Budget editing without a restart.** Four execution budgets are settings fields
   (`internal/config-spec.js`), applied live, which is the only practical way to
   give one session a different ceiling without touching the patch layer:

   | key | default | ceiling |
   | --- | --- | --- |
   | `computeMs` (per-cell CPU time) | 60 000 | `Number.MAX_SAFE_INTEGER` |
   | `maxWallMs` (per-cell wall clock, awaits included) | 600 000 | 2 147 483 647 ms ≈ 24.86 days |
   | `maxOutputBytes` | 67 108 864 | `Number.MAX_SAFE_INTEGER` |
   | `maxOldGenerationSizeMb` | 512 | fixed at worker creation; refused while a session worker is live |
   Plus `enabled` (true) and `cordisToolsEnabled` (false — when on it adds the official
   Cordis tools, owner guidance and the `cordis-plugin-development` skill as one unit).
   0.3.2 grew the card from 20 fields to 23, with non-disruptive defaults. New: boolean
   `enhancedToolView` (richer tool cards instead of DSH's native ones),
   `autoDescribeRunCode` (lets the **`run_code` call itself** omit its outer
   `description` summary; unrelated to a nested `tools.<name>()` argument error), and
   `looseTopLevelFunctionClassRedeclarations`. The four budget defaults above are
   **unchanged** between 0.2.3 and 0.3.2.
   `maxValueNodes/Edges/ArrayLength/BigIntDigits`, `maxNestedRunCodeDepth`,
   `canonicalizeToolCalls`, `looseTopLevelRedeclarations`, `durableReplay`,
   `autoRewriteImports`, `autoStripExports`, `autoSplitRedeclarations`, `tipsEnabled`,
   `tipCooldownMessages`, `tipEscalationFailures`.

### What it deliberately does *not* provide

It cannot make the **model** choose a ceiling. `internal/direct-surface-owner.js` rebuilds
the tool definition by spreading the host one and **throws** unless the parameter object
is exactly two strings:

```
ptc-plus: incompatible run_code schema; expected object parameters with string code and
description properties
```

So no third `timeoutMs` parameter can be added by this or any other plugin — `dsh-tools`
also refuses to register the name at all
(`tool name "run_code" is reserved … cannot be registered or shadowed`). Hours-long work
therefore still belongs **outside** the cell, not in a larger ceiling:
`dsh-subprocess-local` spawns an isolated detached process tree
(`detached: platform !== "win32"`) and signals it with a process-**group** kill
(`process.kill(-pid, sig)`), and `dsh-bash-local` documents that a still-running
background process is "killed and joined at composition teardown" — a harness restart
ends the run. Launch long work in its own session and poll it:

```sh
setsid nohup torchrun --nproc_per_node=4 train.py > train.log 2>&1 < /dev/null &
```

`setsid` re-sessionizes the child so the group kill misses it, and the redirect is
load-bearing: a grandchild holding inherited stdout keeps the capture pipe from ever
reaching EOF, which is a hang, not a background job.

## Interaction with `mode: both` (required in this kit)

`../machine-wide-ptc/` pins the deployment default to **`both`** (native per-tool schemas
*and* `run_code`), because `mode: code` forces every single call through `run_code`.
dsh-ptc-plus is compatible and auto-detects it:

- `presentationState(assembly)` classifies each request as `ptc`, `both` or `native` from
  the assembled tool list. 0.3.x renamed the internal label `code` → `ptc` and now matches
  either collapse section, `['tools:ptc-only', 'tools:code-only']` — the host in this kit
  (dsh-tools 0.1.1-rc.2) still emits only `tools:code-only`, so the plugin is ahead of the
  host here, not requiring it. Extra tools beside
- `executionRejection(exec)` gates direct native calls **only** in `ptc` (0.3.2:
  `direct-surface-owner.js:354`):
  `if (policy?.presentation !== 'ptc') return undefined` — under `both` nothing is
  rejected, so the "tool X is not a direct PTC tool" branch cannot fire.
- The **inverse** is the part that bites: `edit_run_code` is registered *only* in
  `ptc`. All three `ensureInstalled` call sites (0.3.2: `direct-surface-owner.js`
  lines 238, 251, 276; 0.2.3 had them at 225, 238, 264) test
  `presentation === 'ptc'`, so under `both` there is no in-place repair transport and a
  rejected cell has to be resent whole.
- `stream()` canonicalizes mis-directed native calls into `run_code` **only** when
  `presentation === 'ptc'`, so `both` leaves the model's native calls alone.
- Conversely an assembly that is `native` **while still carrying `run_code`** is a hard
  error: `ptc-plus: native agent composition assembled with run_code`. `both` is therefore
  the widest mode that works; do not pair this plugin with `mode: native`.
- It requires `ctx.codeRuntime.language === 'typescript'` (`index.js`:
  `ptc-plus: unsupported code runtime language … only "typescript" is supported`). The
  shipped `@deepseek-ai/dsh-code-runtime-worker-thread` satisfies it.

### Getting `edit_run_code` back for one agent

Presentation is **per composition, not per process**. The shipped
`@deepseek-ai/dsh-agent-tool-presentation` row is "the row an agent preset carries to
say which form of its tools the model sees", and its own header states the payoff:
`ctx.tools.presentAs()` declares it for the mounting scope — the preset's standing
mount — "so the declaration covers every agent joined to that preset and a Code Mode
preset runs beside native ones in one process. One row per composition, not one per
session."

So this deployment can keep `mode: both` as the default and give a heavy-PTC preset:

```yaml
- id: tool-presentation   # @deepseek-ai/dsh-agent-tool-presentation
  config:
    mode: code            # collapsed surface + edit_run_code for this preset only
```

Agents joined to that preset see `run_code` + `edit_run_code` and nothing else
(`collapses()` forces the `UNKNOWN_TOOL` path for other names); every other agent
keeps `both`. `Config` is `{ mode: 'native' | 'code' | 'both' }`, required. A preset
selecting `code` where no code runtime is composed "fails at mount, named in the
preset's own activation audit" — not a risk here.

**Not exercised on this machine.** The row id above is taken from the plugin's
declared `name` (`"tool-presentation"`), and the example is read from shipped source,
not run: confirm it with one mount before trusting it.

## qwencloud schema patch (required with the qwencloud provider)

**Symptom (2026-09-04):** every turn in a session whose request carried
`edit_run_code` died with

```
InvalidParameter: <400> InternalError.Algo.InvalidParameter: The parameters, when
provided as a dict, must confirm to a valid openai-compatible JSON schema. Please
check the schema definition for tool: edit_run_code.
```

**Root cause.** The default provider (`../../setup/settings.yaml.excerpt`) is
`qwencloud` — Alibaba MaaS `token-plan.ap-southeast-1.maas.aliyuncs.com`,
`api: openai-responses`. Its gateway validates every tool `parameters` schema and
rejects **root-level** `oneOf`/`anyOf` outright. Stock 0.3.2 declares exactly that:
`editRunCodeSchema()` in `internal/rejected-cell-editor.js` puts a `oneOf` with two
branches (`edits` / `regex_edits`) at the root of the parameters. Probed directly
against the endpoint (responses API, `qwen3.8-flash`, 2026-09-04):

| parameters schema | result |
| --- | --- |
| root `oneOf` (stock 0.3.2, with or without sibling `type`) | 400 InvalidParameter — the exact error above |
| root `anyOf` | 400, same message |
| nested `oneOf` inside `properties` (`dsh-better-edit`'s `path`) | 200 |
| flattened single object with optional `edits`/`regex_edits` | 200 |

Nested combinators pass, which is why the `dsh-better-edit` and `dsh-lsp-actions`
schemas never tripped it. `repl.state`'s schema is also root-`oneOf`, but that is a
program binding validated in-process, never a provider tool. Upstream 0.3.2 is the
latest npm release (checked 2026-09-04) — no fix to upgrade to.

**The patch.** [`patches/dsh-ptc-plus@0.3.2.patch`](patches/dsh-ptc-plus@0.3.2.patch)
deletes the `editRunCodeParameterBranch` helper and flattens the parameters into one
object with optional `edits`, `regex_edits` and `expected_target_call_seq`. Runtime
semantics are unchanged: `editRejectedCell()` still rejects empty and
double-operation calls with the same messages, so the exactly-one rule moved from
schema to runtime guard, where it already existed. Applied as a registered pnpm patch
so reinstalls keep it (`patchedDependencies` in the profile's `pnpm-workspace.yaml`).

**Apply on a fresh install** (after the batch `dsh plugin add`, before `verify`):

```sh
cd "$DSH_HOME/profiles/web"
mkdir -p patches
cp "$KIT/plugins/dsh-ptc-plus/patches/dsh-ptc-plus@0.3.2.patch" patches/
printf '\npatchedDependencies:\n  dsh-ptc-plus@0.3.2: patches/dsh-ptc-plus@0.3.2.patch\n' >> pnpm-workspace.yaml
pnpm install --no-frozen-lockfile
```

Verified 2026-09-04: `editRunCodeSchema()` from the installed copy emits no
combinator; the exact emitted schema POSTed to `/responses` returns 200 where the
stock schema returns the 400 above; `setup/verify.sh` §3 FAILs when the
registration or the installed flattening is missing.

**Version bumps.** The patch key pins `0.3.2`; a dsh-ptc-plus upgrade needs the
patch re-created (`pnpm patch dsh-ptc-plus@<new>`, same edit — pnpm fails the
install loudly rather than silently dropping it). Re-check upstream first: the
flattening is only needed while the shipped schema has a root-level combinator, and
the qwencloud validator behavior may change independently.

## Dependencies

- npm: `@babel/code-frame`, `@babel/parser`, `@babel/traverse`, `acorn`,
  `@deepseek-ai/schemastery@^3.18.1`.
- Peers (all pinned `"next"`): `@deepseek-ai/dsh-settings`,
  `@deepseek-ai/dsh-skill-filesystem`, `@deepseek-ai/dsh-tool-cordis`, `@deepseek-ai/dsh-tools`.
- Node `^22.19.0 || >=24.0.0` (this machine runs v26.8.1).

**AGENTS.md ground rule 2 check.** `@deepseek-ai/schemastery` is a *regular* dependency, so
it hoists into `$PROFILE/node_modules` — but it is not a runtime singleton (the
config-validation library) and it is **already hoisted in this profile at 3.18.1**, equal
to the installation's copy, so the add changes nothing there. That equality is now
*enforced*, not lucky: upstream published 3.18.2 (whose own dep wants cosmokit `^1.8.3`)
after this entry was written, and a fresh resolve hoists it — §4's skew check then FAILs
even though schemastery is off the `CORE_MODULES` fail list. The profile's
`pnpm-workspace.yaml` now carries `overrides:` pinning `@deepseek-ai/schemastery@3.18.1`
and `@deepseek-ai/cosmokit@1.8.2` (see `../README.md`, "How the npm bundles get
installed", fix 2). `setup/verify.sh`
`CORE_MODULES` deliberately excludes it (the fail list is `dsh-tools dsh-agent`
`dsh-agent-loop dsh-session dsh-llm dsh-fs dsh-sandbox dsh-subprocess dsh-settings`
`dsh-commands dsh-storage-domain dsh-system-prompt dsh-client-runtime`
`dsh-client-connection cordis`), so it does not trip the core-shadow check. The four
`"next"` peers are the one to watch, and they are held back by an existing setting:
`~/.dsh/profiles/web/pnpm-workspace.yaml` carries `autoInstallPeers: false`, so peers are
not installed into the profile. `next` on `@deepseek-ai/dsh-tools` currently resolves to
**0.1.1-rc.2**, the installed version, so even a regression to auto-installing peers
would read as a same-version WARN rather than a skew. Re-run `setup/verify.sh` after the
add (ground rule 3) and confirm the section 4 `core shadow` row has not changed.

**Posture caveat.** The plugin's README states it is designed for `danger-full-access`:
the REPL reaches Node and the OS directly and adds no sandbox of its own. This kit's
`workspace-write` sandbox plus `ask` approvals still apply to every SDK binding call (each
binding re-enters the full pre-execute → guards → execute → post-execute pipeline), but a
persistent REPL keeps a live worker per session for the session's whole life — a wider
standing surface than stateless Code Mode. Keep `cordisToolsEnabled` off unless the session
genuinely needs model-authored plugins.

## Install

1. Batch with any other pending bundle (one resolution pass, one `package.json` write,
   never concurrently):

   ```sh
   dsh plugin --profile web add dsh-ptc-plus@0.3.2
   ```

   The dshmarket entry advertises this **unpinned** (`dsh plugin --profile web add
   dsh-ptc-plus`), so a market-driven restore always takes latest. This kit pins so that
   `setup/versions.txt` and the docs agree — which is precisely how it went stale once,
   and why `setup/verify.sh` §10 now warns whenever any installed bundle falls behind
   npm latest. 0.3.2 was also fresh enough at install time to trip pnpm's
   `minimumReleaseAge` guard; `dsh plugin` wrote the required
   `minimumReleaseAgeExclude: dsh-ptc-plus@0.3.2` entry into
   `~/.dsh/profiles/web/pnpm-workspace.yaml` on its own.

   The bundle self-declares its composition row; its shipped patch is exactly:

   ```yaml
   # Attach the session REPL after both the tools registry and Code Runtime exist.
   # The plugin adds a virtual rejected-cell edit transport beside DSH's run_code.
   - insert:
       - id: ptc-plus
         name: dsh-ptc-plus
   ```

   No manual patch edit is needed for this one, and `$DSH_HOME/cordis.patch.yml` must keep
   `- id: tools → mode: both` from `../machine-wide-ptc/`.
2. Verify the composition:

   ```sh
   dsh --profile web --dump-config | grep -B2 -A4 'id: ptc-plus\|^- id: tools$'
   ../setup/verify.sh --record
   ```

   Section 4 must show `layer dsh-ptc-plus` and `tools mode both`, with no `core shadow`
   FAIL. `--record` refreshes `setup/versions.txt`, which now carries
   `dsh-ptc-plus@0.3.2`.
3. Restart `dsh --profile web`. The composition **row** mounts at boot, so the new
   version is inert until then. Sessions do *not* need to be new: the surface is
   recomposed per request, and a session that predates the install still came back from a
   restart running the plugin's REPL (see the note under "Verify"). The `ptc-plus`
   settings card then appears under **Settings → Plugin configuration** with live-applied
   fields.

## Activation

Boot-time for the row and for `mode: both`; live for every `ptc-plus` setting.
`enabled: false` collapses the plugin to its settings card only and leaves stock Code Mode
`run_code` in place — the cheap runtime rollback.

**A version bump of an already-mounted plugin does not need a restart.** Measured
2026-09-04: the process booted at 14:03:25, `dsh plugin … add dsh-ptc-plus@0.3.2`
replaced `internal/kernel-worker.js` at 14:26:03, and the very next cell already ran the
new code — its frames reported `kernel-worker.js:402`, which is
`return evaluate(message.program)` in 0.3.2 (495 lines) but `const originalReject =
call.reject` in 0.2.3 (484 lines), where the dispatch sat at 394. The kernel worker is
respawned from disk, so only the **mount** of a new bundle is boot-gated. The respawn
costs the in-memory scope: the same cell triggered
`warning[PTC-R002] … skipped 4 unreconstructable historical cell(s)`, and bindings had to
be re-established. Diffing line numbers this way is the cheapest reliable version check.

## Verify

Functional checks after the restart — a **new** session is not required, since the
surface is recomposed per request (see the caveat further down):

1. `run_code` is described as evaluating "the next TypeScript cell in this
   session-bound persistent REPL" **and** the ordinary per-tool schemas are still
   present, proving `both`. Do **not** expect `edit_run_code` here: it registers only
   under `mode: code`.
2. State persistence: one program defining `const x = 41`, a second returning `x + 1` ⇒
   `42`. A fresh session must *not* see `x`.
3. Native calls still direct: a single `glob`/`read` call not wrapped in a program must
   succeed (this is the `mode: code` regression test).
4. Budget edit: lower `maxWallMs` on the card, run `await new Promise(() => {})`, and get a
   `timeout` failure naming the wall-clock ceiling within that budget.

**Results (2026-08-30, against the 12:47 boot that first mounted the bundle).**
1 ✓ native `bash` / `edit` / `read` calls succeeded directly while `run_code` also
ran. 2 ✓ a binding created in one cell (`const probe1 = { value: 7 }`) read back
intact from the next one — under stock Code Mode that is a `ReferenceError`. 3 ✓
(same observation as 1). 4 not exercised: the card needs a human click. The
plugin's own namespaces are live — `capabilities.tree()` returns `tools` (48
bindings), `repl` (`state`: list/save/restore/delete durable REPL states) and
`code` (`run`) — and the hard restart exercised the recovery path for real,
emitting `warning[PTC-R002]: Restored the durable head and skipped 98
unreconstructable historical cell(s) … phase: recover, state: rolled-back`.

Two refinements to the claims above, learned from that run:

- `edit_run_code` is exposed **only under `mode: code`**. Every `ensureInstalled`
  call site in `internal/direct-surface-owner.js` is gated on the collapsed presentation —
  lines 225/238/264 in 0.2.3 (`presentation === 'code'`) and 238/251/276 in 0.3.2, where
  0.3.x renamed that internal label to `ptc` — so under `both` it is never registered at
  all — and the plugin knows this: its own rejection text branches on it, "when
  `edit_run_code` is declared for the current request … otherwise retry only this
  cell with corrected source in `run_code`" (`internal/session-cell-executor.js:78` in
  0.2.3, `:80` in 0.3.2).
  The practical cost of choosing `both`: a typo in a long cell means **resending the
  whole cell** instead of applying a diff.
- The model-facing surface is **recomposed per request, not frozen at session start**.
  This conversation is the same session that predates the install (identical
  `DSH_SESSION_ID`, session log created 2026-08-29, plugin added 2026-08-30) and it
  nevertheless came back from the restart with ptc-plus's runtime: cross-cell
  bindings persist, `capabilities` / `repl` / `code` are live, and cell frames are
  `kernel-worker.js`. So a restart is enough for *existing* sessions; an earlier
  claim here that a resumed session "sees none of this" was wrong, and what looked
  like a stale catalog was the `mode: code` gate above.
  before the bundle mounted.

### Re-verified after a clean boot (19:33 process; same session id, resumed)

| probe | result |
| --- | --- |
| direct native `bash` / `read` | ✅ succeeded outside any program (`mode: both`) |
| binding made in cell 1, read in cells 2 and 3 | ✅ intact (`{value: 7}` three cells later) |
| PTC dispatch `tools.glob` / `tools.grep` / `tools.bash` | ✅ 8 paths, 2 hits, `sleep 3` → `awake` |
| wall time across an awaited tool call | ✅ 3015 ms — awaits really park, no premature ceiling |
| which runtime owns the cell | ✅ frames in `dsh-ptc-plus/internal/kernel-worker.js:224/253/394` |

That last row is the reliable attribution probe: stock Code Mode shows
`@deepseek-ai/dsh-code-runtime-worker-thread/lib/worker.cjs` in the same frames, so
`new Error().stack` inside a cell settles any doubt about who is executing it.

`repl.state({ action: 'save' })` **refused** in this session with `cannot save a
durable REPL state from a volatile segment; restore a durable state …`. That is
correct behavior, not a fault: cells run *after* a `PTC-R002` rollback form a
volatile suffix over the restored durable head, so nothing created there can be
promoted to a named state. Expect the same message in any session resumed across a
restart; whether a session created entirely after a boot can save is untested.

## Rollback

`enabled: false` on the card (live), or remove the bundle and restart:

```sh
dsh plugin --profile web remove dsh-ptc-plus && ../setup/verify.sh
```

Restore `mode: code` in `$DSH_HOME/cordis.patch.yml` (and the kit copy) only if forcing
everything through `run_code` is actually wanted again — see `../machine-wide-ptc/README.md`.

## Interacts with

- `../machine-wide-ptc/` — supplies the `mode` that decides whether this plugin restricts
  direct native calls at all (see the section above).
- `../../setup/verify.sh` — `dsh-ptc-plus` is listed in `BUNDLES`, so sections 3 and 4 check
  the dependency, its `dsh.profile.bundles` entry and its composed row; the layer check
  also matches a row by `name:` as a fallback (verified: this bundle does emit its
  own `# == dsh-ptc-plus` provenance header, at dump line 569).
- `../dsh-better-edit/` — unaffected; that plugin replaces the file read/edit tools, not
  the code transport.
- The stock `code` agent preset — a session on that preset gets the preset's own
  `mode: code` presentation row, so *there* the plugin will route native calls through
  `run_code` and reject direct native calls. Use the `standard` preset (declares no
  presentation row) for the `both` surface.
