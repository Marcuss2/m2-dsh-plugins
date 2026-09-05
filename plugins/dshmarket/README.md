# dshmarket

## What it is

The community **plugin market inside DSH Settings** — a searchable card UI
over the Awesome DSH Plugin list (see `.research/awesome-dsh-plugin.md`), with
one-click install/upgrade of any `dsh.bundle` plugin, a Themes tab, and a
**Backup & Restore** surface that has become this kit's canonical way to
capture and replay the whole profile state. npm package `dshmarket`
(publisher dsh-market, github.com/dsh-market/dshmarket). **1.41.0 installed
2026-09-04 as a dependency-only profile entry** (see Install).

Installed as a **profile dependency, deliberately NOT a `dsh.profile.bundles`
bundle** since DeepSeek Harness desktop 0.3.8. Its shipped `cordis.patch.yml`
still exists and inserts one row on whatever layer stack applies it:

```yaml
- insert:
    - id: dsh-market
      name: 'dshmarket'
```

**Why not a bundle (desktop ≥0.3.8):** the desktop launcher hard-codes
`dsh --profile web --patch <AppImage>/config/plugin-market.patch.yml`, whose
content is exactly `- insert: - id: dsh-market, name: dshmarket` — the 0.3.8
AppImage ships its own `dshmarket@1.40.0` (a dependency of its bundled
`@deepseek-ai/dsh`, symlinked into `$DSH_HOME/profiles/node_modules/` by the
boot's module-fallback heal). The profile's baseUrl resolves that overlay row
against `$DSH_HOME/profiles/web/node_modules/` FIRST, so a profile-installed
`dshmarket` satisfies it (and 1.41.0 wins over the bundled 1.40.0). But bundle
registration would apply the package's own `cordis.patch.yml` too — a second
insert of `id: dsh-market` — and Cordis throws `duplicate loader entry id:
dsh-market`, killing every boot (CLI `dsh` and desktop alike). On desktop
≤0.3.6, which shipped no market, the bundle registration was required; the
`Remove` section covers rolling back if an older desktop returns.

The package declares a **client half** (`dsh.client.platform: web`) that
injects `@deepseek-ai/dsh-client-connection`, `-client-runtime`,
`-client-locale`, `-client-ui-settings` and `-client-ui-theme` — i.e. it
registers UI into the Web GUI's Settings page, no server-side behavior.

## Why this plugin (checked per ground rule 1)

Optional but **installed first**, ahead of every other custom bundle, so the
rest of the pack can be browsed, installed and upgraded from the GUI instead of
the shell. Nothing depends on it and it depends on nothing: a CLI-only restore
works identically without it.

Recorded because it **was present on the source machine's
`dsh.profile.bundles` list** (it appears in the snippet in
`../tier1-plugins/README.md`) yet had no kit entry, so a restore driven by this
repo silently diverged from the machine it describes. Checked per ground rule 1:
no shipped DSH plugin offers a plugin browser, and no other entry here does.

## Dependencies

- `nodejs-npm` (baseline; see `../../DEPENDENCIES.md`). No extra machine
  software, no `uv`, no server.
- Needs a DSH web profile with the `@deepseek-ai/dsh-web-app` bundle (stock).

## Profile backup — the kit standard

The market's **Backup & Restore** (Settings → Plugin Market → Advanced →
Backup & Restore) exports the whole `web` profile as a single readable JSON
(`format: dsh-profile-backup`, version 0.2): every profile config file
verbatim (`cordis.patch.yml`, `cordis.yml`, `pnpm-workspace.yaml`), the parsed
`package.json` manifest — dependencies and `dsh.profile.bundles` included — and,
since the 18:01 export on 2026-09-04, even `patches/` files
(a restore re-materializes registered pnpm patches with no manual copy; the
2026-09-05 record carries only the subagent-monitor patch — the ptc-plus one
retired with its plugin). Since 2026-09-04 this export is the kit's
canonical record of the live profile state:

