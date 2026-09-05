# plugins/ — customization entries

One directory per non-shipped customization (plugin, agent preset, or
composition change). Shipped baseline behavior is *not* recorded here —
`RESTORE.md` assumes a stock install as the starting point.

## Entry format

Each entry is a directory containing:

- `README.md` — what it is, why it exists, dependencies, step-by-step install
  instructions for a baseline install, and how to verify it works.
- The **full** definition: complete plugin source, composition rows, or preset
  files. Never just names or pointers to files outside this repository.
- For inherently session-scoped pieces (e.g. dynamic Cordis plugins): the full
  host/client source plus the exact steps to re-define and re-activate them.

## Application index

Entries must be applied in the order listed here:

1. `dshmarket/` — plugin-market UI inside Settings, **installed first** so the
   rest can be browsed/upgraded from the GUI (nothing depends on it; a CLI
   install works identically). **Dependency-only** since DeepSeek Harness
   desktop 0.3.8: NOT a `dsh.profile.bundles` entry (a bundle layer duplicates
   the desktop's own `dsh-market` insert and kills the boot — see its README).
   Its Backup & Restore export — stripped of private paths and committed as
   `$KIT/profile-backup.stripped.json` — is the canonical record of the whole
   profile state; re-export + strip after any profile-wide change.
2. `agent-browser-skill/` — browser automation for agents (requires the
   `agent-browser` CLI; see its README for the dependency install).
3. `dsh-better-edit/` — **REMOVED 2026-09-05** (superseded by entry 8's
   `better-dsh/`, which re-wires the same hashline read/edit/write/undo natively
   and adds URL-scheme reads). README kept as the rollback recipe.
4. `hindsight-coding-agents/` — Hindsight long-term memory (official profile-
   bundle plugin; requires a reachable Hindsight server + a dsh restart).
5. `tier1-plugins/` — coding-agent capability pack: DAP debugger, LSP actions,
   checkpoint/rewind, LLM fallback chains, web-search failover, and four MCP
   servers (requires `uv`; dsh restart).
6. `dsh-better-reasoning-effort/` — reasoning-effort and input-modality
   declarations for custom (`llm-pi-ai`) provider models, edited inside the
   official Models page (profile-bundle plugin; dsh restart).
7. `machine-wide-ptc/` — machine-wide Code Mode (PTC): writes the home-level
   `$DSH_HOME/cordis.patch.yml` that sets the deployment default tool
   presentation to **`mode: both`** — native per-tool schemas *and* the
   built-in `run_code` + generated TypeScript SDK — for every profile. Not an
   npm bundle: the machinery ships inside stock `dsh`. Apply before the final
   restart so one boot activates everything.
8. `better-dsh/` — **Dashr** (npm `better-dsh@0.2.2-b`): replaces both former
   entries here — a host-plane bundle whose `eval` tool runs one Python cell on
   **one persistent IPython kernel per session** (variables survive across
   cells; optional `dill` snapshots restore across restarts), with every budget
   configurable (`runTimeoutMs` etc.) **and a model-settable per-call
   `timeout` parameter**, plus native hashline `read`/`write`/`edit`/
   `undo_last_edit` that shadow the stock tools and resolve `skill://`,
   `ctx://`, `agent://`, `dvc://`, `http(s)://` URLs. Needs
   `--config.auto-install-peers=false` on install, `allowBuilds: zeromq: true`,
   and an auto-provisioned kernel venv (or `DASHR_KERNEL_PYTHON`). Coexists
   with entry 7's `mode: both`. The old `dsh-ptc-plus/` entry (incl. its
   qwencloud root-`oneOf` patch finding) is kept as the rollback recipe.
9. `dsh-better-sidebar/` — the Web GUI **sidebar workbench** (npm profile
   bundle): explorer/editor/terminal/Git tabs replacing the stock workspace
   seat, plus a published `ctx.betterSidebar.registerTab` face so other plugins
   mount into the sidebar. Needs `allowBuilds: node-pty` in the profile's
   `pnpm-workspace.yaml`; install needs the system pnpm on PATH (see its README).
10. `dsh-ui-subagent-monitor/` — **subagent monitoring as an additional plugin
   for that sidebar**: `@leetoners/dsh-ui-subagent-monitor` mounts a Subagents
   entry at the sidebar foot (`sidebar.footer.action`) and a live card panel
   (`shell.overlay`) showing every child run of the current session; jump into
   any child conversation and back (profile bundle; dsh restart).
