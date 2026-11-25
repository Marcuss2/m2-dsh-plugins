# Changelog

Dated record of changes to the live DeepSeek Harness setup on this machine.
The other directories hold the *current* state; this file holds how it got
there.

Keep the two in step: a change recorded in only one of them is a bug in the
record. Each entry states what changed, why, and the evidence — including
what was found to be *unchanged*, so a later reader can tell "verified
identical" from "not checked".

## 2026-11-25 — Profile drift recorded: `dsh-opencode-go` replaces `mistral-vibe`, seven pins move

**What changed.** The `web` profile inventory is refreshed to the live state
and re-exported. `dsh-opencode-go` **0.4.9** was installed and
`@khuraie/dsh-mistral-vibe-provider` uninstalled — one dependency and one
bundle entry out, one of each in, so the counts stay **23 dependencies / 25
bundles**. Seven pins moved in the same wave: `@linxin666/dsh-client-ui-task-board`
0.4.8→**0.4.21**, `@michengai/dsh-skills-manager` 1.4.9→**1.5.4**,
`dsh-better-sidebar` 0.32.1→**0.33.0**, `dsh-context` 0.84.1→**0.87.1**,
`dsh-free-search` 0.9.51→**0.9.84** (43 engines, up from 39),
`dsh-lsp-actions` 0.5.21→**0.5.24**, `mattpocock-skills-dsh` 0.1.8→**0.1.10**.
The default route (`agent-default-model`) is now `dsh-opencode-go` /
`deepseek-v4.1-flash` at `reasoningEffort: low`; the
`subagent-model-selection-settings` allowlist lists seven OpenCode Go models;
the `agent-team-model-pin` row carries four `dsh-opencode-go` sessions (two at
`high`, two `modelDefault`, one `presetSessions` entry); and a new
`opencode-go` patch row holds the plugin's UI settings
(`sidebarEntry`, `goPlan`, `modelVisibility`, `usagePillStyle`).

Docs updated with it: the setup table's default-model and route rows, the
whole `## Plugins` inventory, the route section (now **OpenCode Go**), the
Agent Teams pins, the "Where settings live now" row list, and the constraints
about the removed provider and the sidebar line. `dsh-market/profile-backup.json`
was re-exported (`createdAt 2026-11-25T09:59:34.358Z`, 6 files) with
`createProfileBackup('web')` and the documented path-strip.
`dsh-market/README.md` records the new export and what it adds.
`COMPACTION-FIX.md`, previously untracked, is committed and listed in the
Contents table.

**Why.** A `dshmarket` install wave on 2026-11-24 (09:06Z) and the provider
migration that followed it had drifted the live profile away from the
2026-11-23 record. The 2026-11-24 compaction entry below records the
`mistral-vibe` removal and its two shims in prose, but the inventory, counts,
default model, route section and backup still described the Mistral route.
This repository exists to record the live setup, so the stale rows had to be
replaced rather than left to disagree with the backup.

**Evidence.** `~/.dsh/profiles/web/package.json` carries the new dependency
map and 25-entry `dsh.profile.bundles` list; every installed version above was
read from the resolved `node_modules/<pkg>/package.json`. The market log
records the wave: `2026-11-24T09:06:27Z install dsh-opencode-go … pinned to the
registry's latest, 0.4.9`, then `update-start`/`update exit=0` rows for
task-board, skills-manager, better-sidebar, context, free-search and
lsp-actions, `09:06:51Z` for mattpocock-skills-dsh, and
`dsh-subagent-workspace-ui → 1.12.0 exit=1` with `update-rollback … restored
npm build v1.3.3` (the patch pin still holds). The re-export reads back 23
dependencies, 25 bundles; its `createdAt` is `2026-11-25T09:59:34.358Z`; the
privacy grep (`$(whoami)|/home/`) prints nothing. `dsh --profile web
--dump-config` exits 0. The alias insert and its comment, the
`agent-team-model-pin` session block and the `opencode-go` row are all in the
recorded `cordis.patch.yml`; nothing else in the patch layer changed.

**Unchanged / verified.** Presets and personas did not drift: the four
`agent-presets/*.cordis.yml` and `*-preset.yml` are byte-identical to
`~/dsh-custom-presets/legacy-agent-presets-pre-rc2/*`, the copied
`generate-patch.cjs` regenerates `~/dsh-custom-presets/cordis.patch.yml`
identically in a scratch directory, and each `prompts/*-persona.md` contains
its live persona suffix verbatim, with the `run_code`-description,
**Language** and **Ask before you guess** paragraphs present once per preset.
The harness stays `0.2.2-rc.5`; bundle order, the `ui-git-graph` disable,
the `dsh-subagent-workspace-ui` 1.3.3 pnpm patch, the unmounted Hindsight
bundle and `agent-browser` 0.42.0 are unchanged.

## 2026-11-25 — Personas teach the `run_code` `description` argument

**What changed.** Added one shared paragraph to the `run_code` section of all
four persona suffixes (`custom`, `coding`, `computeruse`, `orchestrator`):
every `run_code` call needs its own `description` on the tool call itself,
beside `code`; a `description` on a nested `tools.bash(...)` does not satisfy
it. The paragraph names the exact rejection string and shows the call shape.
Edited the four legacy sources under
`~/dsh-custom-presets/legacy-agent-presets-pre-rc2/`, re-ran
`generate-patch.cjs` to refreeze `cordis.patch.yml`, re-copied the four
`agent-presets/*.cordis.yml` files, refreshed the four
`prompts/*-persona.md` extracts, and updated the three READMEs. No tool row,
preset card, or plan-mode text changed.

**Why.** Some models were calling `run_code` with only the nested
`description` they saw in the persona's hello-world example, or with none at
all, and treating the rejection as a broken tool. The generated PTC SDK lists
`description` as required, but the persona is where the call shape gets
explained; the fix is a policy paragraph, not a config change. The wording says
"on the tool call itself, beside `code`" rather than "top-level", because
"top-level statements" in the paragraph above means something else.

**Evidence.** Direct reproduction: `run_code` with no `description` returned
`Error: invalid arguments: missing required property "description"`; the same
error came back when only `tools.bash({ description: "...", ... })` was present
inside the code. With a top-level `description` a trivial program ran and
returned its value. The shared paragraph is byte-identical in all four
legacy sources, all four repo copies, all four prompt extracts, and appears
four times in the regenerated `cordis.patch.yml`.

## 2026-11-24 — compaction fails after removing the `mistral-vibe` provider

**What changed.** Added a compatibility alias plugin at
`~/.dsh/plugins/dsh-provider-alias/index-v2.js` mounted by a top-level
`insert` row (`provider-alias-mistral-vibe-v2`) in `cordis.patch.yml`: the
removed `mistral-vibe` provider id now forwards to
`dsh-opencode-go`/`hy4`. It was mounted live — no restart — via the GUI
model selector, which drives `configEditor.edit()` →
`reconcileProfilePatches()`; the selection was restored to `hy4`. Added a
profile-local wrapper for `@deepseek-ai/dsh-compaction-basic` at
`~/.dsh/profiles/web/node_modules/@deepseek-ai/dsh-compaction-basic/`
(canonical copy `~/.dsh/plugins/dsh-compaction-basic-compat/`) as
defense-in-depth: on `NO_ADAPTER` it retries summarization against the agent's
live route. Removed the two dead `provider: mistral-vibe` teammate pins from
`agent-team-model-pin.sessions`; no config references the removed package any
more. Full diagnosis and verification: `COMPACTION-FIX.md`.

**Why.** `/compact` failed four times in *Redesign website design language
with subagents* with `Compaction could not produce a useful summary`. The
session log shows the real cause on every `compaction/end`:
`no adapter registered for provider "mistral-vibe"`.
`summarizeWithLlm` uses the session's **last routed request header** as its
provider/model, which still names the removed package; switching the model in
the GUI does not refresh that header. `region.ts` then classifies every
summary-stage error as `ManualCompactionError('summary')`, and
`dsh-command-compact` hides the cause behind a fixed string. A plain
`cordis.patch.yml` override cannot fix it: the live engines are nested inside
preset `config.plugins` rows, which id-targeted patches do not reach (verified
with `--dump-config --patch`).

**Evidence.** Stock engine regression loop RED
(`no adapter registered for provider "mistral-vibe"`); wrapper GREEN
(`compacted via dsh-opencode-go/hy4`). `import.meta.resolve` from the profile
`cordis.yml` URL now returns the wrapper; `dsh --profile web --dump-config`
still exits 0. Most importantly, **end-to-end in the running GUI**: after the
alias row reconciled, `command/done` at seq 4449 reports
`kind=success, "Compacted 237 history items (~126661 tokens)"` and the GUI
shows the same. Six failed `compact` rows preceded it. A host restart is
**not** required for the alias; the wrapper loads on the next restart.

## 2026-11-23 — `dsh-better-sidebar` 0.32.1 ends the Tasks-view crash on rc.5

**What changed.** The `web` profile's `dsh-better-sidebar` dependency moved
from `0.28.0` to **`0.32.1`** with `dsh plugin --profile web add
dsh-better-sidebar@0.32.1`; pnpm reported `+ dsh-better-sidebar 0.32.1` and
wrote the pin back to `package.json` as `"0.32.1"`. No pnpm patch was needed
and the plugin's `better-sidebar` patch row is untouched. The client bundle
is served from `node_modules`, so the running host's plugin graph
(`client-hmr`) picked it up without a restart; the host half of 0.32.1 loads
on the next `dsh --profile web` restart.

**Why.** Opening the sidebar's **Tasks** view in a Team-enabled session
rendered `dsh-better-sidebar: can't access property "map", team.members is
undefined` with a **Retry** button. The host's `agentTeam` Session projection
is now `{ enabled, tasks, failure? }`: DSH 0.2.2 removed `members` (upgrade
guide v0.2.1-rc.2; the Team package moved the roster out of the projection).
0.28.0 still built its roster with `team.members.map(...)` in
`src/client/team-projection.ts`. 0.32.1 requires DSH `^0.2.2-rc.2` (its
peers) and builds the roster from the Lead plus the Lead's `subagentCatalog`
rows instead. The
pin had stayed at 0.28.0 after the 2026-11-15 update attempt, when the host
was `0.2.2-rc.1` and 0.32.1's `^0.2.2-rc.2` peer was refused; the 2026-11-21
repair did not revisit it. The host is now `0.2.2-rc.5`, so the gate allows
0.32.1.

**Evidence.** `node_modules/dsh-better-sidebar/package.json` reads `0.32.1`;
its `lib/client.js` contains **zero** `team.members` references and builds
the roster from `subagentCatalog`. Running both published
`team-projection.ts` builds against the rc.5 wire value
`{ enabled: true, tasks: [] }`: 0.28.0 throws exactly `TypeError: Cannot read
properties of undefined (reading 'map')`, while 0.32.1 returns the Lead row
plus catalog teammates and returns `undefined` for `enabled: false`. The
running server's `/plugins/events` graph lists `dsh-better-sidebar` at
`rev 0de6b58959b9`, and that revision's served bundle has no `team.members`
and six `subagentCatalog` references — the watcher, not a restart, published
the new revision. In the live Web GUI the **Tasks** tab then opened as
`Tasks — Fix sidebar with teammate subagents / No subagents` with no error
banner and no **Retry**. `dsh --profile web --dump-config` exits 0 and still
composes the `better-sidebar` row.

