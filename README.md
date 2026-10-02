# DeepSeek Harness setup

A plain record of the DeepSeek Harness (DSH) setup on this machine: how
`dsh-market` is installed, the canonical profile backup, the agent presets in
use, and the prompts they carry.

This repository is **not** a reproduction kit and contains no plugin source.
Plugins are installed directly into the `web` profile; `dsh-market`'s own
Backup & Restore export in `dsh-market/` is the record of which ones, and at
which versions.

## Current setup

| | |
| --- | --- |
| Harness | `@deepseek-ai/dsh` **0.2.0-rc.2** (global npm install) |
| Launch | `dsh --profile web` — Web GUI, `DSH_HOME=~/.dsh` |
| Profile | `web` — **10 dependencies, 12 ordered bundles** |
| Default agent preset | `custom` — **Productivity Mode** |
| Default model | `z-ai/glm-5.3-flash` on provider `openrouter-custom` |
| Web search | `dsh-free-search` 0.6.5, engine **`exa`**, keyless |
| Plugin market | `dshmarket` **1.66.8** |

Last recorded **2026-10-02**. What changed, and when, is in `CHANGELOG.md`.

## Where settings live now

As of DSH 0.1.7-rc.2 the old `$DSH_HOME/settings.yaml` is **no longer read**:
the harness renamed it `settings.yaml.imported` and its keys are now expressed
as **patch rows in `$DSH_HOME/profiles/web/cordis.patch.yml`** —
`agent-default-model`, `agent-preset-registry`, `locale`, `llm-pi-ai`,
`better-sidebar`. The imported file still holds the old document verbatim,
including the `search-pool` block that belonged to the removed
`dsh-search-failover` — dead config now.

So the profile's patch layer is the settings file, and it also carries
configuration for individual plugins — including the Exa engine override on
the `web-search-free` row. See `dsh-market/README.md` for the backup that
records it.

## Machine tooling

Software outside the profile that the installed plugins depend on, or that
makes them worth having. Install these **before** restoring the profile — a
plugin whose backing binaries are missing mounts fine and then does nothing.

| Tool | Version | Backs | Why it matters here |
| --- | --- | --- | --- |
| `@deepseek-ai/dsh` | 0.2.0-rc.2 | everything | the harness itself |
| `dshmarket` (profile dep) | 1.66.8 | Settings → Plugin Market | browse/install/upgrade + Backup & Restore |
| `typescript-language-server` | 6.0.0 | `dsh-lsp-actions` | the `lsp_*` tools for TypeScript/JavaScript |
| `pyright` (+ `pyright-langserver`) | 1.1.412 | `dsh-lsp-actions` | the `lsp_*` tools for Python |
| `rust-analyzer` | system | `dsh-lsp-actions` | already present |
| `clangd` | system | `dsh-lsp-actions` | already present |

```sh
# Language-server backends — both ship as global npm packages, one install path
npm install -g typescript-language-server pyright
# typescript-language-server also needs TypeScript itself resolvable:
npm install -g typescript

# Verify — each must answer with a version, and the pyright wrapper must
# expose the language server binary alongside the CLI:
typescript-language-server --version    # 6.0.0
pyright --version                       # pyright 1.1.412
command -v typescript-language-server pyright pyright-langserver tsserver
```

Both went in with **no restart**: the harness's `lsp_*` tools discover
backends on PATH per call, so they pick the servers up in the next session
rather than on the next boot.

Still missing, deliberately recorded: **no DAP debug adapter** (`debugpy`,
`dlv`, `codelldb`, `netcoredbg` are all absent), so the debugger surface has
nothing to attach to; and no `gopls`, `jdtls`, `bash-language-server` or
`yaml-language-server`. Add one only when a project actually needs it — each
is a single package install with no plugin change.

## Contents

| Path | What it records |
| --- | --- |
| `dsh-market/README.md` | How `dshmarket` is installed, and why it is registered the way it is |
| `dsh-market/profile-backup.json` | Canonical record of the `web` profile — dependencies, bundle order, profile config files and pnpm patches — with private data stripped |
| `agent-presets/` | The two presets in use, verbatim, plus the generator that freezes them into the live plugin |
| `prompts/` | The prompt text those presets carry — personas and plan mode |
| `CHANGELOG.md` | Dated record of what changed in the live setup |
| `.research/*.md` | Older research notes, kept for reference only; not part of the setup |

## Known constraints

Recorded because they are non-obvious and would otherwise be rediscovered:

- **`ui-git-graph` is disabled** in the profile's patch layer. The plugin
  stays installed and listed in `dsh.profile.bundles`; only its loader row is
  off. Reason, recorded in the file itself: it polls every 30 s — several git
  spawns per tick, even for non-git workspaces, each through a `systemd-run`
  scope — a `git status` round can stall up to `STATUS_TIMEOUT_MS` (15 s), and
  its auto-isolation hook is already dead under the current
  workspaces-service shape. Re-enable by deleting the entry.
- **`dsh-subagent-workspace-ui` cannot be upgraded past 1.3.3** as-is. The
  profile carries a hand-derived English-labels patch pinned to 1.3.3, so any
  other version fails with `ERR_PNPM_UNUSED_PATCH` and rolls back. That has
  now happened on 1.3.4, 1.4.0, 1.9.0 and 1.9.1; upstream is 1.9.1. Upgrading
  means re-deriving the patch from the new `lib/client.js` first.
- **`dsh-better-edit` is uninstalled, but its state directory remains.**
  `$DSH_HOME/plugins/dsh-better-edit/` still holds `config.yaml`, the
  `standard`/`code`/`minimal`/`cordis` prompt directories and a `runtime/`
  tree of per-workspace hash stores. Nothing reads it now. One visible
  consequence of its removal: file edits use the stock literal
  `old_string`/`new_string` replacement rather than its hash-anchored
  patching.
- **Search runs keyless on Exa's anonymous quota.** `dsh-free-search`'s `exa`
  engine falls back to `mcp.exa.ai/mcp` without a key and switches to REST
  `api.exa.ai/search` once one appears. The user's Exa key is not wired — it
  still sits in the dead `search-pool` block of `settings.yaml.imported`. Add
  it under Settings → Plugins → Free Search to lift the anonymous rate limit.
- **Stale `minimumReleaseAgeExclude` entries remain** in
  `pnpm-workspace.yaml`, naming packages that are no longer installed
  (`dsh-better-edit@0.8.1`). Left in place deliberately: this repository
  records the live profile, it does not edit it.

## Rebuilding from here

On a fresh DSH install:

1. Install `dshmarket` — see `dsh-market/README.md`.
2. Restore the profile through Settings → Plugin Market → Advanced →
   Backup & Restore, importing `dsh-market/profile-backup.json`.
3. Install the presets — see `agent-presets/README.md`; they arrive as the
   `@local/dsh-custom-presets` bundle, generated from the legacy sources here.
4. Restart `dsh --profile web`; bundle layers compose at boot.

Note that a backup recorded on one DSH release does not automatically apply
to another: the market's compat gate refuses a bundle whose declared core
range excludes the running host. That gate is doing its job, not failing.

## Keeping it current

When the live setup changes, update the affected directory **and add a dated
entry to `CHANGELOG.md`** in the same task:

- **Profile change** — a plugin added, upgraded, removed, or a patch-layer row
  toggled → re-export the backup and re-strip it (`dsh-market/README.md` →
  *Recording a fresh export*).
- **Preset change** → edit the legacy source, re-run the generator, re-copy
  `agent-presets/` and refresh `prompts/`.
- **Settings change** → these are patch rows now; the backup records them, so
  re-export and correct the table above.