- **Canonical artifact:** [`../../profile-backup.stripped.json`](../../profile-backup.stripped.json)
  — rebuilt 2026-09-05 from the live profile after the better-dsh swap (the
  previous record was the 2026-09-04T18:01:36Z export); private data stripped
  per the rules below. NOTE: rebuilt by direct file capture, not through the
  GUI Export backup — re-export via Backup & Restore when convenient.
- Raw exports are named `dsh-dshmarket-backup-<timestamp>.json` by the
  browser download and are **gitignored**: they carry absolute home paths and
  whatever secrets the profile holds. Keep them local; commit only the
  stripped form.

**Stripping rules** (applied when recording an export into the kit):

1. Replace every occurrence of the machine user's profile root
   `/home/<user>/.dsh/profiles/web` with the tier1 convention placeholder
   `__PROFILE__` (the same token `plugins/tier1-plugins/cordis.patch.yml.example`
   uses), so the rows stay materializable against any `$DSH_HOME`.
2. Replace any remaining `/home/<user>` with `$HOME`.
3. Drop duplicated template header blocks if the live patch file accumulated
   them (the 18:00 export carried the dsh template banner twice).
4. Verify: `grep -E "$(whoami)|/home/" <stripped file>` must return nothing
   (the current machine's username is the thing to hunt), and the result must
   still parse as valid backup JSON (`files[]` with `path` + `lines`,
   `package.json` as `json`).

Note the market itself never masks values — exports are one-to-one for
faithful restores (its own UI warns about this). Stripping is a *kit*
operation performed on the copy that gets committed; the restore flow below
re-materializes the placeholders back to real paths.

**Restore from the stripped backup** (on a fresh or drifted machine, profile
quiescent per ground rule 3):

1. Re-point the placeholders:

   ```sh
   sed "s|__PROFILE__|$DSH_HOME/profiles/web|g;s|\$HOME|$HOME|g" \
     "$KIT/profile-backup.stripped.json" > /tmp/restore.json
   ```

2. In the GUI: Settings → Plugin Market → Advanced → Backup & Restore →
   **Import and preview** (Local file card) → pick `/tmp/restore.json`. The
   Installed tab then shows a “Start restore” banner; confirm it.
The export records `patchedDependencies` in `pnpm-workspace.yaml` and
carries every registered patch as a `files[]` entry, so the restore
re-applies them with no manual copy (current record:
`patches/@leetoners__dsh-ui-subagent-monitor@0.2.0.patch`; the retired
`dsh-ptc-plus` patch is documented in `../dsh-ptc-plus/README.md`).

3. What the restore does (verified against dshmarket 1.41.0 source, worth
   knowing before clicking):
   - writes every backup file over the profile's current one, then **merges**
     manifests (target deps kept, backup specs win; bundle lists unioned) and
     runs `dsh plugin --profile web install`;
   - the merge **unions** bundles, so restoring onto a profile where
     `dshmarket` was wrongly registered as a bundle cannot undo that mistake —
     remove it by hand first (see Remove);
   - the desktop's `--patch` overlay insert of `id: dsh-market` is NOT part of
     the profile files, so a restored plain CLI boot has no market row until
     the desktop launches it (or you add the row yourself — see Activation).

4. Restart `dsh --profile web` and run `setup/verify.sh`.

## Install

On a machine whose profile already matches the canonical backup, step 3 of
*Profile backup* above installs everything at once. For a manual or
partial install: `dsh plugin add` always registers a bundle, so the
dependency-only state must be produced by hand (profile quiescent, per ground
rule 3):

1. Add the dependency to `$DSH_HOME/profiles/web/package.json` (exactly the
   `dependencies.dshmarket` spec recorded in
   [`../../profile-backup.stripped.json`](../../profile-backup.stripped.json)):

   ```json
   "dependencies": { "dshmarket": "1.41.0" }
   ```

2. Install it:

   ```sh
   cd "$DSH_HOME/profiles/web" && pnpm install --no-frozen-lockfile
   ```

3. Confirm `dsh.profile.bundles` does **not** list `dshmarket` — that is the
   state `setup/verify.sh` enforces (FAIL when listed, because a bundle layer
   double-inserts `id: dsh-market` and kills the desktop boot. The canonical
   backup is itself the reference for this state: its manifest lists
   `dshmarket` under `dependencies` but not under `dsh.profile.bundles`.

## Activation

The row is mounted by the desktop launcher's own `--patch` overlay, so it
activates whenever the desktop app boots the profile — no restart semantics of
its own beyond the usual "layers compose at boot". A CLI-only boot
(`dsh --profile web` without `--patch`) simply runs without the market row.

## Verify

1. `setup/verify.sh` checks the dependency-only state (dep present, NOT in
   `dsh.profile.bundles`, installed in node_modules) against the same truth
   recorded in `profile-backup.stripped.json`. The composed `dsh-market` row
   is intentionally NOT checked via `dsh --profile web --dump-config`: without
   the desktop's `--patch` overlay the row is absent by design.
2. End-to-end: launch the desktop AppImage; the profile boot must reach
   `dsh web: http://127.0.0.1:<port>`. (2026-09-04, after the 0.3.8 fix: the
   full desktop launched and the same overlay boot was verified headlessly via
   the AppImage's `plugin-market.patch.yml` — HTTP 200 on the printed URL.)
3. In the Web GUI: **Settings → Plugin Market** (client half). Verified on
   2026-08-28 by driving the running GUI with the `agent-browser` skill: the
   panel renders a "Plugin Market" heading, an **Update market** button, and
**Discover / Themes / Favorites / Installed / Advanced / Tasks** tabs;
Advanced carries **Backup & Restore** and **Diagnostics**. `dsh-search-failover`
contributes its own **Search Pool** settings tab alongside it.

### Installing other plugins through the market

The Discover tab's one-click install runs the same pnpm operation as
`dsh plugin add` and writes the same `$DSH_HOME/profiles/web/package.json`, so
per AGENTS.md rule 3 it must not be used while a CLI install is in flight — pick
one path at a time, then restart and run `setup/verify.sh`. It also cannot
approve pnpm build scripts, so npm MCP servers with postinstall binaries still
need the `allowBuilds` step from the tier1 entry.

An agent can drive it (the GUI is a normal page — `agent-browser` reached
Settings and the market panel in three calls), but for scripted restores the CLI
remains the deterministic route: the market needs a restart to appear at all,
and the CLI path does not.

### Keeping the canonical backup current

**Every added (or removed) plugin triggers this**, as do any other profile
changes that should persist across machines (a patch-layer row, an
`overrides` pin): re-export via
**Advanced → Backup & Restore → Export backup**, strip per the rules above,
and replace `profile-backup.stripped.json` in the same task (Maintenance
contract). `setup/verify.sh --record` still refreshes `versions.txt`; the
backup is the full-state complement to that version list.

## Remove

```sh
cd "$DSH_HOME/profiles/web" && pnpm remove dshmarket
```

(or delete the dependency from the profile's `package.json` and rerun
`pnpm install`). There is no bundle entry to remove in the desktop ≥0.3.8
state — if one exists, remove it too: a leftover `dshmarket` bundle layer
re-introduces the duplicate `dsh-market` insert and the desktop boot dies.

## Rollback to desktop ≤0.3.6 (bundle state)

Older desktops ship no market of their own, so there the package MUST be
registered as a bundle again: `dsh plugin --profile web add dshmarket`
(registers dependency + bundle) and restart. Returning to a 0.3.8+ desktop
later requires reverting to the dependency-only state above, or every boot
fails with `duplicate loader entry id: dsh-market`.