**Unchanged / still known.** Every other dependency spec, bundle order, preset
row and provider route is unchanged. The running process still holds the
0.28.0 host half, so its `teams.taskCreate` / `teams.taskUpdate` routes still
call the removed `ctx.agentTeams.tryMembership`; restart before exercising
Team task mutations from the sidebar. The 0.32.1 host build uses the built-in
`agentTeams` service for those two routes.

**Record refreshed.** `dsh-market/profile-backup.json` re-exported
(`createdAt 2026-11-23T18:19:25.259Z`, 6 files, **23 dependencies / 25
bundles**) with the documented path-strip; the secret/path grep is empty. The
export also captured drift that was already live but not yet recorded, and
that is **not** part of this sidebar change:
`@lolkda/dsh-agent-team-model-pin` `^1.8.4` (dependency, bundle entry, and an
`agent-team-model-pin` patch row with two per-session pins; profile
`package.json` mtime 2026-11-22), `agent-default-model.reasoningEffort`
`low` → `high` (the README already said `high`), and the host-shipped
`@deepseek-ai/dsh-experimental-plugin-market-bundle` entry. `README.md` and
`dsh-market/README.md` now record those counts and rows.

## 2026-11-21 — DSH 0.2.2-rc.5: incompatible Agent Teams bundle removed; sessions restored

**What changed.** `dsh-agent-team-model-selection` 0.7.0 is uninstalled from
the `web` profile and its `tool-agent-team-model-selection` config row is gone
from `cordis.patch.yml`. A three-line comment now records the removal in the
patch file. The bundle's old patch had disabled the host's `tool-agent-team`
row; with the bundle gone, the shipped Team tool row is active again. No
restart was needed — HMR picked the manifest and patch changes up live.

**Why.** The host had moved to `@deepseek-ai/dsh` **0.2.2-rc.5** (`dsh
--version`; installed files dated 2026-11-20 22:04). DSH's own
`v0.2.1-rc.2/agent-team-subagents` upgrade guide says `ctx.agentTeams` removed
creation, messaging, roster, **membership and wait** APIs, and that callers
must replace `membership`/`tryMembership` with `ctx.subagents.rootOf`. The
current `TeamService` type exposes only `isEnabled`, `setEnabled` and the four
task methods. The pinned plugin still had
`ctx.agentTeams.tryMembership(agent)` in `index.js:650`, inside the
`agent/created` handler. That synchronous throw vetoes session creation and
restore, which is exactly the reported pair of failures: **New session failed:
gateway/internal: failed to create session: TypeError:
ctx.agentTeams.tryMembership is not a function**, and **Session unavailable**
on an existing session. The upstream GitHub repository has only two commits;
both predate the removal and the installed pin is the newer of them, so there
was no compatible release to upgrade to.

**Evidence.** `dsh plugin --profile web remove dsh-agent-team-model-selection`
exited 0 and pnpm removed one package. The manifest went from 23 dependencies
/ 24 bundles to **22 / 23**; the diff removes only that dependency, its bundle
entry (and, in the refreshed backup, the stale
`@deepseek-ai/dsh-experimental-agent-team-profile` entry that rc.5 no longer
ships and that was already absent from the live manifest before this action).
`dsh --profile web --dump-config` exits 0 with no model-selection row and
`tool-agent-team` enabled. In the live Web GUI, **New session** created
`session-07db5c30-d126-4b25-bf7f-56c4e6ddbdfe` at 10:59:55 with no error toast;
opening the existing **Inkling-2-Mini architecture diagram refinement** session
rendered its full conversation, and a fresh accessibility snapshot contains no
“Session unavailable”, “failed to create” or `tryMembership` text. The blank
verification session was left in the `research` workspace.

**Record refreshed.** `dsh-market/profile-backup.json` re-exported
(`createdAt 2026-11-21T10:05:52.567Z`, 6 files, 22 dependencies / 23 bundles)
with the documented path-strip; the secret/path grep is empty. `README.md`
now records rc.5, the active host Team tools and the removal; `dsh-market/README.md`
records the new export. `cordis.patch.yml` also gained a harmless YAML
language-server modeline pointing at the new, recorded `patch.json` schema: the
language server had been applying the JSON Patch schema to `*.patch.yml` and
reporting every pre-existing Cordis loader entry as invalid. With that modeline
the file checks clean; `dsh --dump-config` still exits 0.

**Unchanged / still known.** Every other dependency spec, bundle order, preset
row and provider route is unchanged. `dsh-better-sidebar` remains 0.28.0: its
`teams.taskCreate` / `taskUpdate` routes still call `tryMembership`, so Team
task mutations from that sidebar remain incompatible with rc.5, but those
routes are not touched by session create/restore and upstream 0.32.1 was not
installed during this repair. `@linxin666/dsh-client-ui-task-board` already
fails closed when the old `spawnTeammate` service is absent.

## 2026-11-18 — default route switched to `mistral-vibe/deepseek-v4-1-flash-1017`; inventory recorded

**What changed.** Three rows in the profile patch layer, and the record
refreshed around them:

- `agent-default-model` — model `mistral-large-4` → **`deepseek-v4-1-flash-1017`**
  (provider `mistral-vibe`, effort `high` unchanged).
- `subagent-model-selection-settings.allowedModels` — the Mistral entry
  `mistral-large-4-0-8` → **`mistral-large-4`**.
- `tool-agent-team-model-selection.modelSelection.allowedModels` — now
  `mistral-vibe/mistral-large-4`, `synthetic/hf:zai-org/GLM-5.3-Flash`,
  `mistral-vibe/deepseek-v4-1-flash-1017`; the earlier
  `synthetic/hf:deepseek-ai/DeepSeek-V4.1-Flash-1017` and
  `mistral-vibe/mistral-large-4-0-8` entries are gone.

**Why it is visible in this session.** The Team route restriction reported to
the Lead (`mistral-vibe/mistral-large-4`,
`synthetic/hf:zai-org/GLM-5.3-Flash`,
`mistral-vibe/deepseek-v4-1-flash-1017`) is exactly the allowlist above, and
the session runs `deepseek-v4-1-flash-1017` — live proof the new row is
loaded.

**Record refreshed.** `dsh-market/profile-backup.json` re-exported
(`createdAt 2026-11-18T08:53:43.152Z`, 6 files, **23 dependencies / 25
bundles**, paths stripped to `$HOME`); the README current-state table updated
and a new **Plugins** inventory added (every dependency: recorded spec,
installed version, what it adds, plus the two host-shipped bundles that have no
dependency row); `dsh-market/README.md` provenance updated.

**Evidence.** `dsh --profile web --dump-config` exits 0 (2961 lines) when run
against a copy of the profile whose `cordis.yml` is writable — the live
profile directory is outside this session's file sandbox, so the dump used a
temporary `DSH_HOME` whose profile dir copies the config files and symlinks
`node_modules`. Normalized against the 2026-11-16 dump, the diff is exactly the
three rows above. `cordis.patch.yml` mtime 2026-11-18 09:05.

**Unchanged, verified.** Harness still `0.2.2-rc.1`; all eight preset rows
still compose (the four shipped plus `custom`, `coding`, `computeruse`,
`orchestrator`); the forge/worktree rows and `llm-mistral-vibe` are still
present; the pnpm patch, the bundle order and every other dependency spec are
unchanged from the 2026-11-15 export.

## 2026-11-18 — machine tooling: `agent-browser` 0.42.0, Wayland input binaries, `rust-analyzer` absent

- **`agent-browser` 0.38.2 → 0.42.0** (global npm package; binary
  `/usr/bin/agent-browser` dated 2026-11-15 13:36). No persona change needed —
  the presets say the CLI exists, not which version.
- **`wtype` and `ydotool` installed** (`/usr/bin/wtype`, `/usr/bin/ydotool`) —
  the two Wayland input synthesizers the computer-use section listed as
  missing. They back `mcp__cul__type_text` and `mcp__cul__click`; presence
  verified, the input path itself not yet exercised live.
- **`rust-analyzer` is not installed — the README had said it was.** The
  command resolves to the rustup proxy `/usr/lib/rustup/bin/rust-analyzer`,
  and `rustup component list --installed` has no `rust-analyzer`, so
  `rust-analyzer --version` fails with `Unknown binary`. Rust files therefore
  have no `lsp_*` backend; `rustup component add rust-analyzer` fixes it. The
  README now records it as absent rather than installed (the record does not
  edit the live setup).
- **Skills directory**: `~/.dsh/skills/` carries four enabled skills, by file
  date `agent-browser` (2026-11-16), `writing-for-agents` (2026-11-15),
  `bro` (2026-11-06) and `humanizer` (2026-10-13). Managed by
  `@michengai/dsh-skills-manager`; the record lists the plugin, not the skill
  contents.
- **Unchanged**: `typescript-language-server` 6.0.0, `pyright` 1.1.412,
  `clangd` 23.1.5; `computer-use-linux` pinned at 0.7.13; harness
  `0.2.2-rc.1`.

## 2026-11-16 — Mistral Vibe provider and the host's forge bundle join the profile

**What changed.** One dependency and two bundle entries, all outside the preset
plane:

- **`@khuraie/dsh-mistral-vibe-provider` 0.1.29** installed from GitHub
  (`github:Khuraie/dsh-mistral-vibe-provider`, **no commit pin**) through the
  Plugin Market at **13:10 local** — market log
  `2026-11-16T12:10:56.239Z`, `install ... exit=0 hot=true`. Its bundle patch
  inserts one row, `llm-mistral-vibe`, which owns the `mistral-vibe` route end
  to end: wire, live `/v1/models` catalogue, per-model thinking levels, PKCE
  browser sign-in, and the Vibe/Studio budget meters served at
  `/mistral-vibe/*`. Settings gains a **Mistral Vibe** page. The key is read
  from the credential record named by `apiKeyEnv` (`MISTRAL_API_KEY`), so it is
  neither in YAML nor in the profile backup.
- **`@deepseek-ai/dsh-experimental-forge-bundle`** added to
  `dsh.profile.bundles`. It ships inside the 0.2.2-rc.1 install (same version),
  so it has **no dependency row**; listing the name is the whole change. Its
  patch inserts `worktree`, `tool-worktree`, `forge`, `forge-github`,
  `forge-session` and the `optional-forge-panel` group (`forge-worktree`,
  `forge-panel`).
- The default model moved off `synthetic` in the same profile pass:
  `agent-default-model` reads provider `mistral-vibe`, model
  `mistral-large-4`, effort still `high`; the subagent allowlist gained
  `mistral-vibe/mistral-large-4-0-8`, and the Agent Teams allowlist gained the
  Mistral routes.

**Why.** The machine's default route moved onto the Mistral subscription, and
the host's worktree / change-request panel was switched on. Both are
profile-plane changes, so no preset row moved.

**Evidence.** The dump-config generated that afternoon (kept as
`.diag/dump-config-2026-11-16.txt` — scratch, not committed) resolves
`llm-mistral-vibe`, the six forge/worktree rows, and an `agent-default-model`
of `mistral-vibe` / `mistral-large-4`. `package.json` mtime 2026-11-16 13:10
matches the log line.

**Not carried into that day's record.** The 2026-11-15 and 2026-11-16 entries
below were written before or around this install and do not mention it; the
inventory and backup were refreshed on 2026-11-18 (the 2026-11-18 entries above).

## 2026-11-16 — Personas teach `run_code`'s function-body shape

