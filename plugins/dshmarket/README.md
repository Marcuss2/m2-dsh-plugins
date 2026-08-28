# dshmarket

## What it is

The community **plugin market inside DSH Settings** — a searchable card UI
over the Awesome DSH Plugin list (see `.research/awesome-dsh-plugin.md`), with
one-click install/upgrade of any `dsh.bundle` plugin and a Themes tab. npm
package `dshmarket` (v1.33.0 at record time; publisher dsh-market,
github.com/dsh-market/dshmarket).

Installed as a DSH **profile bundle** like the other entries here. Its shipped
`cordis.patch.yml` inserts one row on the profile's layer stack:

```yaml
- insert:
    - id: dsh-market
      name: 'dshmarket'
```

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

## Install

```sh
dsh plugin --profile web add dshmarket
```

Registers the package in `dependencies` **and** `dsh.profile.bundles` — no
manual composition editing. In the batched install of the whole pack it is the
**first** spec, and in `dsh.profile.bundles` it takes the first custom slot
(right after the two shipped bundles), so later bundles' patches apply on top of
it:

```sh
dsh plugin --profile web add \
  dshmarket dsh-better-edit @vectorize-io/hindsight-coding-agents \
  dsh-checkpoint-rewind dsh-debugger-dap dsh-llm-fallbacks \
  dsh-lsp-actions dsh-search-failover
```

## Activation

Bundle layers compose at boot: **restart `dsh --profile web`**, then open
Settings in the Web GUI — the market tab is contributed by the client half, so
it appears only after a page load against the restarted server.

## Verify

1. `dsh --profile web --dump-config` shows a `# == dshmarket` layer containing
   the `dsh-market` row (also covered by `setup/verify.sh`).
2. In the Web GUI: **Settings → Plugin Market**. Verified on 2026-08-28 by
   driving the running GUI with the `agent-browser` skill: the panel renders a
   "Plugin Market" heading, an **Update market** button, and **Discover /
   Themes / Installed (9) / Advanced / Tasks** tabs, with the installed-bundle
   count matching the profile. `dsh-search-failover` contributes its own
   **Search Pool** settings tab alongside it.

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

## Remove

```sh
dsh plugin --profile web remove dshmarket
```

(or delete the dependency and the bundle entry from the profile's
`package.json`), then restart.
