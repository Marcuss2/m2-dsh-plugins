# AGENTS.md — Ground Rules

## Repository purpose

This repository is a **self-contained reproduction kit** for this DeepSeek
Harness setup. It must contain *all* information needed so that any reasonable
LLM, starting from a baseline DSH install, can reconstruct the same setup from
this repository alone — no access to the original machine required.

That means recording, for every customization in use:

- **What it is and why** — purpose and behavior of each plugin/preset/setting.
- **The full definition** — complete plugin source, composition rows, preset
  files, or configuration snippets (never just names or pointers to files
  outside this repo).
- **How to install it** — step-by-step instructions an LLM can follow on a
  fresh install (where things go, activation/approval steps, rebuilds).
- **Dependencies and order** — what depends on what, and the sequence in which
  pieces must be applied.
- **Ground rules** — behavioral rules (below) that belong to the setup itself
  and must be re-established on the target machine.

Keep everything here accurate and complete whenever the setup changes: an
out-of-date entry defeats the repo's purpose. Prefer durable artifacts (files,
compositions, presets) over session-only state; where something is inherently
session-scoped (e.g. a dynamic Cordis plugin), record its full source and the
steps to re-define it.

## Ground rules

These rules apply to every task in this workspace.

### 1. Reuse before reinvention
Before suggesting to create a new plugin, search for existing ones first. If the
desired functionality already exists — as a shipped DSH plugin, an existing Cordis
composition row, an agent preset, a skill, or an already-registered dynamic plugin —
reuse or extend it instead of building a duplicate. Only propose a new plugin when no
existing capability covers the need, and say what was checked.

### 2. Profile-installed code must not duplicate the harness

The web profile installs bundles with pnpm's `nodeLinker: hoisted`, so anything a
plugin declares as a *regular* dependency lands inside
`$DSH_HOME/profiles/web/node_modules/`. A plugin that declares `@deepseek-ai/*`
core packages that way shadows the installation with a second copy of the
runtime, and core singletons — the tool-runtime scheduler symbol above all —
stop matching across the two copies. The blast radius is **every tool call in
every session**, not one misbehaving plugin. Therefore:

- Before installing any plugin, compare its `dependencies` with its
  `peerDependencies` for `@deepseek-ai/*`. Packages that use peers (like
  `dsh-better-edit`) are fine; one that hard-depends on core modules is not,
  unless proven otherwise.
- After any add or remove, run `setup/verify.sh` — section 4 is exactly this
  check, and it is the first thing to consult when tools start returning nothing.

### 3. One install at a time, then verify

Batch all profile bundles into a single `dsh plugin --profile web add …` command
and keep the profile quiescent while it runs. Concurrent `pnpm add` processes in
one project both exit 0 while the last writer wins, silently dropping the other's
dependency *and* its bundle entry — so parallel installs are neither faster nor
correct. Afterwards run `setup/verify.sh` (`--record` refreshes
`setup/versions.txt`; `--full` also probes the MCP servers over stdio).

**Every plugin add (or removal) also refreshes the canonical profile-state
record:** re-export via Settings → Plugin Market → Advanced → Backup & Restore
→ Export backup, strip per `plugins/dshmarket/README.md`, and replace
`profile-backup.stripped.json` in the same task as the install and the
verification.