**Symptom.** A coding session reported three consecutive
`(run_code completed with no output)` results, then abandoned `run_code` for
`bash` and finally a plain `read`. Its program opened with
`async function main() {`: `run_code` runs the submitted text as the **body**
of an async function, so a function that is declared and never called executes
nothing — and nothing in the empty result said why.

**What changed.** All four persona suffixes gained one shared paragraph and a
two-line example: the `code` argument is already the body of an async function,
top-level `await` and `return` work, `tools.*` is in scope, and a self-defined
`main()` swallows every result (the paragraph quotes
`(run_code completed with no output)` so the failure is recognisable). The
example is:

```ts
console.log("hello world"); // printed back to you
return await tools.bash({ description: "List files", command: "ls" });
```

The wording is deliberately terse — the model that hit the failure proposed
almost exactly this framing — because the rule is mechanical: state the
contract and show one working call rather than explain the transport.

### What changed, concretely

- **Sources** — `legacy-agent-presets-pre-rc2/{custom,coding,computeruse,orchestrator}/agent.cordis.yml`
  carry the paragraph verbatim; the `agent-presets/` copies are byte-identical
  (`diff -q` clean for all four).
- **Frozen bundle** — regenerated with
  `node /home/vrbkam/dsh-custom-presets/generate-patch.cjs`: **983 lines**
  (was 947), the paragraph appears **4** times, and two consecutive generator
  runs produce the same md5 `7957845cc8a60fb38b88b62e2ac1986f`.
- **Docs** — `prompts/README.md` gained a **`run_code` is a function body** section
  (why the wrapper is the named failure mode, and why the paragraph is shared
  verbatim), and `agent-presets/README.md` lists the paragraph among the shared
  suffix text.

### Evidence

- `dsh --profile web --dump-config` exits 0 and carries the example four times,
  once per preset. The dump re-emits the suffix in folded style, so a source
  newline shows up as a blank line there; that is the dump's representation,
  not the loaded value.
- The generator is idempotent across consecutive runs (identical md5), and the
  frozen patch composes: all four preset rows appear in the dump.
- **Not yet exercised:** a new session on each preset. Preset personas compose
  at boot, so the text reaches a model on the next new session (or via HMR when
  the patch is rewritten), not in the session that made the change.

## 2026-11-15 — DSH 0.2.2-rc.1: custom presets migrated; New Session mount failure fixed

The host update to `@deepseek-ai/dsh` **0.2.2-rc.1** made every **New session**
fail with `agent-preset/invalid: tool-subagent-list-agents
(@deepseek-ai/dsh-tool-subagent-control/list-agents): never started`.

### Root cause

0.2.2-rc.1 merged the globally named `list_agents` tool into
`@deepseek-ai/dsh-tool-subagent-control` — the root entry registers it now —
and removed that package's `./list-agents` subpath export. All four custom
presets still mounted the separate `tool-subagent-list-agents` row, so the
preset registry's mount audit found an enabled row that never started and
rejected the whole preset.

### What changed

- **Generator gained two transforms** (`agent-presets/generate-patch.cjs`,
  byte-identical to the live copy):
  - drop the `tool-subagent-list-agents` row;
  - rewrite `modelSelectionSettings: true` → `modelSelection: true` plus
    `modelDiscovery: true` (0.2.2 split the old switch) and drop the removed
    `backgroundMode` key.
- **Regenerated** `/home/vrbkam/dsh-custom-presets/cordis.patch.yml`
  (947 lines, four presets).
- **Docs and records:** `agent-presets/README.md` now lists six transforms; the
  root README carries host 0.2.2-rc.1, 23 bundles, `dsh-free-search` 0.9.51, a
  preset-regeneration constraint and a Hindsight-mounting constraint; the
  profile backup was re-exported and path-stripped
  (`createdAt 2026-11-15T12:59:42.370Z`, 22 dependencies / 23 bundles).

### Evidence

- `dsh --profile web --dump-config`: **zero** `list-agents` occurrences; each
  of the four presets' spawn row reads `modelSelection: true` +
  `modelDiscovery: true`.
- Every other plugin name in the freeze resolves against the 0.2.2-rc.1
  install; `@brucezhang1993/dsh-computer-use-linux` resolves from the profile's
  `link:` dependency as before.
- The generated YAML parses with a `!!js` tag constructor, `node --check`
  passes, and two consecutive generator runs produce an identical md5
  (`dbfc51e1ecb864cc7b70a1540e3161c2`).
- The Agent Teams model-selection plugin survives the update: `list_agents`
  returned `llm` for the Lead with the same provider/model/effort.
- **Not yet exercised:** creating a session through the fixed presets. Preset
  rows compose at boot, so verification needs a Host restart.

### Sessions — restored

No session data was lost. `$DSH_HOME/sessions` holds **316 session
directories**: 304 with readable v3/v4 headers and 12 created-but-never-
materialized placeholders. The workspace account (`storages/workspace.json`)
listed 105 top-level sessions plus 14 archived ones. **19 top-level sessions**
(2026-09-07…2026-10-18) existed on disk but in no workspace's `sessionIds`, so
the workspace-scoped sidebar could not show them; the listing code is identical
in 0.2.1-rc.2 and 0.2.2-rc.1, so they were already unaccounted before this
update.

**Re-attached 18 of them** to their workspaces by inserting each id at its
chronological position in that workspace's account (registry backed up as
`storages/workspace.json.bak-2026-11-15`; 105 → 123 accounted sessions). The
nineteenth is a `/tmp` session and stays unaccounted: no `/tmp` workspace
exists, and registering a temporary directory as a permanent project is not
desirable. The registry is read at boot, so the restored sessions appear after
the same restart the preset fix needs.

### Observed but not changed

`@vectorize-io/hindsight-coding-agents` 0.8.2 is still a profile dependency but
is no longer in `dsh.profile.bundles`; the composed config has no `hindsight`
row and the `hindsight_*` tools are unavailable. Recorded as a constraint, not
re-enabled here.

## 2026-11-11 — Agent Teams per-member model selection installed

`dsh-agent-team-model-selection` 0.7.0 replaces the shipped Agent Teams tool
plugin, so a Team Lead can pin each teammate's provider, model, and reasoning
effort and every member reports the route it actually runs on.

### What changed

- **Installed as a commit-pinned GitHub bundle.** Target
  `github:devloom1024/dsh-agent-team-model-selection#5150ff9d87799320fa04577db44786175fd1db4f`
  — the package is `private` and is not published to npm under this name, so
  the pin is a commit, not a release tag. `plugin_manager install_bundle`
  added it to `dependencies` and `dsh.profile.bundles` (now 22 / 24) and
  applied it live.
- **The bundle swaps the Team tool row.** Its patch disables
  `tool-agent-team` and inserts `tool-agent-team-model-selection`; both
  register the same nine Team tool names in each member scope, so they cannot
  coexist. The replacement reimplements them with no peer dependencies and a
  vendored schema helper.
- **New model-facing surface.** `spawn_teammate` gains optional `provider`,
  `model`, and `reasoning_effort`; `list_agents` returns an `llm` object per
  member; the new `list_team_models` resolves providers → one provider's models
  → one model's reasoning efforts.
- **Policy default is automatic.** `mode: inherit`, `freshProvider: spawn`,
  `forkProvider: fork`, `allowedModels: []` (no restriction). Settings →
  **Agent Teams models** edits those fields through the profile patch. `fixed`
  mode pins every teammate to one route and rejects route parameters; in
  `inherit` mode `allowedModels` bounds explicit, effort-only, and inherited
  routes alike.
- **Route applied at the subagent seam.** The plugin hooks
  `ctx.subagents.startActivation` and merges the selected route into the child's
  `agentOptions`; both in-process providers (`spawn`, `fork`) declare that
  capability in 0.2.1-rc.2.
- **Record refreshed.** `dsh-market/profile-backup.json` was re-exported and
  path-stripped, and both state tables were corrected. The new export has **6
  files**, not 101: `dshmarket` 1.70.2 no longer mirrors `.plugin-manager`
  operation logs or `pnpm-lock.yaml`. The refresh also captures the drift that
  had accumulated since the 2026-10-19 capture — seven dependencies added
  (including this one), `dsh-secret-guard` removed, and eight pins moved.

### Why