11. `subagent-model-routing/` — powerful root + cheap coding model for
   delegated children, via an **agent preset** (materialized at
   `$DSH_HOME/.agent-presets/code-subagent-flash/`, a copy of the shipped
   `code` preset): delegation-tool `agentOptions.{provider,model}` override the
   parent-inherited route per tool row. Not an npm bundle; select it at
   Settings → General → Agent preset (or the new-session hero chip).

## How the npm bundles get installed

All profile bundles land in **one** batched command — one resolution pass, one
atomic `package.json` write, one restart. The four held-back bundles are pinned
explicitly (see *Version currency*), so the command reproduces the kit's
recorded state instead of reaching for npm latest. When the desktop AppImage
ships an older pnpm than the profile store was written with, prefix the command
with `PATH=/usr/bin:$PATH` (system pnpm v11 vs store v11 here) — otherwise pnpm
exits `ERR_PNPM_UNEXPECTED_STORE`:

```sh
dsh plugin --profile web add \
  '@vectorize-io/hindsight-coding-agents' dsh-checkpoint-rewind@0.6.1 \
  dsh-debugger-dap dsh-llm-fallbacks@0.3.5 dsh-lsp-actions@0.4.0 \
  dsh-search-failover dsh-better-reasoning-effort@0.2.3 better-dsh@0.2.2-b \
  dsh-better-sidebar@0.18.0 @leetoners/dsh-ui-subagent-monitor@0.2.0
```

`dshmarket` is handled **separately** as a dependency-only entry (its README's
Install section) — before or after the batch, profile quiescent either way.

After any bundle add/remove (by CLI or through the market), finish the task by
refreshing the canonical record: re-export via **Advanced → Backup & Restore →
Export backup**, strip per `dshmarket/README.md`, and replace
`$KIT/profile-backup.stripped.json` — then `setup/verify.sh --record`. The
§3 check compares the recorded specs against the live profile and WARNs on drift.

Two things the batch command gets wrong on its own, both found in the
2026-09-04 (afternoon) restore:

1. **`dsh plugin add` rewrites `dsh.profile.bundles` in alphabetical order**,
   which differs from the kit's recorded order. Fix the list by hand in the
   profile's `package.json` to match the recorded layer stack:
   `@vectorize-io/hindsight-coding-agents`, `dsh-checkpoint-rewind`,
   `dsh-debugger-dap`, `dsh-llm-fallbacks`, `dsh-lsp-actions`,
   `dsh-search-failover`, `dsh-better-reasoning-effort`, `better-dsh`
   (`dshmarket` never appears — dependency-only, see entry 1). Observed again
   2026-09-05: adding `better-dsh` also **re-inserted `dshmarket` into the
   bundles list** — remove that row again or boot dies on the duplicate
   `dsh-market` loader id.
2. **Core-ecosystem drift can make §4 FAIL with a version skew** even with all
   bundles held: `@deepseek-ai/schemastery` 3.18.2 (whose own dep wants
   cosmokit `^1.8.3`) and `@deepseek-ai/cosmokit` 1.8.3 were published after the
   morning sweep, and the bundles' `^3.18.1` regular-dep ranges hoisted them
   over the installation's 3.18.1 / 1.8.2 (dsh 0.1.1-rc.2). Pin the hoisted
   copies back to the installed versions — in pnpm 11 that means `overrides`
   **in `pnpm-workspace.yaml`** (its `pnpm.overrides` field in `package.json` is
   no longer read) — then force a re-resolution (delete `pnpm-lock.yaml` and
   `pnpm install`; `install` alone reports "Already up to date"):

   ```yaml
   overrides:
     '@deepseek-ai/schemastery': 3.18.1
     '@deepseek-ai/cosmokit': 1.8.2
   ```

   §4 then returns to the documented same-version WARN. Re-evaluate this pin
   when the harness itself moves to core 0.1.2-rc.1 (which ships the newer
   schemastery), not before.

Measured on a warm pnpm store: 3 specs batched = 0.29s, 3 separate adds =
0.84s. Parallel installs are **not** an option: two concurrent `pnpm add` calls
in one project both exit 0 while the last writer wins, silently dropping the
other's dependency **and** its `dsh.profile.bundles` entry and leaving a dangling
`node_modules` symlink. Keep the profile quiescent — one install at a time, and
no other session running `dsh plugin` concurrently.

Afterwards, and after every later change, run `../setup/verify.sh` (one command
replaces the whole checklist below; `--full` also probes the MCP servers over
stdio).

## Version currency

`setup/verify.sh` §10 compares every installed bundle against `npm view <name> version`,
so a stale pin surfaces as a WARN instead of rotting silently. Sweep of **2026-09-04**:

| bundle | live | npm latest | status |
| --- | --- | --- | --- |
| better-dsh | 0.2.2-b | 0.2.3 (npm `latest` tag) | installed 2026-09-05; **held at 0.2.2-b** — the 0.2.3 publish was pulled back: dist-tags are `{latest: 0.2.3, beta: 0.2.2-a, alpha: 0.2.2-b}` and the maintainer's own test reports reference higher local builds; re-check before upgrading |
| dshmarket | 1.41.0 | 1.41.0 | upgraded (was 1.33.0) |
| ~~dsh-ptc-plus / dsh-better-edit~~ | — | — | **removed 2026-09-05**, superseded by better-dsh |
| @vectorize-io/hindsight-coding-agents | 0.5.1 | 0.5.1 | upgraded (was 0.4.3) |
| dsh-checkpoint-rewind | 0.6.1 | 0.6.5 | **held** — wants `cordis ^4.0.2` + `schemastery ^3.18.2` |
| dsh-lsp-actions | 0.4.0 | 0.4.4 | **held** — same cordis/schemastery gap |
| dsh-llm-fallbacks | 0.3.5 | 0.4.1 | **held** — ~24 core peers pinned to `^0.1.2-rc.1` |
| dsh-better-reasoning-effort | 0.2.3 | 0.3.5 | **held** — wants core `>=0.1.2-rc.1` |

The four held upgrades are not a risk-tolerance judgement: they declare host-plane peers
this install cannot satisfy (it ships cordis 4.0.1, schemastery 3.18.1, core 0.1.1-rc.2),
and pnpm only *warns* — it installs unsatisfiable peers anyway. A bundle reaching for
core APIs that do not exist at boot is precisely the ground-rule-2 failure, and it is
machine-wide rather than one plugin. So §10's WARN is the guard, and holding is the
default.

Unblocking them means updating the harness: `@deepseek-ai/dsh` is at **0.1.2-rc.1**
(`next` and `latest` both) while this install runs 0.1.1-rc.2. After that, re-run §10; if
the held rows clear, one batch finishes it:

```sh
dsh plugin --profile web add dsh-checkpoint-rewind@0.6.4 dsh-lsp-actions@0.4.3 \
  dsh-llm-fallbacks@0.4.1 dsh-better-reasoning-effort@0.3.5 && ../setup/verify.sh --record
```

(Historic, pre-2026-09-05 — kept for the rollback path) `dsh-better-edit@0.6.1`
(zod `^3.25.76`) and `dsh-checkpoint-rewind@0.6.1` (zod `^4.4.3`)
do want conflicting zod majors. Checked, not assumed: the root hoist took 4.4.3 and the
linker nested a private copy for the other, so `dsh-better-edit` resolves
`node_modules/dsh-better-edit/node_modules/zod` ⇒ **3.25.76**, and its only zod consumer
(`lib/store-config.js`) loads against its own major. Neither zod is an `@deepseek-ai/*`
package, so §4's core-shadow guard stays green. Worth re-checking the same way after any
future bump.

## Recommended, not installed — desktop client

Researched 2026-08-28 (full comparison: `../.research/desktop-clients-research.md`,
trigger: the Web GUI works but is "a bit clunky"). If a native window is ever
wanted, the pick is
[dsh-tauri-desk/deepseek-harness-desktop](https://github.com/dsh-tauri-desk/deepseek-harness-desktop)
("DeepSeek Harness 桌面版", MIT, ★1,333, v0.9.2 released 2026-08-28): a Tauri 2
shell that runs the *same* harness surface —
`dsh --profile <profile> --host 127.0.0.1 --port 3080` with `DSH_HOME=~/.dsh` —
and **prefers an already-installed global `dsh` core**, so this kit's web
profile and every bundle here keep working inside the native window unchanged.
Linux ships AppImage + `.deb` (no AUR package; on Arch run the AppImage or
extract/convert the .deb); the note records the documented Wayland/WebKitGTK
workarounds (`WEBKIT_DISABLE_DMABUF_RENDERER=1 GDK_BACKEND=x11`) relevant to
Hyprland. Runner-up: [s3yf1337/dsh-desktop](https://github.com/s3yf1337/dsh-desktop)
— genuinely "desktop as a plugin, not a fork", but ★2 and its `desktop` profile
needs all bundles reinstalled as a second batch.
[hust-open-atom-club/oh-dsh](https://github.com/hust-open-atom-club/oh-dsh)
(★288) was rejected for this kit: it pins its own DSH + Node runtimes and
would re-platform the stack the kit reproduces. The Electron clients
(dataelement/dsh-desktop, anywhere-labs) ship no Linux artifact at all.
Nothing is installed for this yet; adoption is a user-level .deb/AppImage
plus a new entry dir here — no changes to the profile's bundle list.
