# better-dsh (Dashr) — persistent IPython kernel REPL, replacing dsh-ptc-plus and dsh-better-edit

## What it is

Community plugin `better-dsh` (npm, MIT, repo
[pgmi-builds/better-dsh](https://github.com/pgmi-builds/better-dsh);
**0.2.2-b installed** on 2026-09-05). "Dashr" mounts on the **host plane** and
adds an **`eval` tool backed by one persistent IPython kernel subprocess per
session** (`ctx.replRuntime`, class `DashrRuntime`). It supersedes two kit
entries at once:

- **`dsh-ptc-plus`** (removed): same job — turn the ephemeral cell surface into
  a session-persistent REPL — but Python instead of TypeScript, and with every
  budget configurable **plus a model-settable per-call timeout**, which was the
  thing ptc-plus structurally refused to expose (it throws unless `run_code`'s
  schema is exactly `{code, description}` strings).
- **`dsh-better-edit`** (removed): Dashr re-wires the hashline lineage natively
  — its own `read` / `write` / `edit` / `undo_last_edit` register on each
  agent's own scope layer and **shadow** the stock ones by nearest-layer-wins
  (same `HASH│content` anchors this session uses). Its `read` additionally
  resolves URL schemes: `skill://`, `ctx://`, `agent://`, `dvc://`, `dsh://`,
  `http(s)://`. The upstream project's own test reports record deployments run
  with `dsh-better-edit` removed as the intended configuration.

| | dsh-ptc-plus (old) | better-dsh (now) |
| --- | --- | --- |
| language | TypeScript worker-thread REPL | IPython kernel subprocess (`zeromq` Jupyter protocol) |
| transport | `run_code` (hijacked) | `eval` (own name; `run_code` untouched) |
| per-cell timeout | config card only; model cannot set it | config default `runTimeoutMs` **and** optional `timeout` (seconds) parameter the model passes per call |
| state across cells | yes (worker respawn loses it) | yes; plus `dill` namespace snapshots restore across restarts (`snapshotDir`) |
| in-flight cancel | no | two-phase interrupt (control-channel, then SIGALRM escalation) |
| file editing tools | separate plugin (`dsh-better-edit`) | built-in hashline read/write/edit/undo + URL schemas |

## Why it exists in this kit

1. **Timeouts fully set.** Every budget is a live config field on the row
   (defaults from shipped `lib/index.js`): `startupTimeoutMs` 30 000,
   `runTimeoutMs` 120 000, `interruptGraceMs` 2 000, `interruptConfirmMs` 250
   (must stay < grace), `disposeTimeoutMs` 5 000, `snapshotTimeoutMs` 30 000,
   `maxOutputBytes` 67 108 864, `snapshotSizeCapBytes` 268 435 456 — and the
   model can bound any single cell itself via `eval({cell, description,
   timeout})`. Verified behavior (direct probe against the installed bundle):
   a 60 s sleep under a 2 000 ms budget returned
   `cell exceeded 2000ms wall budget` in 2 536 ms (interrupt + grace worked).
2. **Persistent state with recovery.** Variables/imports survive cells and
   turns; configure `snapshotDir` for full-namespace `dill` snapshots that
   restore on next boot (`python` version / interpreter identity validated
   kernel-side; degraded restore never fabricates variables).
3. **One fewer stack.** The hashline editor, the persistent REPL, a simplistic
   LLM-endpoint failover, and browser use (`dvc://browser`, via bundled
   `puppeteer-core`) arrive in a single bundle.
4. **Coexists with this kit's `mode: both`** (see `../machine-wide-ptc/`):
   `eval` is its own transport name, native tools stay directly callable, and
   Dashr's control prompt explicitly teaches the dual surface ("payload-shaped
   work → direct tool call; logic-shaped work → `eval` cell"). It masks only
   `send_message`/`report` behind a bridge; everything else stays visible.

## Behavior details worth knowing

- **Model-direct collapse**: within its composition, Dashr collapses the wire
  schema to `eval` + keeps native tools per the presentation mode; nested
  calls inside a cell ride the real registry pipeline (`await tool.name({...})`,
  one positional args object; approvals/sandbox still apply per sub-call).
- **Kernel env ownership**: `python` is only a hint. Bare `python3` selects a
  managed venv `<package>/.venv-kernel` auto-provisioned on first use
  (`kernelAutoInstall: true`, uv → venv+pip fallback ladder). This machine has
  it pre-provisioned manually (see Install step 3), so first cell doesn't pay
  provisioning cost.
- **Concurrency**: cells on one session serialize; different sessions get
  their own kernels. `maxParallelSubCalls` (default 10) caps one cell's
  overlapping sub-calls.
- **Bundled extras** (accept or override later): it re-enables host compaction
  rows (`compaction-basic`, `command-compact`, `tool-result-pruner` —
  dsh-web-app disables them) and installs a global LLM-endpoint failover
  (fallback1/fallback2 settings fields, unset by default — overlaps
  `../dsh-llm-fallbacks/`, which remains installed).
- **iOS PWA tweaks + web-trust fence**: client-side UI rows; harmless here.

## qwencloud compatibility

The default provider here (qwencloud, Alibaba MaaS) rejects **root-level**
`oneOf`/`anyOf` in tool parameter schemas (this is why dsh-ptc-plus needed a
patch — see `../dsh-ptc-plus/README.md`). Dashr's `edit.path` uses a *nested*
`oneOf` inside `properties`, which the endpoint accepts (probed 2026-09-04:
nested combinators pass). No patch needed; if a future version moves a
combinator to a schema root, revisit.

## Dependencies

- npm regular deps (all safe to hoist): `@deepseek-ai/schemastery` (override-
  pinned to 3.18.1 profile-wide already; not a core singleton), `diff`,
  `file-type`, `puppeteer-core`, `xxhash-wasm`, `use-sync-external-store`,
  **`zeromq`** (native build → needs `allowBuilds: zeromq: true`, added to the
  profile's `pnpm-workspace.yaml`; prebuilt binaries ship for linux-x64/node
  so no compiler ran), and platform-scoped `@oh-my-pi/pi-natives-*`
  (optionalDependencies — only the matching platform installs; carries the
  ast/lsp natives the `dvc://` devices use).
- Peers: ~50 `@deepseek-ai/*` packages, all pinned to the
  `>=0.1.2-alpha.1 <0.2.0-0` line — **but they are peers, not dependencies**,
  so nothing shadows core (AGENTS.md rule 2 holds; verify.sh §4 confirms).
  The host here is 0.1.1-rc.2, *below* the declared peer floor: install works
  and the code mirrors rc.2 shapes (its own comments cite `dsh-tools
  0.1.1-rc.2`), but treat alpha-line drift as a known risk on future upgrades.
- Node `>=22.18` (this machine: v26.8.1). Python side: ipykernel + dill inside
  the managed venv (auto).
- **MANDATORY install flag**: `--config.auto-install-peers=false` — otherwise
  pnpm pulls a second divergent copy of cordis/dsh core into the profile
  (rule-2 violation). The profile also sets `autoInstallPeers: false` globally.

## Install (fresh machine)

1. One batched command (ground rule 3), PATH-prefixed for the system pnpm:

   ```sh
   PATH=/usr/bin:$PATH dsh plugin --profile web add --config.auto-install-peers=false better-dsh@0.2.2-b
   ```

   If `minimumReleaseAge` refuses the fresh version, `dsh plugin` records a
   `minimumReleaseAgeExclude` entry itself. If pnpm reports
   `ERR_PNPM_IGNORED_BUILDS: zeromq`, add `zeromq: true` under `allowBuilds:`
   in `~/.dsh/profiles/web/pnpm-workspace.yaml` and re-run.

2. **Do NOT let a later `dsh plugin add` resurrect the `dshmarket` bundle
   row** — observed 2026-09-05: `dsh plugin … add better-dsh` re-inserted
   `dshmarket` into `dsh.profile.bundles` (the package is still a dependency),
   which duplicates the desktop's own `dsh-market` insert and kills the boot.
   After every batched add, check:

   ```sh
   python3 -c "import json;d=json.load(open('$HOME/.dsh/profiles/web/package.json'));print(d['dsh']['profile']['bundles'])"
   ```

   and remove `dshmarket` from that list if present (keep the dependency).

3. Pre-provision the kernel venv (optional but recommended — skips first-use
   latency and the build ladder):

   ```sh
   cd ~/.dsh/profiles/web/node_modules/better-dsh
   uv venv .venv-kernel --python 3.12
   uv pip install --python .venv-kernel/bin/python ipykernel dill
   ```

   Or export `DASHR_KERNEL_PYTHON` to any prepared interpreter; the row reads
   it (`python: !!js process.env.DASHR_KERNEL_PYTHON ?? 'python3'`).

4. Remove the displaced bundles (already done here):

   ```sh
   # unregister the ptc-plus pnpm patch + release-age entry FIRST, or pnpm
   # fails the removal with ERR_PNPM_UNUSED_PATCH:
   #   patchedDependencies: drop the dsh-ptc-plus@0.3.2 line
   #   minimumReleaseAgeExclude: drop dsh-ptc-plus@0.3.2 (whole key if sole entry)
   dsh plugin --profile web remove dsh-ptc-plus dsh-better-edit
   ```

5. Restart `dsh --profile web` (composition rows mount at boot).

## Activation

Boot-time for the `dashr-repl` row and its compaction/connection overrides.
Per-session: kernels spawn lazily on a session's first `eval` cell and tear
down on `agent/disposed`.

## Verify

After the restart, in a new session:

1. `eval` is offered with parameters `cell`, `description`, optional `timeout`
   (seconds) and optional `reset`; ordinary native tools are still directly
   callable (`mode: both` regression test).
2. Persistence: cell 1 `x = 41`, cell 2 `x + 1` ⇒ `42`. A fresh session must
   not see `x`.
3. Timeout: `eval({"cell": "import time\ntime.sleep(60)", "description": "…",
   "timeout": 5})` ⇒ interrupted with a wall-budget error in ~5–7 s.
4. Editing tools are Dashr's: `read` description mentions resolving
   `scheme://` URLs (stock/better-edit text does not).
5. Offline attribution (done 2026-09-05 before restart): mounting the
   installed bundle standalone runs real cells — persistence ✓, per-call
   timeout ✓ (`cell exceeded 2000ms wall budget` in 2.5 s).

CLI-side checks:

```sh
dsh --profile web --dump-config | grep -A3 'id: dashr-repl'   # row present
../setup/verify.sh                                            # §3/§4/§9 green
```

## Rollback

```sh
dsh plugin --profile web add dsh-ptc-plus@0.3.2 dsh-better-edit   # + re-register the pnpm patch per ../dsh-ptc-plus/
dsh plugin --profile web remove better-dsh
```

then restart. The displaced entries keep their full records
(`../dsh-ptc-plus/`, `../dsh-better-edit/`) for exactly this path.

## Interacts with

- `../machine-wide-ptc/` — unchanged and required: `mode: both` keeps native
  calls working beside `eval`. Do not switch to `mode: code` while Dashr is
  mounted (its collapse guard and the PTC collapse would fight).
- `../dsh-ptc-plus/`, `../dsh-better-edit/` — **REMOVED 2026-09-05, superseded
  here**; their READMEs record the removal and remain valid rollback docs.
- `../dsh-llm-fallbacks/` — functional overlap with Dashr's built-in failover;
  kept installed for now (its route-chain policy is richer). Revisit if the
  two ever disagree.
- `../tier1-plugins/` — `dsh-lsp-actions` etc. unaffected; Dashr's `dvc://lsp`
  device is an alternative surface, not a replacement of those rows.
- `setup/verify.sh` — BUNDLES lists `better-dsh` (replaced `dsh-ptc-plus` and
  `dsh-better-edit`); §9 checks the `dashr-repl` row; the old ptc-plus patch
  check is gone.