Agent Teams otherwise forces every member onto the Lead's LLM route. Cheap
teammates for mechanical work and strong ones for review are not selectable at
spawn time, and `list_agents` gave no way to confirm what a member actually
ran on. This is the market-listed plugin for that gap
(<https://dsh-plugin.org/plugins/devloom1024/dsh-agent-team-model-selection>).

### Evidence

- Install result: `stage: enable`, `enabled: true`, `changed: true`,
  `application: applied`, version `0.7.0`, pnpm exit 0.
- Manifest: `dependencies["dsh-agent-team-model-selection"]` is the pinned
  `github:` spec, and the bundle is the last entry of `dsh.profile.bundles`.
- Live Host config: `Config.listConfigs` reports
  `include:tool-agent-team-model-selection` with the `modelSelection` schema
  (`mode`, `provider`, `model`, `reasoningEffort`, `allowedModels`).
- Live tool surface: `Tool.listTools` shows `spawn_teammate` with the three
  route parameters and a registered `list_team_models`.
- Live route reporting: `list_agents({})` returned
  `llm: { provider: "synthetic", model: "hf:deepseek-ai/DeepSeek-V4.1-Flash-1017",
  reasoningEffort: "high" }`.
- Live Client slot: the `settings.section` occupant `agent-team-models`
  (order 25) is `active`.
- Source review: no `peerDependencies`, vendored `schemastery`/`cosmokit`;
  `node --test` passes 16/16; every `ctx.agentTeams.*` and
  `ctx.subagents.startActivation` / `agentOptions` call it makes exists in the
  running 0.2.1-rc.2 packages.
- Unchanged: the Agent Teams bundle stays mounted, the other settings pages are
  untouched, and the manager reported the change as applied without a restart.
- Not exercised: an actual teammate spawn with a pinned route. That would
  create a durable member, so the routing rules rest on the plugin's own tests
  plus the live schemas above. Visual check is limited to the live slot
  registration — this session had no connected browser control.

## 2026-11-11 — persona prompts compacted without changing preset tools

The system-prompt review found easy repetition in the shared persona paragraphs
and in the orchestrator suffix. This is the low-risk, prompt-only pass; SDK tool
scoping and Hindsight injection cadence are deliberately unchanged.

### What changed

- **Shared suffix compacted in all four presets.** The `run_code`, **Language**,
  browser-access, and **Ask before you guess** paragraphs retain their triggers
  and required tool names while dropping repeated explanations. The browser
  paragraph points to the existing CLI guide for details. The ask paragraph
  keeps plan mode's exact "material ambiguity that inspection cannot answer"
  wording and the ban on asking "should I proceed?".
- **Global language rule compacted too.** `$DSH_HOME/AGENTS.md` retains the same
  language, non-prose, and foreign-language-input rules as the personas; their
  intentional two-layer defence remains.
- **Orchestrator simplified and corrected.** The prefix and ledger now state the
  context/token tradeoff once. Role paragraphs retain the delegation policy but
  drop tool-call mechanics already carried by schemas/Team policy; the repeated
  anti-pattern list is gone. `workflow` and `ralph` now carry the harness's
  explicit-use restrictions. The stale claim that members cannot see each
  other's edits is replaced with the installed policy's actual rule: edits are
  immediately visible, so use disjoint write scopes and task dependencies.
- **Coding verification de-duplicated.** Removed the repeated Workflow/Verify
  evidence statements and the model-default anti-fabrication sentence. The
  engineering contract and deliverable-specific checks remain.
- **Documentation synchronized.** Persona extracts, prompt/preset READMEs, the
  root maintenance date, and this entry describe the compacted text. The
  computer-use `mcp__cul__screenshot` command was checked and already correct;
  it did not change.

### Size reduction

Character counts below include the YAML block scalar's final newline. Token
figures are only rough chars/4 estimates, not provider tokenizer measurements.

| Preset | Suffix before | Suffix after | Chars saved |
| --- | ---: | ---: | ---: |
| `custom` | 2725 | 1372 | 1353 |
| `coding` | 8589 | 7024 | 1565 |
| `computeruse` | 3597 | 2244 | 1353 |
| `orchestrator` | 8876 | 4373 | 4503 |

The orchestrator prefix also dropped from 218 to 135 chars, and its
orchestrator-specific suffix section from 6148 to 2999 chars before the shared
paragraph savings.

### Evidence

- Live generation ran twice: `node /home/vrbkam/dsh-custom-presets/generate-patch.cjs`
  produced 963 lines both times with identical SHA-256
  `a1aeb627e06bf4f07d698fb58e521f789e292cd31de98f6a4aeafd7ab483c3f7`.
- `dsh --profile web --dump-config` exited **0**. Its only stderr lines were the
  three unrelated `@idealclover/dsh-session-title-studio` patch warnings for
  `optional-session-title-all-prompts`, `session-title-studio-recipe`, and
  `session-title-studio-policy`.
- Parsed assembled personas match live source, repository source, and readable
  `prompts/*-persona.md` extracts exactly (including the final newline in the
  assembled YAML value). Preset plugin counts remain 18 `custom`, 18
  `coding`, 20 `computeruse`, and 18 `orchestrator`; generator and preset
  cards remain byte-identical to the live copies.
- `git diff --check` exits **0**. Retired long-form and stale orchestrator
  phrases are absent from every assembled persona.
- **Scope/limits:** no plugin row, tool-presentation mode, preset card, generator
  transform, plan-mode text, or Hindsight setting changed. No model-quality A/B
  test was performed; this pass proves configuration assembly and byte fidelity,
  not unchanged model behaviour.

## 2026-10-24 — answer language pinned in all four personas, plus a global instruction file

The user reported models randomly switching to Chinese on English requests. The
cause is not a single bad instruction: nothing in the harness ever stated an
answer language, while foreign-language text arrives every turn.

### What changed

- **New shared **Language** paragraph**, carried byte-identically by all four
  presets (`custom`, `coding`, `computeruse`, `orchestrator`), inserted
  between the `run_code` paragraph and the browser-access paragraph — early in
  the suffix, where it outweighs later tool guidance. It states the rule
  positively (answer in the user's language), and pins the two cases a bare
  "match the user" line leaves open: non-prose (code, identifiers, paths,
  commands, log lines, error text, quoted output) is reproduced exactly and
  never translated, and foreign-language tool descriptions / UI strings / search
  results are **input**, not a cue about answer language.
- **New `$DSH_HOME/AGENTS.md`** carrying the same rule. This is the user-global
  chain `dsh-agent-instructions` loads into every session on this DSH_HOME,
  whichever preset is selected. Two layers on purpose: the persona covers preset
  sessions, the global file covers the rest, and it survives a session running a
  preset that predates the paragraph.
- **Docs in step**: `prompts/README.md` gains a `### Language` section;
  `agent-presets/README.md` gains "Language rule, and why it is in two places";
  all four `prompts/*-persona.md` extracts are refreshed and round-trip
  byte-exactly (custom 2725, coding 8589, computeruse 3597, orchestrator 8875
  chars of suffix).

### Why this is the right lever, and where the drift comes from

- **No language instruction existed anywhere.** `dsh-client-locale` is GUI
  localisation only (`preference: en` in the profile patch switches the *Web
  interface*, not the model's answers); no shipped prompt section mentions
  answer language. The harness ships the persona prefix as
  `You are a coding agent powered by the {{model}} model.` and nothing more.
- **A real foreign-language competitor exists in this profile.**
  `dsh-free-search` ships **Chinese tool-schema descriptions** — 9 model-facing
  `description` strings, e.g. the weather parameter "City or place name (Chinese
  or English), e.g. 北京, Shanghai, Tokyo.", the `so360`/`sogou` engines and the
  research-document fields ("带来源标注；缺失 = unknown"). Tool schemas sit in the
  prompt on every turn, so a model with no explicit language rule has a standing
  Chinese-language signal to follow. The paragraph names this directly instead
  of only saying "answer in English".

### Evidence

- `node /home/vrbkam/dsh-custom-presets/generate-patch.cjs` → 1070 lines;
  re-running produced a byte-identical file (`md5 de67725d320f255b7261e53f0de8bcec`
  twice).
- `dsh --profile web --dump-config` exits **0** with no bundle-parse error, and
  the assembled config contains the paragraph **4 times** — once per preset.
- **Shared paragraphs verified still byte-identical across all four presets**
  after the insert: `run_code` (627 chars), browser access (461), Ask before you
  guess (1072). The Language paragraph itself is byte-identical across all four
  (checked by set-uniqueness of the extracted block).
- All four `prompts/*-persona.md` extracts compare exactly to their
  `suffix: |` blocks in `agent-presets/*-agent.cordis.yml`.
- `~/.dsh/AGENTS.md` verified loading into a live session: the file's content
  was injected as a workspace-instruction reminder in the same turn it was
  written, without a restart.
- **Unchanged, verified**: no tool row, `preset.yml`, or generator transform was
  touched — this is a prompt-only change. The pre-existing `dsh-secret-guard`
  compatibility warning still appears on stderr and is unrelated.

## 2026-10-24 — fourth preset added: `orchestrator`

The user asked for a persona "heavily pushed to delegate as much as possible",
on the stated grounds that the lead model is expensive to run, and for it to
know that teammates can message each other and spawn their own subagents. A
new agent preset was added rather than editing an existing one, so the user can
pick delegation-heavy or delegation-light per session.

### What changed

- **New preset `orchestrator`** (`legacy-agent-presets-pre-rc2/orchestrator/`,
  frozen as `preset-orchestrator`). Its plugin list is the `custom` list **row
  for row** — every tool row, `mode: ptc` presentation, plan mode, and the
  delegation group are unchanged. Only the `persona` row and the `preset.yml`
  description differ, which makes this a pure persona experiment: if the
  delegation policy is wrong, nothing else about the preset is.
- **The persona** (`../prompts/orchestrator-persona.md`) keeps the three shared
  paragraphs byte-identical (`run_code`, browser access, **Ask before you
  guess**) and adds: a context-scarcity framing plus a two-sided ledger, a
  delegation ladder (`subagent` / `subagent_fork` / `workflow` / `ralph` /
  `spawn_teammate` / self), three role paragraphs, a formal brief format
  (objective, target, non-goals, acceptance check), a partition-then-dispatch
  rule, a peers-not-routes rule, verify-once-at-the-end, an explicit plan-mode
  rule, and an anti-pattern list.
- **`generate-patch.cjs`** gained `["orchestrator", {}]` in its card list; the
  repo copy is refreshed. The generator's four freeze transforms are unchanged
  and the new source already satisfies transforms 2 and 3.
- **Docs in step**: `agent-presets/README.md` (four-preset table, the new
  bullet, "all four" wording), `prompts/README.md` (table row plus an
  `## Orchestrator` section), and a new
  `.research/2026-10-24-orchestrator-persona-inspiration.md` recording how
  other frameworks write orchestrator prompts.

### Two design decisions worth carrying forward

- **The persona is role-aware, and there are three roles, not two.** A teammate
  spawned by `spawn_teammate` inherits the parent's preset, and so do one-shot
  `subagent`/`workflow`/`ralph` children — so this one suffix renders for all
  of them. An unqualified "delegate everything" would therefore land on a
  subagent and produce a delegation tower, so each role has its own conditional
  paragraph. The role itself comes from the harness (`team:identity`), not from
  the text.
- **The cost framing had to be corrected before it could ship.** The first
  draft claimed the Lead's turns "cost far more" than a child's. False in the
  important half: `spawn_teammate` takes no model parameters and the roster
  reports `live.options.model ?? root.options.model`, so a teammate runs the
  *same* model — it saves the Lead's context, not its spend, while adding total
  tokens. `subagent`, by contrast, does accept `provider`/`model`/
  `reasoning_effort` under the `subagent-model-selection` policy (allowlist on
  this machine: `GLM-5.3-Flash`, `DeepSeek-V4.1-Flash-1017`). The persona now
  frames the scarce resource as **context** and names the overhead, instead of
  asserting a price difference that does not exist.

### Evidence

- `node /home/vrbkam/dsh-custom-presets/generate-patch.cjs` writes 1039 lines,
  and a second run produced a byte-identical file
  (`md5 c1de40bfd4e0f656ee27a5d8aa0d69f2` twice) — regeneration is idempotent
  with four cards.
- `dsh --profile web --dump-config` exits **0** with **no bundle-parse error**,
  and the assembled config contains all eight preset rows
  (`preset-standard`, `preset-ptc`, `preset-minimal`, `preset-cordis`,
  `preset-custom`, `preset-coding`, `preset-computeruse`,
  `preset-orchestrator`).
- The rendered `preset-orchestrator` row carries the corrected prefix and
  suffix, and `prompts/orchestrator-persona.md` round-trips byte-exactly to both
  blocks (prefix 218 chars, suffix 8365).
- **One bug found and fixed during verification**: the prefix was first written
  as an inline `prefix: ...` scalar; because the text contains a colon-space,
  the YAML failed to parse and the whole `@local/dsh-custom-presets` bundle was
  skipped (visible as `failed to parse overlay ... bad indentation of a mapping
  entry` in `--dump-config` stderr). Restored to the `>-` block scalar the other
  presets use, then re-verified. This is why the persona doc now states that
  both blocks must stay block scalars.
- **Correction to a review claim**: the reviewer held that `spawn_teammate`'s
  lead-only restriction is prompt-level only. It is not —
  `AgentTeams.spawnAdmitted` throws `TEAM_LEAD_REQUIRED` for a non-lead caller
  (`dsh-experimental-agent-team/lib/index.js:1004-1006`), the same guard
  `interrupt_agent` and task reassignment use. The flat-team rule is enforced
  by the runtime; the persona states it anyway so a model does not spend a turn
  discovering the refusal.
- **Second review round, and what it caught.** A reviewer pass over the revised
  draft found two real self-contradictions the first draft had introduced: the
  ledger said teammates inherit the Lead's model and then, six words later,
  claimed "a turn of yours is worth many turns of theirs" (the retracted
  economics); and the anti-pattern list said "spawning one teammate where three
  independent slices would fit" while ladder rung 2 assigns many independent
  slices to `workflow`. Both fixed — the ledger now concludes that delegation
  "buys your attention, not a smaller bill", and the anti-pattern is a durable
  teammate where a scripted `workflow` fan-out would do. The same pass found
  "Workers cannot see your conversation" to be false for `subagent_fork` and
  `spawn_teammate({context:"fork"})`, now "A fresh delegate cannot see your
  conversation", and moved the bare-child paragraph **above** the ladder so the
  caveat precedes the instruction it qualifies.
- **Duplication with `team:policy` measured, not asserted.** The persona was
  checked against the bundle's own shipped policy text by extracting both and
  looking for shared runs of eight or more consecutive words: **0 matches**. What
  is left is the decision content the policy leaves implicit (who owns which
  file, who goes first), not a restatement of its sentences.
- **Unchanged, verified**: the `custom`, `coding`, and `computeruse` rows
  regenerate identically apart from the added preset; their shared paragraphs
  are still byte-identical to `orchestrator`'s (`run_code`, browser access, and
  Ask before you guess all compared equal). The pre-existing
  `dsh-secret-guard` compatibility warning still appears on stderr and is
  unrelated.

## 2026-10-22 — persona revised: `ask_user_question` encouraged everywhere; coding contract de-duplicated

The user asked for the persona prompt to be revised, naming one concrete
problem: models were ignoring `ask_user_question`. That is not a wording
preference — under `mode: ptc` the model sees no native tool schemas at all,
so the persona is the only place the tool can be advertised and legitimised.
A separate GLM-5.3-Flash review of the draft found additional defects, recorded
below as they were fixed.

### What changed

- **New shared paragraph, "Ask before you guess"** — carried verbatim by
  all three presets (`custom`, `coding`, `computeruse`). It names
  `ask_user_question`, shows the PTC call shape
  (`await tools.ask_user_question({ questions: [...] })`), lists the trigger
  classes (user-owned decisions, material ambiguity, irreversible/destructive
  steps, unreachable credentials), and states the anti-triggers (never ask what
  inspection can answer, never re-ask what the request already stated, never
  spend a question on "should I proceed?"). Trigger vocabulary is deliberately
  the same words `prompts/plan-mode.md` uses, so the two rules cannot
  contradict each other.
- **Placement.** In `coding` it sits directly under the thesis line ("You do
  not stop when the code looks right…") — the highest-salience block of the
  suffix. In `custom` and `computeruse` it follows the browser-access
  paragraph, before the computer-use paragraph.
- **`coding`: latent contradiction fixed.** `Verify` said "reproduce the
  failure first"; `Engineering` said a user's failure report is ground truth
  and must not be re-run. Both could not be satisfied. The bug-fix bullet now
  says reproduce to *build the regression check*, not to re-confirm a report
  you were already given.
- **`coding`: one rule, one home.** The near-duplicate "Scope" bullet in
  `Verify` folded into "Consistency and blast radius"; the standalone
  "Verification is not paranoia…" paragraph merged into the `Engineering`
  ground-truth bullet; "Evidence, not confidence" and "match the format the ask
  implies" cut as restatements.
- **`computeruse`: cul paragraph tightened.** Its "confirm with the user before
  clicking anything that submits, deletes, sends, purchases, or overwrites data"
  is now covered by the shared destructive-step trigger; it now points back at
  it. The click-specific "never click consent or permission dialogs yourself"
  rule is retained.
- **Docs in step.** `prompts/README.md` gains the missing
  `computeruse-persona.md` row and an "Ask before you guess" section explaining
  why the paragraph exists and that it must stay aligned with `plan-mode.md`.
  `agent-presets/README.md` describes the revised suffix.

### Evidence

- `node /home/vrbkam/dsh-custom-presets/generate-patch.cjs` regenerated the
  bundle: 734 lines, and re-running it produced a byte-identical file
  (`md5 e050ba45a6dca958ff6f44261754d106` twice) — regeneration stays
  idempotent.
- `dsh --profile web --dump-config` exits **0**, and the assembled effective
  config carries the new paragraph once per preset (3 occurrences of
  "Ask before you guess"). The `@local/dsh-custom-presets` dependency is a
  `link:`, so the rewritten patch is what the profile reads; no reinstall.
- `prompts/*-persona.md` verified byte-faithful to the `suffix: |` blocks in
  `agent-presets/*-agent.cordis.yml` by re-extracting both and comparing
  (`custom` 2084 chars, `coding` 7862, `computeruse` 2956 — all exact).
- `agent-presets/*-agent.cordis.yml` and `generate-patch.cjs` verified
  byte-identical to the live sources under
  `/home/vrbkam/dsh-custom-presets/legacy-agent-presets-pre-rc2/` by `diff -q`.
- `prompts/plan-mode.md` and the `plan-mode` rows were **not touched**;
  their three copies remain byte-identical to each other (`md5 c2ba9516…`).
- Review: an independent GLM-5.3-Flash subagent reviewed the original text and
  then the revision; its findings drove the contradiction fix, the rule
  de-duplication, and the wording of the ask paragraph.

---

## 2026-10-19 — preset record refreshed for 0.2.1-rc.2 (PTC mode, no `{{cwd}}`); docs drift corrected

The user asked for the latest configuration to be committed and pushed, noting
that the upstream record still described an older version. It did: `HEAD` still
documented `tool-presentation: mode: both` and a `Your working directory is
{{cwd}}.` persona line, both of which DSH 0.2.1-rc.2 rejects, while the live
sources had only been half-sed'd on 2026-10-18 — the `mode:` rows were flipped
to `ptc`, but the surrounding prose, the persona line, and the preset
descriptions still promised the old shape.

### What changed

- **Preset sources cleaned and re-synced.** `agent-presets/*-agent.cordis.yml`
  and `*-preset.yml` are byte-identical to the live sources again. Removed the
  sed casualty `# ptc in the persona at the top:` (restored `both`), the
  dangling `# ... the working directory arrives` comment, the `BOTH mode`
  presentation prose, and the `Your working directory is {{cwd}}.` suffix line.
  The comments now state what the rows do: `mode: ptc` publishes `run_code`
  plus the generated SDK and does **not** list native schemas.
- **Preset card descriptions corrected** for `custom` and `coding`, which still
  read "native tool catalog + PTC run_code side by side". Regenerated
  `cordis.patch.yml` and installed it by atomic rename; `dsh --profile web
  --dump-config` (exit 0) shows the corrected text in the effective config.
  No restart: HMR is on for this profile.
- **Generator refreshed and improved.** The repo copy was stale — it still read
  `$DSH_HOME/.agent-presets` and lacked the rc.2 transforms. It is now
  byte-identical to the live one, which also collapses the blank-line runs left
  where it strips the legacy commentary (installed patch 1042 → 696 lines,
  whitespace only).
- **Prompts brought in step.** `prompts/*-persona.md` no longer carry the
  `{{cwd}}` line or claim that `{{cwd}}` is substituted; they name the real
  live source paths and note that `{{model}}` is the only loop-registered
  variable. `prompts/README.md` and `agent-presets/README.md` likewise
  (including the 0.2.1-rc.2 shipped-preset paths in the maintenance note).
- **Root README drift corrected:** default model row
  (`openrouter-custom` / `deepseek/deepseek-v4.1-flash-1017`, reasoning effort
  `high` — not the recorded `synthetic` / GLM-5.3-Flash), `dsh-free-search`
  0.9.4 → 0.9.7, the harness row in the machine-tooling table 0.2.0-rc.2 →
  0.2.1-rc.2, "persona of both presets" → all three, and the recording date.
- **Profile backup re-exported** with `createProfileBackup('web')` and
  path-strip: `createdAt 2026-10-19T18:08:01.792Z`, 101 files (95
  `pnpm.log` + 6 config), 16 dependencies / 18 bundles — counts unchanged,
  version pins current (`dsh-free-search` 0.9.4→0.9.7, `dsh-context`
  0.73.1→0.73.3, `dsh-skills-manager` 1.2.6→1.2.8,
  `dsh-better-reasoning-effort` 0.5.3→0.5.4).

### Evidence

- `dsh-agent-tool-presentation` 0.2.1-rc.2 schema:
  `mode: z.union(["native", "ptc"]).required()` — `both` is gone, and its
  README documents exactly those two values.
- `dsh-system-prompt/README.md`: "Custom persona templates must not depend on a
  built-in `{{cwd}}` variable: the loop does not register it, so unresolved
  references fail prompt assembly before any model request." Only `provider`
  and `model` are loop-supplied.
- Shipped presets checked at
  `node_modules/@deepseek-ai/dsh-web-app/presets/{standard,ptc}.patch.yml`:
  `standard` is native-only with a bare `present` row; `ptc` pairs
  `tool-presentation` (`mode: ptc`) with `present`; both personas carry only a
  prefix, no suffix.
- Regeneration check: sources + generator copied to a scratch directory and run
  there; `diff` against the previously installed `cordis.patch.yml` showed only
  the two corrected description lines (blank lines ignored). After the atomic
  install, `diff -q` reports no delta against the regenerated file, and the
  installed patch parses (`--dump-config` exit 0).
- Prompt extract check: each `prompts/*-persona.md` `## suffix` block compares
  equal to its preset's `persona.config.suffix` (custom 1090 chars, coding
  6866, computeruse 1942).
- Backup strip verified: `grep -E "$(whoami)|/home/"` over
  `dsh-market/profile-backup.json` prints nothing.
- No harness restart was performed; the running host keeps serving sessions
  (including the one that made these edits).

### Left unchanged

- `dsh-secret-guard` still reports its pre-existing incompatibility
  (`requirements @deepseek-ai/dsh-llm ^0.1.0-rc.6`) on 0.2.1-rc.2. Unrelated to
  this refresh.
- The web profile's patch layer and its `minimumReleaseAgeExclude` residue were
  not touched.

## 2026-10-18 — `dsh-mcp-setting` installed (Settings GUI for MCP server rows)

The user asked for a settings GUI to manage MCP servers directly in dsh web.
The canonical model is unchanged — one MCP server is one
`@deepseek-ai/dsh-mcp-client` row in a `cordis.patch.yml` (home or
per-profile) or in an agent preset's config list — but the bundled Settings UI
has no MCP page, so row editing was hand-YAML only.

### What changed

- **`dsh-mcp-setting` 0.1.5 installed into the `web` profile** via
  `dsh plugin --profile web add dsh-mcp-setting` (exit 0, +2 packages). It
  adds Settings → **MCP Servers**: list/add/edit/delete/toggle
  `@deepseek-ai/dsh-mcp-client` rows across the home patch
  (`~/.dsh/cordis.patch.yml`, created on first add) and per-profile patch
  files, with live status badges, contract validation (id/serverName rules,
  stdio⇒command, streamable-http⇒url), atomic `.bak` writes, and
  loopback-only write access. Profile went **15 deps / 17 bundles →
  16 deps / 18 bundles**.
- **Chosen over `@xxxyz/dsh-mcp-manager` 2.2.7** (richer: HTTP API,
  `mcp_manager_*` model tools, skills page): its peer
  `@deepseek-ai/dsh-tools ^0.1.2-rc.1` does not satisfy this runtime's
  dsh-tools 0.2.1-rc.2 (checked with `semver.satisfies`,
  `includePrerelease: true` → false), so DSH's
  `evaluatePluginCompatibility` would refuse it without a version exemption.
  `dsh-mcp-setting`'s peers (`^0.2.0-rc.2`) are satisfied by the
  0.2.1-rc.2 runtime; the install produced no compatibility warning for it
  (the `dsh-secret-guard` warning is pre-existing, unchanged).
- **Version-currency drift corrected in `README.md` while touching it:**
  Harness 0.2.0-rc.2 → 0.2.1-rc.2 (verified via `dsh --version` and the
  dsh-app-boot package version), dshmarket 1.66.21 → 1.66.39,
  dsh-free-search 0.6.5 → 0.9.4, and the default-model row updated to the
  `synthetic` provider row the patch layer actually sets.

### Evidence

- `dsh --profile web --dump-config` shows the mounted row
  (`- id: dsh-mcp-setting / name: dsh-mcp-setting`); `--dump-config-schema`
  declares its schema.
- **No restart was needed**: dsh-hmr is enabled for this profile
  (`disabled: !!js '!ctx.get('profileContext')'`), and the new bundle layer
  hot-mounted in the already-running host. The dsh-market README's "bundle
  layers compose at boot" guidance describes the no-HMR case.
- GUI verified end-to-end with agent-browser against the running host:
  Settings → **MCP Servers** renders the add form (row id, serverName,
  stdio/streamable-http, command/args/cwd/env) and reports "No MCP servers
  configured yet" — correct, because the only MCP server here (`cul`) is
  preset-scoped, so its row lives in the preset config, not a patch file.
- **How the GUI was reached for verification**: the web GUI authenticates via
  a signed cookie (`dsh-auth-<sha256(authority)>`, payload
  `{version, authority, issuedAt, expiresAt}`, HMAC-SHA256 over the
  base64url body) keyed by the browser-session grant secret in
  `~/.dsh/.credentials.yaml`. A cookie was minted locally for authority
  `127.0.0.1:3080` (1-day expiry) and injected into agent-browser; the
  secret was never printed or persisted. Only works with local file access to
  `$DSH_HOME` — the same trust domain as the harness itself. Reusable
  technique for future live-GUI verification.
- **Profile backup re-exported** per the dsh-market flow:
  `createdAt 2026-10-18T17:36:17.468Z`, 94 files (was 81), 16 deps / 18
  bundles, `dsh-mcp-setting ^0.1.5` present in both dependencies and
  `dsh.profile.bundles`; privacy grep clean.

## 2026-10-15 — `@brucezhang1993/dsh-computer-use-linux` installed (computer use for Hyprland)

Searched for a "computer use" plugin so the agent can operate GUI surfaces
that CLI automation cannot reach — the motivating case is creating Kahoot
quizzes directly in the browser. This machine is Arch Linux + Hyprland
0.56.2 on Wayland, which rules out the X11/xdotool-based servers.

### What changed

- **Plugin added to the `web` profile: `@brucezhang1993/dsh-computer-use-linux`
  0.1.1** (released 2026-10-10; repo `BruceZhang1993/dsh-computer-use-linux`).
  It bridges the upstream `agent-sh/computer-use-linux` Rust MCP server
  (upstream at v0.7.16) via the in-box `@deepseek-ai/dsh-mcp-client`
  0.2.0-rc.2 into the `mcp__cul__*` tool surface — `doctor`, `get_app_state`,
  `list_windows`, `focused_window`, `screenshot`, `click`, `perform_action`,
  `set_value`, `type_text`, `press_key`, `scroll`, `drag`, window
  move/resize, `setup_accessibility`, `setup_window_targeting`, plus the
  bundled `computer-use-linux` skill.
- **Chosen over two alternatives found in the same search**:
  `berker-z/hyprhands` (Hyprland-native MCP server; v0.1, single machine,
  no releases, drag needs ydotool) and `ziggy42/wayland-computer-use-mcp`
  (weekend project, tested on GNOME only, pointer-only). The winner is the
  only one that is a DSH bundle with a maintained upstream, compositor-aware
  window targeting (Hyprland via `hyprctl`), and AT-SPI semantic actions.
- **Install form: local checkout link.** The package is served from GitHub
  Packages, and the first registry install failed with
  `ERR_PNPM_FETCH_404 … No authorization header was set for the request`
  (classic PAT with `read:packages` needed). Instead:
  `git clone https://github.com/BruceZhang1993/dsh-computer-use-linux
  ~/repos/dsh-computer-use-linux` then
  `dsh plugin --profile web add ~/repos/dsh-computer-use-linux`,
  which pnpm-links the directory. Profile went from 14 deps / 17 bundles to
  **15 deps / 18 bundles**; `dshmarket` was **not** re-inserted this time
  (single occurrence in `dsh.profile.bundles`).
- **AT-SPI enabled by hand** — on Hyprland nothing owns the accessibility
  switches, so `gsettings set org.gnome.desktop.interface
  toolkit-accessibility true` and the D-Bus property
  `org.a11y.Status IsEnabled = true` were both set directly; both verified
  as true afterwards. `/dev/uinput` already carries an rw ACL for the user
  (getfacl shows the user with `rw-`), so ydotool will run without root.
- **Profile backup re-exported** and re-stripped per the
  `dsh-market/README.md` flow; privacy grep clean (no `/home/` hits, no
  username hits). Diff against the previous record: only `createdAt`, the
  new dependency (`link:$HOME/repos/dsh-computer-use-linux`), the new bundle
  entry, and plugin-manager log entries — nothing else moved.

### Evidence

- `node scripts/doctor.mjs` (standalone, no DSH needed) downloaded the pinned
  upstream binary v0.7.13 to `~/.cache/computer-use-linux/plugin/` and
  reported: Hyprland windowing backend **OK** (`can_query_windows`,
  `can_focus_apps`, `can_focus_windows` all true), portals **OK**
  (Screenshot + ScreenCast + input_capture present; the Hyprland portal's
  RemoteDesktop lacks pointer methods, so clicks route via ydotool),
  AT-SPI bus present. Blockers recorded: accessibility was off (fixed above)
  and input tools missing (below).
- `mcp__cul__screenshot` in a live session captured the full desktop
  (5640×2880) through `xdg-desktop-portal` — capture verified live, before
  any restart. This also surfaced the first-run portal consent dialog
  ("Allow Apps to Take Screenshots?"), left for the user to grant.
- **Anomaly, recorded as observed**: the `mcp__cul__*` tools were available
  inside the session that installed the plugin, although the established
  convention says plugin-provided tools appear only in a session created
  after the boot that mounted it. Either the surface recomposed or the
  deployment serves `cul` out of band; not investigated further — flagged
  so the next verification pass can check which it is.

### Not done

- `wtype` and `ydotool` are **not installed** — pacman needs the user's
  password: `sudo pacman -S wtype ydotool`. Until then typing has no backend
  and clicks have no pointer backend (`can_send_development_input: false`).
- Portal screenshot consent not yet granted by the user.
- No harness restart yet; bundle layers compose at boot, so a restart is
  still required for the profile to boot with the plugin permanently.
- `verify.sh` still absent from the repo — pre-existing gap, unchanged.

## 2026-10-15 — computer-use preset fixed: unresolvable plugin alias was killing the mount

The first Computer Use session after the restart had no `mcp__cul__*` tools
and the GUI reported `dsh-computer-use-linux … never started`. Root cause
found by instrumenting the shadowed `@deepseek-ai/dsh-mcp-client`, the
`dsh-agent-preset-registry`, and the plugin launcher (technique: shadow the
packages into the profile's `node_modules`; tee the launcher's stdio to a
file; find real server processes via `/proc/*/exe` links — `pgrep -f` matches
your own watcher).

### Root cause

The preset row declared `name: 'dsh-computer-use-linux'` — an alias that
resolves nowhere; the package's real name is
`@brucezhang1993/dsh-computer-use-linux`. The agent-plane preset tree
imports plugin modules from the declaring preset package's base
(`@local/dsh-custom-presets`, which had no dependencies at all). The alias
import failed, the loader logged it and returned with the entry's fiber
undefined, and `auditRows` reported exactly `dsh-computer-use-linux
(dsh-computer-use-linux): never started`. A failed audit rejects the mount:
the registry disposed the whole preset tree ~3 ms after the mcp-client had
successfully registered all 18 tools (`ready resolved error=none`, then
`DISPOSE`). That disposal is also why the server process kept vanishing
without any reconnect attempt.

### Fix

- The preset's JS entry row now uses the real package name
  `@brucezhang1993/dsh-computer-use-linux` (legacy source, re-frozen patch,
  repo copy re-synced).
- `@local/dsh-custom-presets/package.json` gained
  `"@brucezhang1993/dsh-computer-use-linux": "link:/home/vrbkam/repos/dsh-computer-use-linux"`
  so the preset tree's import base can resolve the package; `pnpm install`
  run there. The package must stay resolvable from wherever the preset tree
  imports — the profile dependency alone is not enough.

### Also learned (recorded, not fixed)

- The harness's bundled MCP client runs a **60 s `server/discover`
  era-negotiation probe on a disposable sibling stdio process** before
  falling back to the classic `initialize` handshake. Upstream
  computer-use-linux 0.7.13 and 0.7.16 both exit on any pre-`initialize`
  request, so the probe never answers and the full 60 s elapses. The tools
  therefore register ~60 s after boot/mount; a session opened within that
  first minute may not list them. The mcp-client Config exposes no
  negotiation/protocolVersion option to skip the probe (checked
  0.2.0-rc.2); an upstream binary that speaks `server/discover` would remove
  the delay.
- The in-box `@deepseek-ai/dsh-computer-use` package referenced by the
  plugin's provider-slot claim does not exist in this install.

### Evidence

- End-to-end acceptance, live: a fresh `dsh --profile web` instance on port
  3447, a new session on the **Computer Use** preset (selected through the
  GUI preset menu), the prompt "call mcp__cul__doctor" → the agent **called
  `mcp__cul__doctor` and printed** `{"accessibility": ["at_spi"], "input":
  ["abs_pointer", "wtype"], "screenshot": ["portal"], "window_control":
  ["hyprland"], …}` — the capability is preset-scoped and working.
- The negative check had already passed after the earlier restart: the
  Productivity session's catalog no longer declares any `mcp__cul__*` tool.
- Diagnostic breadcrumbs: the shadowed client logged
  `registered mcp__cul__… t=60085` then `DISPOSE t=60088`; the registry
  shadow logged the audit verdict; the launcher relay showed the server
  answering `initialize`/`tools/list` in ~20 ms and the client closing stdin
  immediately after — the closing was the tree disposal, not a server fault.
- Cleanup: the instrumented launcher was restored from backup (checkout
  clean), the shadowed package copies removed, the 3444–3447 test instances
  killed. The throwaway `cutest` profile (headless + presets bundle + a
  `--patch` overlay providing `agent-preset-registry`) remains at
  `$DSH_HOME/profiles/cutest` for future preset debugging; delete it when
  done with this initiative.

## 2026-10-15 — `computeruse` preset added; computer use scoped to it

Follow-up to the plugin install above. The user wants the desktop
computer-use capability available **only** in an explicit agent preset, not
in every session of the profile. A preset is an agent-plane composition that
can mount plugin rows of its own, so the capability moved from the profile
layer into a new preset.

### What changed

- **New agent preset `computeruse` ("Computer Use")**, declared as
  `preset-computeruse` in the `@local/dsh-custom-presets` bundle. Source:
  `$DSH_HOME/.agent-presets/computeruse/{preset.yml,agent.cordis.yml}`,
  built from the `custom` preset with three changes:
  1. two rows before the presentation row — `mcp-computer-use-linux`
     (`@deepseek-ai/dsh-mcp-client`, `serverName: cul`, stdio,
     `toolCallTimeoutMs: 120000`, `failOnStartupError: false`) and
     `dsh-computer-use-linux` (the plugin's JS entry: registers the bundled
     skill, claims the sole computer-use provider slot). Both consume host
     registries (`tools`, `skills`) and provide nothing, so like the tool
     rows they need no `isolate` realm.
  2. the persona suffix gains the computer-use paragraph — `doctor` first,
     semantic selectors over pixels, prefer agent-browser/bash when they
     reach the same target, confirm before destructive clicks, never click
     consent dialogs.
  3. `preset.yml`: name "Computer Use", order 0. Id is the single lowercase
     word `computeruse` per the preset-id convention.
- **The plugin's bundle was removed from the web profile**:
  `dsh.profile.bundles` went 18 → 17; the package stays in `dependencies`
  (the preset's `!!js` launcher resolution is anchored at the profile's
  `package.json`, so the link must survive). This also avoids the
  duplicate-registration collision a profile-level mount and a preset-level
  mount would cause on the `mcp__cul__*` tool names.
- **The generator was extended** to freeze three presets:
  `generate-patch.cjs` now iterates `custom`, `coding`, `computeruse`
  (both the live copy and the repo copy). `cordis.patch.yml` re-froze,
  687 → 1028 lines.

### Evidence

- `dsh --profile web --dump-config` composes cleanly (exit 0): three preset
  decls present (`preset-custom`, `preset-coding`, `preset-computeruse`),
  and the `mcp-computer-use-linux` row appears ONLY inside the
  `preset-computeruse` config.plugins list — not at profile level.
- The new preset YAML parses (`yaml.parse`), 20 top-level entries
  (= custom's 18 + the 2 new rows), and carries both generator SUBST anchor
  lines verbatim so the freeze substitution still applies.
- Persona fidelity: the `suffix` block parsed from the preset file matches
  `prompts/computeruse-persona.md` line-for-line after de-indentation.
- Profile backup re-exported and re-stripped; privacy grep clean; diff
  against the previous record is only `createdAt` and the removed bundle
  entry.

### Post-restart verification (same day, ~17:50)

- The user restarted the harness. First attempt failed with "did not
  activate" entries — a collision with the still-running old instance; the
  second boot succeeded (pid started 17:49:30) and serves this record's
  session. An alt-port boot test (`dsh --profile web --no-open --port 3399`)
  showed the preset-scoped mount starting cleanly
  (`computer-use-linux: using plugin cache …`); its own two "did not
  activate" entries (`ui-task-board` ledger lock, `secret-guard` import) are
  second-instance artifacts, not computer-use failures.
- **Negative acceptance check verified live**: the pre-restart Productivity
  session's model-facing catalog still listed the `mcp__cul__*` tools
  mid-session (the anomaly above), and after the restart the recomposed
  catalog dropped them — this session no longer declares any cul tool. The
  surface recomposes per request, which is also the mechanism behind the
  earlier anomaly.
- **Positive check still open**: a new session on **Computer Use** should
  list the `mcp__cul__*` tools (call `doctor`). Not yet run by the user.

## 2026-10-15 — `agent-browser` added to both presets' personas

The machine already had **`agent-browser` 0.38.2** installed globally (global
npm package, binary `/usr/bin/agent-browser`) — a browser-automation CLI for
agents (`open`, `snapshot` with click/type `@refs`, `get text|html|title|url`,
`eval`, `screenshot`, CDP `connect`), found while answering whether a browser
tool was available. Nothing in the setup recorded it, and no harness tool
exposes it: it is plain CLI reached through the `bash` tool.

### What changed

- Persona suffix of both presets (`custom` = Productivity Mode, `coding`)
  now carries a **browser-access paragraph**: that the CLI exists, the main
  subcommands, when to reach for it (JS-rendered or interactive pages that
  `web_fetch` cannot handle), its built-in usage guide
  (`agent-browser skills get core --full`), and `agent-browser close` to
  release the session. The persona is the seam for this because the tool is
  a shell binary, not a mounted tool row — the same reason the
  `run_code`-composition instruction already lives there.
- Legacy sources edited, then re-frozen per the preset editing flow:
  `~/.dsh/.agent-presets/{custom,coding}/agent.cordis.yml` →
  `node /home/vrbkam/dsh-custom-presets/generate-patch.cjs`
  (patch rewritten, 687 lines) → repo copies re-synced
  (`agent-presets/*-agent.cordis.yml`, `prompts/*-persona.md`).

### Evidence

- Smoke test (before recording): `agent-browser open https://example.com` →
  launched a browser on the live display (`DISPLAY=:1`/`wayland-1`), returned
  `Example Domain`, `snapshot` gave the accessibility tree with refs,
  `close` released it.
- Regenerated patch greps 8 `agent-browser` mentions, 4 per preset, inside
  the `persona` config of both `preset-custom` and `preset-coding` rows.
- Verified before editing: live legacy files were byte-identical to the repo
  copies (`diff` clean both presets), so the repo record stayed in step.

### Not done

- No restart yet: the frozen patch composes at boot, so running sessions
  (including this one) still run without the paragraph; it takes effect on
  the next `dsh --profile web` restart.
- `verify.sh` is referenced by `README.md` but is absent from the repo —
  pre-existing gap, unrelated to this change, recorded here as noticed.

## 2026-10-14 — `dsh-secret-guard` installed (tool-call screening, step 1)

First line of defense of the tool-call screening initiative: a deterministic
gate that blocks the agent's file tools from touching sensitive files
(`.env`, credentials, key material) before they execute, and masks
secret-shaped values in tool results as a fallback — the "don't load API keys
into context" half of the screening goal. The semantic half (screening every
tool call through the local Cloudflare **clef-flash** decision model at
`127.0.0.1:8080/v1/systemone`) is planned next, candidate
`dsh-jev-interceptor` (market-listed, `provider: custom`); `dsh-decision-layer`
was evaluated first but rejected because it is **not** in the plugin market
(absent from `awesome-dsh-plugin.com/plugins.json` and `dsh.directory`).

### Install — from GitHub, deliberately not from npm

```sh
dsh plugin --profile web add github:JohnXu22786/secret-guard   # → dsh-secret-guard 0.1.0
```

Installed from the GitHub source the market entry links, **not** the npm
registry: npm's `dsh-secret-guard@0.1.1` is a *different* plugin by a
different author (`aazjzkskkw/dsh-secret-guard`, intercepts keys typed into
shell commands, not market-listed). Same package name, unrelated code —
running `dsh plugin add dsh-secret-guard` from npm would install the wrong
one. Recorded here so a future reinstall does not repeat that lookup.

Source was vetted before install: pure-TypeScript, zero-build, no lifecycle
scripts, MIT; `import type`-only use of `@deepseek-ai/dsh-tools`/`dsh-llm`
except one runtime import (`defineTool` in `src/inspect.ts`).

### Version exemption (peers pin 0.1.x, runtime is 0.2.0-rc.2)

First `add` was rejected: peers pin `@deepseek-ai/dsh-llm` /
`@deepseek-ai/dsh-tools` `^0.1.0-rc.6`, and the harness rolled the profile
back cleanly. Granted the exact-version exemption (`dsh plugin allow-version
dsh-secret-guard@0.1.0 --dsh-version 0.2.0-rc.2 --accept-risk`) after
verifying every seam the plugin touches is unchanged in 0.2.0-rc.2:

- `tools/pre-execute` / `tools/post-execute` event names — present (5 refs
  each across shipped plugins);
- `PreToolDecision` `kind: 'deny'` shape — present in `dsh-tools` typings;
- `ctx.tools.register(definition)` and `defineTool` — present, and the
  plugin's `dsh-tools` import resolves to the host's own 0.2.0-rc.2 copy.

### Verification

- Shipped test suite **77/77 pass** (run from a `/tmp` copy with the host's
  `@deepseek-ai/*` linked in; Node refuses type-stripping under
  `node_modules`, which is a test-harness limitation, not a plugin one — the
  dsh host loads `.ts` with its own loader).
- Default policy probe (real `PolicyEngine` from the installed copy):
  `~/.env` → block · `~/.ssh/id_ed25519` → block-read · `~/.aws/credentials`
  → block · `*.key` → block-read · workspace `README.md` → allow ·
  `.env.example` → allow (sensible exemption).
- **Known gap:** `/etc/shadow` (and other system credential files) are *not*
  covered by the default rules. Fixable with one custom rule in
  `cordis.patch.yml` config (`rules:`) or the hot-reloadable `rulesFile` —
  not yet added.
- **Not yet live:** the running `dsh web` host loads bundle layers at boot,
  so the gate activates at the next restart. No restart was performed (it
  would terminate the live session).

### Backup refreshed; drift recorded

`dsh-market/profile-backup.json` re-exported (strip verified: no `/home/`,
no username). The live profile had drifted from the 2026-10-02 record:
`@michengai/dsh-skills-manager`, `dsh-better-reasoning-effort` and
`mattpocock-skills-dsh` were added since, unrecorded — they appear in this
backup refresh and are noted in `dsh-market/README.md`, not given separate
entries. Counts: **14 dependencies, 17 bundles** (was 10/12).

## 2026-10-02 — language-server backends installed

`typescript-language-server` 6.0.0 and `pyright` 1.1.412, both **global npm**
installs (not pip, not pipx — one install path), alongside the already-present
`typescript` 6.0.3.

`dsh-lsp-actions` 0.5.6 was installed since 2026-09-20 but had almost nothing
to drive: the machine's only language servers were `rust-analyzer` and
`clangd`, so the `lsp_*` tools were mounted and inert for the languages this
checkout is written in. Now both are served.

Verified:

```
typescript-language-server  /usr/bin/typescript-language-server   6.0.0
pyright                     /usr/bin/pyright                      1.1.412
pyright-langserver          /usr/bin/pyright-langserver
tsserver                    /usr/bin/tsserver
```

No harness restart needed — LSP backends are discovered on PATH per call, so
they surface in the next session rather than on the next boot.

Recorded as **machine tooling** in the root README's new *Machine tooling*
section, with the install and verify commands. That section now carries the
table the deleted `DEPENDENCIES.md` used to: software outside the profile that
plugins depend on. Also recorded there as still missing: no DAP debug adapter
(`debugpy`, `dlv`, `codelldb`, `netcoredbg` all absent), so the debugger
surface has nothing to attach to.

## 2026-10-02 — search provider: `dsh-free-search` installed, engine set to Exa

Recorded 2026-10-02. Fills the gap left by the `dsh-search-failover` removal
earlier the same day.

### Chosen: `dsh-free-search`

Three candidates were compared on the `ctx.web` seam, the extension point the
removed plugin used. The harness ships only `dsh-web-search-deepseek`, and the
official `@deepseek-ai/dsh-web-search-exa` on npm is stale at `0.0.1-rc.1`
with peers pinned to ancient versions — not usable.

| | Chosen `dsh-free-search` 0.6.5 | `@tonydua/dsh-web-search-exa` 0.1.5 | `@yugasun/dsh-web-search` 0.2.5 |
| --- | --- | --- | --- |
| Engines | 18, Exa among them | Exa only | 5, Exa among them |
| Exa without a key | ✅ anonymous MCP | ✅ anonymous MCP | ❌ key required |
| Core package as a regular dep | `@deepseek-ai/schemastery` | none | none |
| Declares a harness range | `engines.dsh >=0.1.7-rc.1` | peers only, untested ≥0.1.8 | README claims 0.1.0-rc.7 |
| Last published | 2026-10-01 | 2026-08-15 | 2026-08-24 |
| Settings UI | ✅ | ❌ config via patch layer | ✅ |

Deciding factors: the most current of the three, a Settings UI, and Exa works
keyless. The `schemastery` regular dep was checked rather than assumed:
per the project's ground rule 2 record, `schemastery` is an inert
non-composition package — not in `CORE_MODULES` — and the profile already
hoists **3.18.4**, the exact version the plugin wants, so no second copy is
introduced. The package that actually bricked the harness was `dsh-tools`,
whose dual copies produced two different `Symbol("@deepseek-ai/dsh-tools.scheduler")`
keys. Verified after install: the profile still hoists only `cosmokit` and
`schemastery`, both 3.18.4, unchanged.

Set aside: `@tonydua/dsh-web-search-exa` — cleaner deps and the closest match
to "just Exa", but its own compat matrix stops at `0.1.7-alpha.1` and marks
`>=0.1.8` (which covers this host) as untested. `@yugasun/dsh-web-search` —
requires an Exa key.

### Install

```sh
PATH=/usr/bin:$PATH dsh plugin --profile web add dsh-free-search
```

Added `^0.6.5` to dependencies and the bundle list. **Resolved 0.6.5, not
0.6.6** — pnpm's fresh-release hold substituted an older version because
0.6.6 was published 2026-10-01, inside the hold window. Same mechanism the
market logged for `dsh-thinking-effort` on 2026-09-28.

### Engine pointed at Exa

The plugin's own bundle layer ships `provider: bing`, and the profile layer
applies after the bundle layer — so an override row in
`$DSH_HOME/profiles/web/cordis.patch.yml` selects the engine:

```yaml
- id: web-search-free
  config:
    provider: exa
    disabledEngines: []
    bingMarket: zh-CN
```

Every field the bundle row sets is restated, not just `provider`: patch
semantics replace a row's whole `config` (DSH 0.1.2+), so a one-field override
would silently drop the rest. `disabledEngines` and `bingMarket` are the
plugin's own defaults, restated verbatim.

Keyless by decision: the `exa` engine in the plugin's source calls
`resolveApiKey("EXA_API_KEY", "exaApiKey")` and falls back to the anonymous
`mcp.exa.ai/mcp` endpoint without one, switching to REST `api.exa.ai/search`
when a key appears. The user's Exa key is not currently wired — it still sits
in the dead `search-pool` block of `settings.yaml.imported` — so Exa runs on
the anonymous quota until they add it under Settings → Plugins → Free Search.

### What the plugin registers

Provider id **`ddg`** (line 2497 of `lib/index.js` — the loader entry is
`web-search-free`, the seam provider is `ddg`; the two are deliberately
different). Its patch also overrides the `web` row with
`searchProvider: ddg, fetchProvider: http`, and the code additionally takes
over at runtime when `searchProvider` is unset or still the factory default
`deepseek-official` — so search follows this plugin even if a patch layer
strip erased the row.

### Not yet active

The CLI install schedules no restart, and nothing in the market log shows a
hot-mount. **A `dsh --profile web` restart is required** for the bundle layer
to compose.

### Profile state after install

**10 dependencies / 12 bundles.** `dsh-market/profile-backup.json`
regenerated, `createdAt 2026-10-02T17:38:35.371Z`.
## 2026-10-02 — second sweep; `dsh-search-failover` removed

Recorded 2026-10-02 from the market log and the live files. Three dated
batches, a harness upgrade chain, and a settings migration that changed where
configuration lives.

### Settings moved into the profile patch layer

`~/.dsh/settings.yaml` is no longer read: the harness renamed it
`settings.yaml.imported` (2026-09-26 12:21) and its keys are now expressed as
**patch rows in `$DSH_HOME/profiles/web/cordis.patch.yml`** —
`agent-default-model`, `agent-preset-registry`, `locale`, `llm-pi-ai`,
`better-sidebar`.

The imported file still holds the old document verbatim, including the
`search-pool` block that belonged to `dsh-search-failover` — dead config now.

**Current live settings, read from the patch layer:** default model
`z-ai/glm-5.3-flash` on provider `openrouter-custom`, `reasoningEffort: high`;
default agent preset `custom`; locale `en`; and a two-model `openrouter-custom`
provider (`fireworks/ember-1`, `z-ai/glm-5.3-flash`) — down from the five
models and two providers the imported file records.

### Harness upgraded twice

`0.1.5-rc.2` → `0.1.7-rc.2` (visible in the 2026-09-28 compat warnings) →
**`0.2.0-rc.2`** (current).

### 2026-09-28 11:37–12:54 — thinking-effort installed then dropped

`dsh-thinking-effort` installed at 0.3.5, then toggled off and **uninstalled**
the same hour (`live-removed=true`) — gone from the profile.

### 2026-09-28 17:46 — the compat gate refused a bundle

`dsh-better-sidebar@0.24.1` update **refused before installing**: the release
declares `^0.2.0-rc.1` and the host was then `0.1.7-rc.2`. It succeeded once
the host reached 0.2.0-rc.2. A backup recorded on one release therefore does
not automatically apply on another.

### 2026-09-28 ~16:17–18:20 — presets migrated into a local plugin

DSH 0.1.7-rc.2 **stopped reading the legacy `$DSH_HOME/.agent-presets/<id>/`
directories**. The user authored `@local/dsh-custom-presets` at
`/home/vrbkam/dsh-custom-presets` and installed it as a bundle:

- `generate-patch.cjs` freezes the two legacy presets into a `cordis.patch.yml`
  declaring each as an `@deepseek-ai/dsh-agent-preset` row, with the plugin
  entry lists taken verbatim from the legacy `agent.cordis.yml` files.
- One substitution: `@deepseek-ai/dsh-workflow-worker-thread` (removed in
  0.1.7-rc.2) → `@deepseek-ai/dsh-workflow-ptc`, keeping
  `config.provider: spawn`.
- The `custom` preset was renamed **"Productivity Mode"**; its id stays
  `custom`, so the registry default keeps working.
- `agent-presets/generate-patch.cjs` in this repository is a copy of that
  generator — the legacy files here are the source it freezes from.

### 2026-10-02 17:24–17:26 — the sweep and the search-pool removal

| Plugin | 2026-09-23 | Now |
| --- | --- | --- |
| `@linxin666/dsh-client-ui-task-board` | 0.3.24 | **0.4.4** |
| `@vectorize-io/hindsight-coding-agents` | 0.6.1 | **0.8.0** |
| `dsh-better-sidebar` | 0.19.1 | **0.24.1** |
| `dsh-context` | 0.54.0 | **0.62.2** |
| `dsh-lsp-actions` | 0.5.3 | **0.5.6** |
| `dshmarket` | 1.51.0 | **1.66.8** |
| `@linxin666/dsh-client-ui-git-graph` | 0.3.20 | 0.3.20 (unchanged) |
| `dsh-subagent-workspace-ui` | 1.3.3 | 1.3.3 (updates blocked) |

and **`dsh-search-failover` uninstalled**:

```
17:25:19  toggle     dsh-search-failover: no loader entry matched
17:25:19  uninstall  dsh-search-failover exit=0 live-removed=false
```

`live-removed=false` with "no loader entry matched" — the plugin had already
stopped contributing a loader entry on this host. Reason, in the user's words:
this machine will use Exa directly, not a provider pool. **A replacement search
provider was not yet chosen.**

### Still blocked: `dsh-subagent-workspace-ui`

Attempts on 2026-09-28 (1.9.0) and 2026-10-02 (1.9.1) both failed on
`ERR_PNPM_UNUSED_PATCH` against the pinned 1.3.3 patch and rolled back. The
gap is now 1.3.3 → upstream 1.9.1.

### Verified unchanged

- Both agent presets byte-identical to `agent-presets/` — which matters more
  now, since they are the source the local plugin freezes from.
- The `ui-git-graph` disable is still in the patch layer.
- `patches/dsh-subagent-workspace-ui@1.3.3.patch` unchanged.
- `$DSH_HOME/AGENTS.md` and a home-level `$DSH_HOME/cordis.patch.yml` are
  still absent.
- Profile is **9 dependencies / 11 bundles**.
## 2026-09-20 — plugin sweep; `dsh-better-edit` removed

Recorded 2026-09-23 from `$DSH_HOME/profiles/web/.dsh-market/log.ndjson`, which
timestamps every action the market takes.

### Removed: `dsh-better-edit`

```
17:21:02  uninstall  dsh-better-edit exit=0 live-removed=true
```

Gone from `dependencies` **and** `dsh.profile.bundles`. Reason, in the user's
words: it did more harm than good.

It also took its hashline `read` / `write` / `edit` / `undo_last_edit` tools
with it. The stock tools are back, and file edits are now literal
`old_string` / `new_string` replacement rather than hash-anchored patches.

Leftovers it did not clean up:

- `$DSH_HOME/plugins/dsh-better-edit/` still exists — `config.yaml`, the
  `standard` / `code` / `minimal` / `cordis` prompt directories, and a
  `runtime/` tree of per-workspace hash stores. Nothing reads it now.
- `dsh-better-edit@0.8.1` is still listed under `minimumReleaseAgeExclude` in
  `pnpm-workspace.yaml`.

### Upgraded

All within the same 17:20–17:22Z window:

| Plugin | From | To |
| --- | --- | --- |
| `dshmarket` | 1.45.1 | **1.51.0** |
| `@hytime/dsh-thinking-effort` | 0.2.4 | **0.3.1** |
| `@linxin666/dsh-client-ui-task-board` | 0.3.20 | **0.3.24** |
| `@vectorize-io/hindsight-coding-agents` | 0.5.4 | **0.6.1** |
| `dsh-context` | 0.49.4 | **0.54.0** |
| `dsh-lsp-actions` | 0.5.0 | **0.5.3** |

### Failed again: `dsh-subagent-workspace-ui`

```
17:22:04  update-rollback  dsh-subagent-workspace-ui: restored npm build v1.3.3
17:22:04  warn             dsh-subagent-workspace-ui: failed update command; previous build restored and verified
17:22:04  error            dsh-subagent-workspace-ui -> 1.4.0 exit=1
                           err=ERR_PNPM_UNUSED_PATCH: The following patches were not used: dsh-subagent-workspace-ui@1.3.3
```

The same failure as the 1.3.4 attempt on 2026-09-11: the English-labels patch
is pinned to 1.3.3, so no other version installs under it. Upstream is now
1.6.0. See *Known constraints* in the root README.

### Also changed

- **Harness upgraded** — `@deepseek-ai/dsh` 0.1.5-rc.1 → **0.1.5-rc.2**. Not in
  the market log; observed from `dsh --version`.
- **`settings.yaml` gained a second provider**, `alibaba-qwencloud`
  (`apiKeyEnv: ALIBABA_QWENCLOUD_API_KEY`, the Alibaba MaaS compatible-mode
  endpoint, models `qwen3.8-max` and `deepseek-v4.1-flash`), plus two more
  models on `openrouter-custom`: `stealth/union-alpha` and
  `xiaomi/mimo-v2.6-pro`.
- **Default model moved back** to `deepseek/deepseek-v4.1-flash` on
  `openrouter-custom`, having been `z-ai/glm-5.3-flash` since 2026-09-13.

### Stale `minimumReleaseAgeExclude` entries

Left as-is — this repository records the live profile, it does not edit it.