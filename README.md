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
| Harness | `@deepseek-ai/dsh` **0.1.5-rc.2** (global npm install) |
| Launch | `dsh --profile web` — Web GUI, `DSH_HOME=~/.dsh` |
| Profile | `web` — **10 dependencies, 12 ordered bundles** |
| Default agent preset | `custom` (`$DSH_HOME/settings.yaml` → `agent-presets.default`) |
| Default model | `deepseek/deepseek-v4.1-flash` on provider `openrouter-custom` |
| Plugin market | `dshmarket` **1.51.0** |

Last recorded **2026-09-23**. What changed, and when, is in `CHANGELOG.md`.

## Contents

| Path | What it records |
| --- | --- |
| `dsh-market/README.md` | How `dshmarket` is installed, and why it is registered the way it is |
| `dsh-market/profile-backup.json` | Canonical record of the `web` profile — dependencies, bundle order, profile config files and pnpm patches — with private data stripped |
| `agent-presets/` | The two agent presets in use (`custom`, `coding`), verbatim |
| `prompts/` | The prompt text those presets carry — personas and plan mode |
| `CHANGELOG.md` | Dated record of what changed in the live setup |
| `.research/*.md` | Older research notes, kept for reference only; not part of the setup |

## Known constraints

Recorded because they are non-obvious and would otherwise be rediscovered:

- **`ui-git-graph` is disabled** in the profile's patch layer
  (`$DSH_HOME/profiles/web/cordis.patch.yml`). The plugin stays installed and
  listed in `dsh.profile.bundles`; only its loader row is off. Reason, recorded
  in the file itself: it polls every 30 s — several git spawns per tick, even
  for non-git workspaces, each through a `systemd-run` scope — a `git status`
  round can stall up to `STATUS_TIMEOUT_MS` (15 s), and its auto-isolation hook
  is already dead under the current workspaces-service shape, so it added poll
  churn without its main feature. Re-enable by deleting the entry.
- **`dsh-subagent-workspace-ui` cannot be upgraded past 1.3.3** as-is. The
  profile carries a hand-derived English-labels patch pinned to
  `dsh-subagent-workspace-ui@1.3.3`, so requesting any other version fails with
  `ERR_PNPM_UNUSED_PATCH` and `dshmarket` rolls the update back. That has now
  happened twice — 1.3.4 on 2026-09-11, 1.4.0 on 2026-09-20. Upgrading means
  re-deriving the patch from the new `lib/client.js` first. Upstream is 1.6.0.
- **`dsh-better-edit` is uninstalled, but its state directory remains.**
  `$DSH_HOME/plugins/dsh-better-edit/` still holds `config.yaml`, the
  `standard`/`code`/`minimal`/`cordis` prompt directories and a `runtime/`
  tree of per-workspace hash stores. Nothing reads it now. The plugin was
  removed on 2026-09-20 because it did more harm than good; one visible
  consequence is that file edits use the stock literal
  `old_string`/`new_string` replacement rather than its hash-anchored patching.
- **Five of the ten profile plugins have newer npm releases** as of
  2026-09-23; none are installed. The sweep is in `CHANGELOG.md`.
- **Three `minimumReleaseAgeExclude` entries are stale** — they name versions
  that are no longer installed (`dsh-better-edit@0.8.1`,
  `@hytime/dsh-thinking-effort@0.2.4`, `@vectorize-io/hindsight-coding-agents@0.5.3 || 0.5.4`).
  Left in place deliberately: this repository records the live profile, it does
  not edit it.

## Rebuilding from here

On a fresh DSH install:

1. Install `dshmarket` — see `dsh-market/README.md`.
2. Restore the profile through Settings → Plugin Market → Advanced →
   Backup & Restore, importing `dsh-market/profile-backup.json`.
3. Install the agent presets — see `agent-presets/README.md`.
4. Restart `dsh --profile web`; bundle layers compose at boot.

`$DSH_HOME/settings.yaml` is **not** reproduced here: it carries API keys (the
search-pool backend key among them) and is machine-specific. The settings-
derived values in the table above are recorded as facts, not as a file to
restore.

## Keeping it current

When the live setup changes, update the affected directory **and add a dated
entry to `CHANGELOG.md`** in the same task:

- **Profile change** — a plugin added, upgraded, removed, or a patch-layer row
  toggled → re-export the backup and re-strip it (`dsh-market/README.md` →
  *Recording a fresh export*).
- **Preset change** → re-copy `agent-presets/` and refresh `prompts/`.
- **Settings change** → if it affects the table above (default preset, default
  model), correct it here; never copy the file.
