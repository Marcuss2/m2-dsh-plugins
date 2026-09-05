# dsh-ui-subagent-monitor (@leetoners)

## What it is

**Subagent monitoring mounted on the sidebar**: npm package
`@leetoners/dsh-ui-subagent-monitor` (Mombrane/dsh-subagent-monitor, MIT,
**0.2.0 installed** on 2026-09-05; ★25, ~640 downloads). A Web client plugin
that adds a **Subagents entry at the bottom of the sidebar** (registers into
the shell's `sidebar.footer.action` seat) and a draggable/resizable card
panel pinned top-right (via the frame-wide `shell.overlay` list seat —
additive, click-through unless opted in). It shows every subagent of the
current session live: running (animated dot + stopwatch), done, failed,
interrupted, token-limit, rejected; one-shot vs continuable; tree indent for
grandchildren; "Open chat" jumps into the child conversation and a "← Main
session" button returns. Position/height persist; refresh-proof (composition
row re-mounts it); hidden at ≤768px viewports by default.

This is the user-requested pairing: an additional plugin whose surface is the
sidebar, dedicated to subagent monitoring.

## Why this plugin (checked per ground rule 1)

Sweep of the market index (3117 entries, 2026-09-05) for subagent monitors:
`dsh-subagent-watchdog`, `dsh-session-monitor`, `dsh-side-monitor` (system
stats, not subagents), `dsh-plugin-subagent-director`,
`DSH-Subagent-Model-Router` (routing, not monitoring). This one is the only
purpose-built **live run monitor** with a sidebar mount point. The shipped
core (`@deepseek-ai/dsh-client-ui-subagent`) already contributes a header
lineage catalog (breadcrumb dropdown on the session header) — good for
navigation, but no persistent always-visible panel; the two coexist.

**Dependency hygiene (ground rule 2):** every `@deepseek-ai/*` is a peer
(loose `>=0.1.0-rc.0` ranges — satisfied by this install); its only regular
dependency is react. Its `cordis.patch.yml` inserts exactly one row
(`id: ui-subagent-monitor`); no override of `tools`/`code-runtime`.

## Install

In the same batch as dsh-better-sidebar:

```sh
PATH=/usr/bin:$PATH dsh plugin --profile web add @leetoners/dsh-ui-subagent-monitor@0.2.0
```

(The PATH prefix keeps pnpm's major aligned with the profile store — see
`../dsh-better-sidebar/README.md`, Install step 2.)

## Activation

Restart `dsh --profile web` / the desktop app (bundle layers compose at
boot). Existing sessions pick it up on their next request; first-time mounts
need the boot.

## Verify

- `setup/verify.sh` §3 PASSes the `ui-subagent-monitor` composed row.
- GUI after restart: a Subagents action sits beside Settings at the sidebar
  foot; clicking it opens the panel. Spawn any subagent (e.g. a background
  `subagent` call) and watch its card go running → done with elapsed time;
  "Open chat" navigates into the child session.

## Rollback

`dsh plugin --profile web remove @leetoners/dsh-ui-subagent-monitor`, restart.

## English-label patch (applied 2026-09-05)

The plugin ships **hardcoded Chinese** UI strings — it registers no locale
namespace at all (unlike dsh-better-sidebar, which follows the DSH i18n chain
and renders English under `locale.preference: en`). Every visible label in
`lib/client.js` is a literal (`运行中`/`完成`/`打开对话`/panel title/etc.,
33 runs). Upstream source confirms it is not a settings issue.

Fix: a **pnpm patchedDependency** translating all user-visible strings to
English — artifact `english-labels.patch` in this directory (identical copy
lands at \`patches/@leetoners__dsh-ui-subagent-monitor@0.2.0.patch\` in the
profile). Re-apply on a target machine by adding to
\`$DSH_HOME/profiles/web/pnpm-workspace.yaml\`:

```yaml
patchedDependencies:
  '@leetoners/dsh-ui-subagent-monitor@0.2.0': patches/@leetoners__dsh-ui-subagent-monitor@0.2.0.patch
```

(copy the patch file into \`patches/\` first), then \`pnpm install\` in the
profile dir. The canonical profile-state record
(\`profile-backup.stripped.json\`) already carries both the yaml row and the
patch content, so the dshmarket Backup & Restore import applies it too.

**Re-evaluate on version bump:** the patch pins 0.2.0; a newer upstream may
add real i18n (drop the patch) or move strings (regenerate via
\`pnpm patch @leetoners/dsh-ui-subagent-monitor@<ver>\`, edit
\`lib/client.js\` labels, \`pnpm patch-commit\`).
