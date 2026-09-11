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
| Harness | `@deepseek-ai/dsh` **0.1.5-rc.1** (global npm install) |
| Launch | `dsh --profile web` — Web GUI, `DSH_HOME=~/.dsh` |
| Profile | `web` |
| Default agent preset | `custom` (`$DSH_HOME/settings.yaml` → `agent-presets.default`) |
| Plugin market | `dshmarket` **1.45.1** |

## Contents

| Path | What it records |
| --- | --- |
| `dsh-market/README.md` | How `dshmarket` is installed, and why it is registered the way it is |
| `dsh-market/profile-backup.json` | Canonical record of the `web` profile — dependencies, bundle order, profile config files and pnpm patches — with private data stripped |
| `agent-presets/` | The two agent presets in use (`custom`, `coding`), verbatim |
| `prompts/` | The prompt text those presets carry — personas and plan mode |
| `.research/*.md` | Older research notes, kept for reference only; not part of the setup |

## Rebuilding from here

On a fresh DSH install:

1. Install `dshmarket` — see `dsh-market/README.md`.
2. Restore the profile through Settings → Plugin Market → Advanced →
   Backup & Restore, importing `dsh-market/profile-backup.json`.
3. Install the agent presets — see `agent-presets/README.md`.
4. Restart `dsh --profile web`; bundle layers compose at boot.

Deliberately **not** recorded here, because it is machine- or user-specific
rather than part of the profile: `$DSH_HOME/settings.yaml` (model provider,
API-key environment variable, search backends), `$DSH_HOME/.credentials.yaml`,
and session history.

## Keeping it current

When the live setup changes, update the affected directory in the same task:

- **Profile change** (plugin added, upgraded or removed) → re-export the
  backup and re-strip it — `dsh-market/README.md` → *Recording a fresh export*.
- **Preset change** → re-copy `agent-presets/` and refresh `prompts/`.
