# agent-browser-skill

## What it is

A DSH **filesystem skill** (not a Cordis plugin) that gives every agent on
this install browser automation via the `agent-browser` CLI. Installed at
`$DSH_HOME/skills/agent-browser/SKILL.md` (`~/.dsh/skills/agent-browser/`),
which the shipped `dsh-skill-filesystem` provider scans by default
(`includeDefaultRoots: true` → `$DSH_HOME/skills` is always a root).

## Why this shape

Checked before choosing it (ground rule: reuse before reinvention):

- **Shipped DSH packages** — no browser-automation plugin exists (`dsh-web`
  is search/fetch only; `dsh-host-webserver` serves the GUI).
- **`agent-browser` CLI** (`/usr/bin/agent-browser`, v0.34.0 at record time)
  is already installed machine-wide and is purpose-built for AI agents:
  Chromium over CDP, accessibility snapshots with `@eN` refs, and bundled
  version-matched skills.
- **DSH filesystem skill roots** — `~/.dsh/skills` is auto-discovered for all
  sessions/workspaces, so a skill file is sufficient; no plugin code, no
  composition change, nothing to re-define after a restart.
- **Rejected alternatives** — mounting `dsh-mcp-client` against
  `agent-browser mcp` (heavier, large tool surface, composition change) and a
  dynamic Cordis wrapper tool (reinvents what CLI + skill already provide).

The skill body is deliberately a compact core-workflow guide; for the full
reference it delegates to the CLI's own always-version-matched docs
(`agent-browser skills get core --full`), so CLI upgrades never desync it.

## Dependencies

Tracked centrally in `DEPENDENCIES.md` (repo root): `nodejs-npm` and
`agent-browser` (CLI + a Chromium it can drive). They must be installed and
verified first — RESTORE.md Step 2 — because install methods differ per
system. Quick form on Linux: `npm i -g agent-browser && agent-browser install
--with-deps`.

## Install

1. Ensure the dependency above (`agent-browser --version` must work).
2. Copy `SKILL.md` from this directory to
   `$DSH_HOME/skills/agent-browser/SKILL.md` (create the directory).
3. If a file already exists at the target, diff before overwriting — it may
   contain user edits.

## Verify

- The session skill catalog lists `agent-browser` (appears in the
  `available_skills` block of any session; the filesystem watcher picks it up
  without restart).
- Smoke test:
  `export AGENT_BROWSER_SESSION=dsh-verify && agent-browser open https://example.com && agent-browser snapshot -i && agent-browser close`
  must show an accessibility snapshot with `@eN` refs.
