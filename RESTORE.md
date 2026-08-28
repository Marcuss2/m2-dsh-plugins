# RESTORE.md — Reconstructing this DeepSeek Harness setup

**Audience:** a reasonable LLM agent working on a **baseline DeepSeek Harness
(DSH) install** with this repository available somewhere on disk (call that
path `$KIT`). Follow the steps **in order**. Every entry referenced here is
self-contained in this repo — nothing outside it is required.

**Hard rule:** when asked to set up the harness from this repository, the
**first action is always installing machine-level dependencies**
(`DEPENDENCIES.md`, Step 2 below) — they vary system to system, and no kit
entry can be applied before they verify.

## Baseline assumptions

- A stock DSH install: Web GUI, shipped agent presets (including `cordis`),
  default sandbox/approval policies. Nothing else customized.
- `$DSH_HOME` defaults to `~/.dsh`. Instruction files (`AGENTS.md`) are
  discovered automatically: `$DSH_HOME/AGENTS.md` applies to every session
  (user-global scope); an `AGENTS.md` in the session workspace applies to that
  workspace. More specific scopes take precedence over broader ones.

## Order of application

| # | Entry | Kit location | Status |
|---|-------|--------------|--------|
| 1 | Machine dependencies | `DEPENDENCIES.md` | live |
| 2 | User-global system prompt | `setup/user-global-AGENTS.md` | live |
| 3 | dshmarket (plugin-market UI in Settings) | `plugins/dshmarket/` | live |
| 4 | agent-browser skill (browser automation) | `plugins/agent-browser-skill/` | live |
| 5 | dsh-better-edit (hashline editing) | `plugins/dsh-better-edit/` | live |
| 6 | hindsight-coding-agents (Hindsight memory) | `plugins/hindsight-coding-agents/` | live |
| 7 | tier1-plugins (debugger, LSP, checkpoints, fallbacks, web+AST) | `plugins/tier1-plugins/` | live |
| 8 | dsh-better-reasoning-effort (reasoning levels for custom providers) | `plugins/dsh-better-reasoning-effort/` | live |
| 9 | machine-wide PTC home patch (Code Mode on every profile) | `plugins/machine-wide-ptc/` | live |
| 10 | Settings excerpt | `setup/settings.yaml.excerpt` | advisory |

## Step 1 — Read the kit

Read `$KIT/AGENTS.md`. It defines the repository purpose and the ground rules
that govern work in it. When this repository *is* the session workspace, that
file loads automatically as workspace instructions — no install step needed
for it.

## Step 2 — Install machine dependencies

Work through `DEPENDENCIES.md` in full: detect each dependency, install what
is missing in the way the target system requires (this differs per system —
distro, package manager, privileges), and run each verification command.
Report results per dependency. **Nothing below this step proceeds until all
dependencies verify.**

## Step 3 — Install the user-global system prompt

Target: `$DSH_HOME/AGENTS.md` (normally `~/.dsh/AGENTS.md`).

1. If the target **does not exist** (typical baseline install): copy
   `setup/user-global-AGENTS.md` verbatim to the target.
2. If the target **exists**: it is user-edited living content. Merge instead of
   overwriting — preserve the user's edits, add any missing sections from the
   kit copy, and tell the user what you merged.
3. **Verify:** start a session in any workspace and confirm the global
   instructions appear in its context.

## Step 4 — Apply plugin entries

Two rules, then the entries.

**Install the npm bundles in one batched call, one at a time.** All nine custom
bundles are added by a single `dsh plugin --profile web add …` (see
`plugins/README.md`, "How the npm bundles get installed"), with the profile
quiescent — no other session running `dsh plugin` at the same time. Concurrent
`pnpm add` calls in one project both report success while the last writer wins,
so a dependency and its bundle entry can vanish silently. Parallel installs are
therefore never faster than batching, and not correct.

**Check dependency hygiene before trusting any plugin.** The profile installs
with pnpm's `nodeLinker: hoisted`, so a plugin that declares `@deepseek-ai/*`
core packages as *regular* dependencies (instead of `peerDependencies`, the way
`dsh-better-edit` does) hoists a second copy of the harness's own modules into
`$DSH_HOME/profiles/web/node_modules/@deepseek-ai/`. The profile then shadows the
installation and core singletons — the tool-runtime scheduler symbol most
importantly — stop matching, which breaks **every tool call in every session**
rather than just that plugin. `setup/verify.sh` section 4 fails the check, and
it is the first thing to look at when tools start returning nothing.

Then, for each entry in `plugins/` in the index order given in
`plugins/README.md`, follow that entry's own `README.md` (purpose, files,
install steps, verification). Machine-level dependencies are tracked centrally in
`DEPENDENCIES.md` and were installed in Step 2. Finish with `setup/verify.sh`
(`--full` to also probe the MCP servers over stdio), then restart
`dsh --profile web` — bundle layers compose at boot, so nothing is active in
running sessions until then.

## Step 5 — Machine-wide Code Mode (PTC) home patch

Target: `$DSH_HOME/cordis.patch.yml` — the home-level patch layer the launcher
applies to **every** profile, ranked above each profile's own layers. Follow
`plugins/machine-wide-ptc/`: copy its verbatim `cordis.patch.yml` artifact to
the target when absent, or merge into an existing file without disturbing the
user's rows. Nothing is installed (Code Mode ships inside stock `dsh`). The
Step 4 restart — or one of your own afterwards — activates it: `dsh
--profile web --dump-config` then shows the composed `tools` row at
`mode: code` with the home file named in its provenance header.

## Step 6 — Settings (advisory)

Review `setup/settings.yaml.excerpt` and compare against the target's
`$DSH_HOME/settings.yaml`. Apply only what makes sense on the target machine:
API-key environment variables and model availability differ per machine. Never
blindly overwrite an existing `settings.yaml`; merge key by key and confirm
with the user when in doubt.

## Verification checklist

- [ ] `setup/verify.sh` exits 0 (0 FAIL). It covers: every `DEPENDENCIES.md`
      row, the Hindsight server, each bundle in `dependencies` **and**
      `dsh.profile.bundles`, one composed layer per bundle, the four `mcp-*`
      rows, the no-shadowing guard, built MCP binaries, and the kit files
      applied. WARNs are judgement calls, not failures.
- [ ] `setup/verify.sh --full` also answers a raw JSON-RPC `initialize` from
      each MCP row (works without a session; keep stdin open after the
      handshake or stdio servers exit on EOF).
- [ ] Version drift is reviewed (`setup/versions.txt` vs live); refresh with
      `setup/verify.sh --record` and update the affected entry README in the
      same task.
- [ ] `$DSH_HOME/AGENTS.md` matches the kit copy (or was merged, with the
      user informed).
- [ ] In a NEW session after the restart: `read` prints `HASH│content`, the
      hindsight/debug/LSP/checkpoint tools are registered, and `mcp__*` tools
answer.
- [ ] In a NEW session after the home-patch restart: the model works through
      `run_code` (`tools.*()` bindings); a direct native tool call is refused
      as `UNKNOWN_TOOL` — by design, not a breakage.
- [ ] Settings reviewed; machine-specific values adapted.

## Maintenance contract

Whenever the live setup changes — a plugin, preset, setting, or ground rule is
added, changed, or removed — the corresponding kit entry must be updated **in
the same task**. An out-of-date kit defeats its purpose. Any entry that needs
machine-level software must also add a row and section to `DEPENDENCIES.md`
in the same task.
