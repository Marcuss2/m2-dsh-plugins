# dsh-market

## What it is

[`dshmarket`](https://github.com/dsh-market/dshmarket) (npm package
`dshmarket`, publisher dsh-market) adds the **Plugin Market** section to DSH
Settings: a searchable card UI over the plugin registry with one-click
install and upgrade of any `dsh.bundle` plugin, plus **Advanced → Backup &
Restore**, which exports and imports an entire profile as a single JSON file.

Live version here: **1.51.0**.

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

Recorded `createdAt 2026-09-23T11:30:58.815Z`; 5 files. It was produced with
`dshmarket`'s own `createProfileBackup('web')` — the same function behind the
GUI's *Export backup* button — so it is a faithful capture of the live profile.

Since the 2026-09-11 capture it has lost `dsh-better-edit` — **10 dependencies
and 12 bundles, down from 11 and 13** — gained `cordis.patch.yml`'s
`ui-git-graph` disable, and taken the 2026-09-20 version bumps. See the root
README's *Known constraints* and `CHANGELOG.md`.

The export covers the profile directory only, so it carries **no credentials
and no absolute paths**: `$DSH_HOME/settings.yaml` (model provider, API-key
environment variable, search backends) lives outside the profile and is not in
it. The copy here was checked to contain no home path and no username.

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
