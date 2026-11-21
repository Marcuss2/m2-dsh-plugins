# dsh-market

## What it is

[`dshmarket`](https://github.com/dsh-market/dshmarket) (npm package
`dshmarket`, publisher dsh-market) adds the **Plugin Market** section to DSH
Settings: a searchable card UI over the plugin registry with one-click
install and upgrade of any `dsh.bundle` plugin, plus **Advanced → Backup &
Restore**, which exports and imports an entire profile as a single JSON file.

Live version here: **1.70.2**.

## Install

```sh
dsh plugin --profile web add dshmarket
```

Then restart `dsh --profile web` — bundle layers compose at boot, so nothing
changes in an already-running session.

Keep the profile quiescent while this runs: two concurrent `pnpm add`
processes in one project both exit 0 while the last writer wins, silently
dropping the other's dependency *and* its bundle entry.

The command adds `dshmarket` to both `dependencies` and `dsh.profile.bundles`
in `$DSH_HOME/profiles/web/package.json`. The bundle registration is what
applies the package's own `cordis.patch.yml`:

```yaml
- insert:
    - id: dsh-market
      name: 'dshmarket'
```

### Desktop client caveat

On **DeepSeek Harness Desktop ≥ 0.3.8**, install it as a **dependency only**
and keep it out of `dsh.profile.bundles`. That launcher always applies its own
overlay — `dsh --profile web --patch <AppImage>/config/plugin-market.patch.yml`
— whose content is the same `id: dsh-market` insert. A bundle layer would
contribute a second one and Cordis aborts the boot with:

```
duplicate loader entry id: dsh-market
```

The plain CLI (`dsh --profile web`, what this machine runs) applies no such
overlay, so a bundle registration is correct there — and is what the recorded
backup contains.

## profile-backup.json

The canonical record of the `web` profile, in `dshmarket`'s own Backup &
Restore format (`dsh-profile-backup`, version 0.2). It holds:

- `package.json` — the `dependencies` map and the ordered `dsh.profile.bundles` list
- `cordis.yml`, `cordis.patch.yml`, `pnpm-workspace.yaml` — the profile's own config
- `patches/` — each registered pnpm patch, verbatim

Recorded `createdAt 2026-11-21T10:05:52.567Z`; 6 files. It was produced with
`dshmarket`'s own `createProfileBackup('web')` — the same function behind the
GUI's *Export backup* button — so it is a faithful capture of the live profile.
The export shape shrank since the 2026-10-19 capture (101 files): 1.70.2
carries only the profile's config files — `compatibility.json`, `cordis.yml`,
`cordis.patch.yml`, `package.json`, `pnpm-workspace.yaml`, and
`patches/*.patch` — and no longer mirrors `.plugin-manager` operation logs or
`pnpm-lock.yaml`. The path-strip applies to the whole file either way.

**22 dependencies and 23 bundles**, back to the 2026-11-15 counts after the
2026-11-21 removals (see below), and up from 16 and 18 on 2026-10-19. The
2026-11-11 re-export recorded
`dsh-agent-team-model-selection` 0.7.0 (a
commit-pinned GitHub bundle) plus the drift accumulated since October: added
`@idealclover/dsh-session-title-studio` 0.8.1, `dsh-mcp-connector` (`link:`),
`dsh-tool-ast-grep` 0.1.2, and the `dsh-workboard` / `dsh-workboard-gitlab` /
`dsh-workboard-jira` `link:` bundles; removed the uninstalled
`dsh-secret-guard`.

The 2026-11-15 re-export adds the post-0.2.2-rc.1 state: the
`@vectorize-io/hindsight-coding-agents` **bundle left `dsh.profile.bundles`**
while the package stays a dependency, so its memory tools are no longer
mounted; and four pins moved (`dsh-context` 0.75.1→0.84.1, `dsh-free-search`
0.9.15→0.9.51, `dsh-lsp-actions` 0.5.17→0.5.21,
`@michengai/dsh-skills-manager` 1.2.18→1.4.9).

The 2026-11-18 re-export records the post-Mistral-Vibe state: added the
`@khuraie/dsh-mistral-vibe-provider` dependency (`github:`, unpinned; 0.1.29
installed) and the host-shipped `@deepseek-ai/dsh-experimental-forge-bundle`
bundle entry. Everything else — every other dependency spec, the bundle order,
the pnpm patch — is unchanged from 2026-11-15. The patch layer's
`agent-default-model` row moved to `mistral-vibe` /
`deepseek-v4-1-flash-1017`, and the two route allowlists carry its models;
the export carries those rows.

The 2026-11-21 re-export records the post-0.2.2-rc.5 state:
`dsh-agent-team-model-selection` was uninstalled because its
`ctx.agentTeams.tryMembership` call broke every new and restored session, and
its patch row was deleted. The host-shipped
`@deepseek-ai/dsh-experimental-agent-team-profile` bundle is also absent: it
was already gone from the live manifest before the uninstall and is no longer
shipped by rc.5, so this export corrects the stale 2026-11-18 record. Every
other dependency spec and bundle order is unchanged. The patch layer now
ends with a comment recording the removal instead of the old Team route
allowlist, and starts with a YAML language-server modeline pointing at the
recorded `patch.json` schema so editors stop matching this Cordis patch list
to the JSON Patch schema. The modeline is a comment; the loader and
`dsh --dump-config` ignore it.

The export covers the profile directory only, so it carries **no credentials
and no absolute paths**. The model-provider rows now live in the profile's
`cordis.patch.yml` and are included — but they reference keys by
environment-variable name (`apiKeyEnv`), never the key value; the credential
store (`$DSH_HOME/.credentials.yaml`) is outside the profile and is not in it.
The copy here was checked to contain no home path and no username.

### Recording a fresh export

Either through the GUI — Settings → Plugin Market → Advanced → Backup &
Restore → **Export backup**, which downloads
`dsh-dshmarket-backup-<timestamp>.json` — or from Node:

```sh
node -e "const{createProfileBackup}=require('$DSH_HOME/profiles/web/node_modules/dshmarket/lib/backup.js');
  process.stdout.write(JSON.stringify(createProfileBackup('web'),null,2))" > /tmp/backup.json
```

Then strip it and replace the recorded copy:

```sh
sed 's|/home/[^/]*/\.dsh/profiles/web|__PROFILE__|g; s|/home/[^/]*|$HOME|g' \
  /tmp/backup.json > dsh-market/profile-backup.json
grep -E "$(whoami)|/home/" dsh-market/profile-backup.json   # must print nothing
```

The strip step is a no-op on the current record (it contains no absolute
paths), but keep it so the rule holds if the profile ever grows a
path-bearing config file. Never commit the raw download: the export is
one-to-one, so it carries whatever secrets the profile holds.

### Restore

With the profile quiescent:

1. Re-point the placeholders, if the strip step introduced any:

   ```sh
   sed 's|__PROFILE__|'"$DSH_HOME"'/profiles/web|g; s|$HOME|'"$HOME"'|g' \
     dsh-market/profile-backup.json > /tmp/restore.json
   ```

   (The current record has none, so this copies it unchanged.)

2. Settings → Plugin Market → Advanced → Backup & Restore →
   **Import and preview** → pick `/tmp/restore.json` → confirm the restore.

3. Restart `dsh --profile web`.

A restore **merges** into the target's `package.json` rather than overwriting
it: dependencies the machine already has are kept, the backup's spec wins on a
name conflict, and the two bundle lists are unioned. It therefore does not
delete plugins a target machine has but this profile does not.
