# dsh-better-sidebar

## What it is

The Web GUI **sidebar workbench**: npm package `dsh-better-sidebar`
(omdsh-dev/dsh-better-sidebar, MIT, **0.18.0 installed** on 2026-09-05; ★3.3k,
~208k downloads — the most-used community sidebar plugin). It replaces the
stock left column's workspace browser seat (`sidebar.workspaces`) with a
tabbed workbench: file explorer, CodeMirror editor (all common languages),
node-pty terminal, Git panel, Markdown/Mermaid preview, and a built-in
Subagents tab. Third-party plugins can register additional tabs through its
published service face `ctx.betterSidebar.registerTab(descriptor)` (see
`lib/types/client/service.d.ts` in the installed bundle) — which is how
sidebar occupants extend it without forking.

It matters here because the user asked for "a plugin for a sidebar" as the
surface other panels mount into; this is that base.

## Why this plugin (checked per ground rule 1)

Market sweep of the awesome-dsh-plugin index (3117 entries, 2026-09-05):
`dsh-popout-sidebar` (artifacts + file tree, pop-out tab),
`dsh-flyout-sidebar`, `DSH-Right-Sidebar` (right dock),
`dsh-better-sidebar-N23` (full fork), `dsh-plugin-sidebar-views` (pin/filter
switcher only). Chosen over them: richest base + an explicit third-party tab
API + largest install base; the N23 fork adds nothing needed here.

**Dependency hygiene (ground rule 2):** all `@deepseek-ai/*` are
peerDependencies (ranges target core `^0.1.2-rc.1`; pnpm only warns under
this install's 0.1.1-rc.2 — same held-peer situation as llm-fallbacks et al.).
Regular deps are codemirror/mermaid/node-pty/dompurify/ws/react-icons — no
core shadowing. Its `cordis.patch.yml` inserts exactly one row
(`id: better-sidebar`) plus a self-disabling double-mount guard; it never
overrides `id: tools` or `id: code-runtime`.

## Install

One spec inside the batched profile install (see ../README.md "How the npm
bundles get installed"):

```sh
dsh plugin --profile web add dsh-better-sidebar@0.18.0
```

Two machine-level consequences to handle in the same task:

1. **node-pty needs a build script.** Add to
   `$DSH_HOME/profiles/web/pnpm-workspace.yaml`:

   ```yaml
   allowBuilds:
     node-pty: true
   ```

   then `cd $DSH_HOME/profiles/web && pnpm install` (compiles the native
   `pty.node`). Without it the install exits with
   `ERR_PNPM_IGNORED_BUILDS: node-pty` and the terminal tab is dead.
2. **pnpm major must match the profile store.** The desktop AppImage ships
   pnpm v10 on PATH ahead of the system pnpm; the profile's node_modules is
   linked from store v11, so `dsh plugin add` dies with
   `ERR_PNPM_UNEXPECTED_STORE`. Run the command with the system pnpm first:
   `PATH=/usr/bin:$PATH dsh plugin --profile web add ...`.

## Activation & known CLI quirk

- Bundle layers compose at boot: restart `dsh --profile web` (or the
  desktop app) after installing.
- **Quirk found during install (2026-09-05):** when the pnpm step fails
  (e.g. ignored builds), `dsh plugin add` still reconciles
  `dsh.profile.bundles` — and rewrites it alphabetically, pulling in
  dependency-only packages like `dshmarket`. That duplicate-mounts
  `id: dsh-market` and kills every boot (`duplicate loader entry id`).
  After any failed-then-retried add, check `package.json`:
  `dshmarket` must NOT be in `bundles` (verify.sh §3 FAILs if it is),
  and restore the recorded layer order by hand if it was reshuffled.

## Verify

- `setup/verify.sh` §3 PASSes rows `dsh-better-sidebar` and
  `ui-subagent-monitor` in the composed config; §4 stays green
  (no core shadow beyond the documented cosmokit/schemastery WARNs).
- In the GUI after a restart: the sidebar shows the workbench tabs (Files,
  Terminal, Git, Subagents); opening the terminal tab proves node-pty built.

## Rollback

`dsh plugin --profile web remove dsh-better-sidebar` (same pnpm-PATH
caveat), drop the `allowBuilds` line, restart.
