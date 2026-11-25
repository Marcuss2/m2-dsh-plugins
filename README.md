# DeepSeek Harness setup

A plain record of the DeepSeek Harness (DSH) setup on this machine: how
`dsh-market` is installed, the canonical profile backup, **every plugin the
profile carries**, the agent presets in use, and the prompts they carry.

This repository is **not** a reproduction kit and contains no plugin source.
Plugins are installed directly into the `web` profile. The **plugin inventory**
below lists each one with its recorded spec, its installed version and what it
adds; `dsh-market`'s own Backup & Restore export in `dsh-market/` is the
machine-readable copy.

## Current setup

| | |
| --- | --- |
| Harness | `@deepseek-ai/dsh` **0.2.2-rc.5** (global npm install) |
| Launch | `dsh --profile web` — Web GUI, `DSH_HOME=~/.dsh` |
| Profile | `web` — **23 dependencies, 25 ordered bundles** |
| Default agent preset | `custom` — **Productivity Mode**, PTC tool presentation (`run_code` + generated SDK) |
| Default model | `deepseek-v4.1-flash` on provider `dsh-opencode-go`, reasoning effort `low` |
| OpenCode Go route | `dsh-opencode-go` 0.4.9 (npm, exact pin) — Settings → **OpenCode Go** plus a sidebar console |
| Forge / worktree | `@deepseek-ai/dsh-experimental-forge-bundle` 0.2.2-rc.5 (host-shipped) — worktree option + change-request panel |
| Web search | `dsh-free-search` 0.9.84, engine **`exa`**, keyless |
| Plugin market | `dshmarket` **1.70.2** |
| MCP 管理 | `dsh-mcp-setting` 0.2.0 — Settings → **MCP Servers** |
| Agent Teams | host-shipped `agent-team` + `tool-agent-team` — shared task DAG; teammate control uses the standard subagent tools |

Profile inventory last recorded **2026-11-25**, after the `dsh-opencode-go`
0.4.9 route replaced the removed `mistral-vibe` provider and seven plugin
versions moved; the 0.2.2-rc.1 update before it had dropped the Hindsight
bundle (see `CHANGELOG.md`). Preset prompts last compacted **2026-11-11**, with
the additive `run_code` paragraph on 2026-11-16 and the
`run_code`-`description` paragraph on 2026-11-25; all four presets and their
prompt extracts were re-verified against the live sources on 2026-11-25. What
changed, and when, is in `CHANGELOG.md`.

## Plugins

The `web` profile as recorded **2026-11-25**. *Spec* is what
`$DSH_HOME/profiles/web/package.json` records, *installed* is the version
resolved in the profile's `node_modules`; `~` stands for `/home/vrbkam`. The
machine-readable copy of every row is `dsh-market/profile-backup.json`.

| Package | Recorded spec | Installed | What it adds |
| --- | --- | --- | --- |
| `@brucezhang1993/dsh-computer-use-linux` | `link:~/repos/dsh-computer-use-linux` | 0.1.1 | desktop computer use (`mcp__cul__*`), mounted **only** by the `computeruse` preset |
| `@idealclover/dsh-session-title-studio` | `0.8.1` | 0.8.1 | session titles: recipes, refresh policy, topic-drift detection |
| `@linxin666/dsh-client-ui-git-graph` | `^0.3.20` | 0.3.20 | git branch selector + graph — loader row **disabled** (see constraints) |
| `@linxin666/dsh-client-ui-task-board` | `0.4.21` | 0.4.21 | Host-authoritative task board with real session runs and cron |
| `@local/dsh-custom-presets` | `link:~/dsh-custom-presets` | 1.0.0 | the four agent presets — see `agent-presets/` |
| `@lolkda/dsh-agent-team-model-pin` | `^1.8.4` | 1.8.4 | per-session Team model, effort and creation-preset pinning, with native command menus |
| `@michengai/dsh-skills-manager` | `1.5.4` | 1.5.4 | loads and toggles local skills (`~/.dsh/skills`) |
| `@vectorize-io/hindsight-coding-agents` | `0.8.2` | 0.8.2 | Hindsight memory — **installed, bundle not mounted** |
| `dsh-better-reasoning-effort` | `0.5.4` | 0.5.4 | per-model reasoning effort and input modalities |
| `dsh-better-sidebar` | `0.33.0` | 0.33.0 | file tree, editor, changes, tasks and side chat in one sidebar — the DSH 0.2.2-rc.2+ build |
| `dsh-context` | `0.87.1` | 0.87.1 | context dashboard and `/context` command |
| `dsh-free-search` | `0.9.84` | 0.9.84 | web search + fetch: 43 engines, engine `exa`, keyless |
| `dsh-lsp-actions` | `0.5.24` | 0.5.24 | the `lsp_*` tools over language servers |
| `dsh-mcp-connector` | `link:~/repos/dsh-mcp-connector` | 0.2.77 | MCP server connections, catalog and cross-server tool search |
| `dsh-mcp-setting` | `0.2.0` | 0.2.0 | Settings → **MCP Servers** over the `dsh-mcp-client` rows |
| `dsh-opencode-go` | `0.4.9` | 0.4.9 | the `dsh-opencode-go` LLM route (Go + Free gateways), usage meters, multi-account failover, sidebar console |
| `dsh-subagent-workspace-ui` | `^1.3.3` | 1.3.3 | subagent manager UI — **patch-pinned**, cannot upgrade (see constraints) |
| `dsh-tool-ast-grep` | `0.1.2` | 0.1.2 | AST structural search (`ast_search`) and outline (`ast_outline`) tools |
| `dsh-workboard` | `link:~/Projects/dsh-workboard/workboard` | 0.1.0 | one merged, urgency-ordered workboard |
| `dsh-workboard-gitlab` | `link:~/Projects/dsh-workboard/workboard-gitlab` | 0.1.0 | GitLab provider for the workboard |
| `dsh-workboard-jira` | `link:~/Projects/dsh-workboard/workboard-jira` | 0.1.0 | Jira Cloud provider for the workboard |
| `dshmarket` | `1.70.2` | 1.70.2 | Settings → **Plugin Market**, Browse/install/upgrade + Backup & Restore |
| `mattpocock-skills-dsh` | `0.1.10` | 0.1.10 | Matt Pocock's skills bundle |

Two entries in `dsh.profile.bundles` have **no dependency row** because they
ship inside the harness install: `@deepseek-ai/dsh-experimental-forge-bundle`
(0.2.2-rc.5 — `worktree`, `tool-worktree` and the `forge*` change-request
rows) and `@deepseek-ai/dsh-experimental-plugin-market-bundle` (0.2.2-rc.5 —
the `plugin-market` host service and the `ui-plugin-market` Discover tab).
The list also opens with the host's own `@deepseek-ai/dsh-base` and
`@deepseek-ai/dsh-web-app` layers. The older
`@deepseek-ai/dsh-experimental-agent-team-profile` entry is gone: rc.5 no
longer ships that package. Bundle order matters and is recorded in the backup,
not here.

## Where settings live now

As of DSH 0.1.7-rc.2 the old `$DSH_HOME/settings.yaml` is **no longer read**:
the harness renamed it `settings.yaml.imported` and its keys are now expressed
as **patch rows in `$DSH_HOME/profiles/web/cordis.patch.yml`** —
`agent-default-model`, `agent-preset-registry`, `locale`, `llm-pi-ai`,
`better-sidebar`. The imported file still holds the old document verbatim,
including the `search-pool` block that belonged to the removed
`dsh-search-failover` — dead config now.

So the profile's patch layer is the settings file, and it also carries
configuration for individual plugins — the Exa engine override on the
`web-search-free` row, and the route rows themselves: `agent-default-model`,
`subagent-model-selection-settings`, `agent-team-model-pin` and `opencode-go`
carry the `dsh-opencode-go` routes. Two 2026-11-24 additions sit in this layer
as well: the `provider-alias-mistral-vibe-v2` insert row, which maps the
removed `mistral-vibe` provider id onto `dsh-opencode-go`/`hy4` for sessions
whose durable request header still names it, and comments pointing at
`COMPACTION-FIX.md`. The `tool-agent-team-model-selection` row was removed
with its plugin on 2026-11-21; a comment in the patch file explains why. See
`dsh-market/README.md` for the backup that records it.

## Machine tooling

Software outside the profile that the installed plugins depend on, or that
makes them worth having. Install these **before** restoring the profile — a
plugin whose backing binaries are missing mounts fine and then does nothing.

| Tool | Version | Backs | Why it matters here |
| --- | --- | --- | --- |
| `@deepseek-ai/dsh` | 0.2.2-rc.5 | everything | the harness itself |
| `dshmarket` (profile dep) | 1.70.2 | Settings → Plugin Market | browse/install/upgrade + Backup & Restore |
| `typescript-language-server` | 6.0.0 | `dsh-lsp-actions` | the `lsp_*` tools for TypeScript/JavaScript |
| `pyright` (+ `pyright-langserver`) | 1.1.412 | `dsh-lsp-actions` | the `lsp_*` tools for Python |
| `rust-analyzer` | **absent** (rustup proxy only) | `dsh-lsp-actions` | `rust-analyzer --version` fails: the component is not in the toolchain — see below |
| `clangd` | system | `dsh-lsp-actions` | already present |
| `agent-browser` | 0.42.0 | persona of all four presets | browser automation CLI, driven through the `bash` tool — see below |
| `@brucezhang1993/dsh-computer-use-linux` | 0.1.1 (profile link dep) | the `computeruse` preset | Linux computer use MCP bridge (`mcp__cul__*` tools) — see below |
| `computer-use-linux` (upstream binary) | 0.7.13, pinned by the plugin | `mcp__cul__*` tools | Rust MCP server, cached at `~/.cache/computer-use-linux/plugin/` |
| `wtype`, `ydotool` | system packages | `mcp__cul__type_text` / `mcp__cul__click` | Wayland input synthesis — installed 2026-11-18; the input path itself not yet exercised |

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

`agent-browser` (global npm package, binary `/usr/bin/agent-browser`) is the
same shape of thing from the other side: a browser-automation CLI the agent
reaches through the `bash` tool. No plugin backs it and none is needed —
unlike the language servers there is no harness tool to discover it, so all
presets tell the agent it exists in their persona suffix (added
2026-10-15).
Smoke-tested live: `open` → `get title` → `snapshot` against
`https://example.com`, then `close`.

Still missing, deliberately recorded: **no DAP debug adapter** (`debugpy`,
`dlv`, `codelldb`, `netcoredbg` are all absent), so the debugger surface has
nothing to attach to; no `gopls`, `jdtls`, `bash-language-server` or
`yaml-language-server`; and no working `rust-analyzer` — the command resolves
to the rustup proxy, and `rustup component list --installed` has no
`rust-analyzer`, so Rust files get no `lsp_*` backend until
`rustup component add rust-analyzer`. Add one only when a project actually
needs it — each is a single package install with no plugin change.

### Computer use (Hyprland)

`@brucezhang1993/dsh-computer-use-linux` 0.1.1 (added 2026-10-15) bridges the
upstream `agent-sh/computer-use-linux` Rust MCP server into the harness as the
`mcp__cul__*` tools: `doctor`, `get_app_state` (AT-SPI tree + screenshot),
`list_windows`, `click`, `type_text`, `press_key`, `scroll`, `drag`. Its
Hyprland backend is `hyprctl`; screenshots go through `xdg-desktop-portal`.
The bridge is the in-box `@deepseek-ai/dsh-mcp-client` — no DSH modification.

- **Scoped to the `computeruse` preset, not the profile.** The plugin package
  is a web-profile **dependency** (the `!!js` launcher resolution anchors at
  the profile's `package.json`), but its bundle is NOT listed in
  `dsh.profile.bundles`. The two rows mount inside the `computeruse` agent
  preset's plugin list instead (`agent-presets/README.md`), so only sessions
  on that preset see the `mcp__cul__*` tools. Running the profile-level
  mount and the preset-level mount at once would collide on tool names.
- **Verified live**: `mcp__cul__screenshot` captured the whole desktop
  through `xdg-desktop-portal`; `doctor` reports the Hyprland windowing
  backend OK, portals OK. AT-SPI was enabled by hand
  (`gsettings set org.gnome.desktop.interface toolkit-accessibility true`
  plus the `org.a11y.Status IsEnabled` D-Bus property — there is no GNOME to
  own that setting on Hyprland).
- **Input binaries landed 2026-11-18**: `wtype` and `ydotool` are now on
  PATH (`/usr/bin/wtype`, `/usr/bin/ydotool`). They are what
  `mcp__cul__type_text` and `mcp__cul__click` fall back to on Wayland — the
  portal's RemoteDesktop interface lacks pointer methods under the Hyprland
  portal, so clicks go through ydotool/uinput, and `/dev/uinput` already
  carries an rw ACL for the user. Presence is verified; the click/type path
  itself has not been exercised live since they landed.
- **Portal consent and scoping are settled.** The live screenshot above went
  through `xdg-desktop-portal`, consent included, and preset scoping was
  confirmed live on 2026-10-15: a session on **Computer Use** shows the
  `mcp__cul__*` tools, a session on Productivity Mode does not.

### MCP servers (Settings GUI)

`dsh-mcp-setting` 0.2.0 (added 2026-10-18) adds Settings → **MCP Servers**: a
GUI over the canonical MCP configuration — the `@deepseek-ai/dsh-mcp-client`
rows in the patch layers. It lists, adds, edits, deletes and toggles rows in
the home patch (`~/.dsh/cordis.patch.yml`, all profiles) and the per-profile
`cordis.patch.yml` files; toggles write the `disabled` flag and hot-apply via
config live reload, no restart. The `cul` server does **not** appear there:
it is scoped to the `computeruse` preset, so its row lives in the preset
config, not in a patch file — preset-plane mounts stay preset-plane.

### Agent Teams (host-shipped)

`dsh-agent-team-model-selection` 0.7.0 was **removed on 2026-11-21**. DSH
0.2.2-rc.5 had removed `ctx.agentTeams.tryMembership` (and the old
spawn/message/roster APIs) while the plugin still called `tryMembership` from
an `agent/created` listener. That synchronous throw vetoed session creation,
so **New session** failed with `ctx.agentTeams.tryMembership is not a function`
and existing sessions reported **Session unavailable**.

The profile now uses the host-shipped `agent-team` and `tool-agent-team` rows
plus `@lolkda/dsh-agent-team-model-pin` 1.8.4 (installed 2026-11-22), whose
`agent-team-model-pin` patch row carries per-session model/effort pins — four
sessions now carry `dsh-opencode-go/deepseek-v4.1-flash`, two pinned at `high`
and two recorded as `modelDefault`.
Team membership is derived from the standard subagent tree; teammate control
uses `subagent`, `send_message({ agent_id, … })`, `list_agents` and
`interrupt_agent({ agent_id })`. Ordinary subagent model selection remains
under Settings → **Subagent models**. Details and verification are in
`CHANGELOG.md`.

### OpenCode Go route (Settings GUI)

`dsh-opencode-go` **0.4.9** (installed 2026-11-24, registry package pinned
exactly) registers the **`dsh-opencode-go`** LLM route — two gateways, Go and
Free — and its own Settings page, **OpenCode Go**: an opt-in sidebar console
(Overview, usage board, accounts, models, appearance, advanced, about), live
quota multipliers on the model list and in the model picker, five
composer-pill shapes for the allowance meters, a daily usage board read from
the official console CSV, up to 20 accounts with pre-output failover on
`401/403`, `429` and quota exhaustion, and a session-level prompt-cache
binding through `x-opencode-session`. It needs DSH `0.2.1-rc.5` or newer.

- **One row, one provider.** The bundle's patch inserts only `opencode-go`;
  the profile patch's `opencode-go` row carries the UI settings
  (`sidebarEntry`, `goPlan`, `modelVisibility`, `usagePillStyle`). Credentials
  live in the credential store, not in YAML, so the profile backup carries no
  sign-in state; re-authenticating after a restore is a GUI step.
- **It replaced `@khuraie/dsh-mistral-vibe-provider`.** That GitHub-installed,
  unpinned package (0.1.29) was uninstalled on 2026-11-24 and its
  `mistral-vibe` routes went with it. `agent-default-model` now points at
  `dsh-opencode-go`/`deepseek-v4.1-flash` with `reasoningEffort: low`; the
  subagent and Agent Teams allowlists list the OpenCode Go catalogue. A
  `provider-alias-mistral-vibe-v2` insert forwards the old provider id to
  `dsh-opencode-go`/`hy4` for sessions whose durable request header still names
  it, and the profile-local `dsh-compaction-basic` wrapper covers the same
  stale route inside compaction — see `COMPACTION-FIX.md`.
- **Where it shows up.** The composer's model picker, Settings →
  **OpenCode Go**, the sidebar console when `sidebarEntry` is on, the
  composer usage pill, and the subagent/Agent Teams allowlists. Model ids are
  live-catalogue data from the gateway `/models`, not constants.

## Contents

| Path | What it records |
| --- | --- |
| `dsh-market/README.md` | How `dshmarket` is installed, and why it is registered the way it is |
| `dsh-market/profile-backup.json` | Canonical record of the `web` profile — dependencies, bundle order, profile config files and pnpm patches — with private data stripped |
| `agent-presets/` | The four presets in use, verbatim, plus the generator that freezes them into the live plugin |
| `prompts/` | The prompt text those presets carry — personas and plan mode |
| `COMPACTION-FIX.md` | Diagnosis and fix record for the 2026-11-24 `/compact` failure after the `mistral-vibe` removal |
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
  now happened on 1.3.4, 1.4.0, 1.9.0, 1.9.1 and 1.12.0; upstream is 1.12.0.
  Upgrading means re-deriving the patch from the new `lib/client.js` first.
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
- **The old Agent Teams model-selection plugin is gone.** Do not reinstall the
  commit-pinned `dsh-agent-team-model-selection` 0.7.0: it reimplements a Team
  tool surface DSH removed in 0.2.1-rc.2 and still calls
  `ctx.agentTeams.tryMembership`. On rc.5 that call throws during agent
  creation. Its old patch row and the bundle's `tool-agent-team` disable went
  away with the uninstall; the shipped Team tool row is active again.
- **`dsh-better-sidebar` must match the host's line, not just its major
  version.** The profile now runs **0.33.0** (peers `^0.2.2-rc.2`, cordis
  `^4.1.0`); its `subagentCatalog` roster replaced the `agentTeam.members`
  read that 0.28.0 still used (0.28.0 crashed the Tasks view on rc.5). A 0.x
  caret never spans a minor version, so the market's `latest` pick can be wrong
  for an older host: 0.2.2-rc.1 needs 0.32.0, and the 0.2.1 line needs 0.28.2.
- **The `mistral-vibe` provider is gone, but its id still appears in old
  sessions.** The unpinned GitHub package was uninstalled on 2026-11-24. Two
  shims keep those sessions working: the `provider-alias-mistral-vibe-v2`
  insert in the profile patch (a plain JS row at
  `$DSH_HOME/plugins/dsh-provider-alias/index-v2.js`) and the profile-local
  `@deepseek-ai/dsh-compaction-basic` wrapper at
  `$DSH_HOME/profiles/web/node_modules/@deepseek-ai/dsh-compaction-basic/`
  (canonical copy in `$DSH_HOME/plugins/dsh-compaction-basic-compat/`).
  Neither is a plugin dependency, so the profile backup records the alias row
  but not the wrapper; recreate it from `COMPACTION-FIX.md` after a restore.
  `dsh-opencode-go` itself is a normal npm package pinned exactly at **0.4.9**,
  but its model ids are live-catalogue data, not constants: the allowlist
  strings must match the gateway `/models`.
- **The forge bundle is host-shipped and experimental.**
  `@deepseek-ai/dsh-experimental-forge-bundle` sits in `dsh.profile.bundles` but has no
  dependency row — it resolves from the `@deepseek-ai/dsh` install, so its
  `worktree`/`forge*` rows move with the host and may change between
  releases. Listing the bundle name is the whole change.
- **Custom presets must be regenerated after a DSH update.** The preset rows
  are composed at boot, and `@local/dsh-custom-presets/cordis.patch.yml` is a
  freeze of the legacy sources by `agent-presets/generate-patch.cjs` — its
  transforms absorb every host rename/removal so far. A stale freeze fails
  **New session** with `agent-preset/invalid ... never started` (seen on
  0.2.2-rc.1: the removed `tool-subagent-control/list-agents` subpath). After
  updating `@deepseek-ai/dsh`, run the generator and restart before creating a
  session.
- **The Hindsight memory bundle is installed but not mounted.**
  `@vectorize-io/hindsight-coding-agents` 0.8.2 is still a profile dependency,
  but as of 2026-11-15 it is absent from `dsh.profile.bundles`, so the
  `hindsight_*` tools are gone even though a resumed session's prompt may still
  advertise them. Re-add the bundle name and restart to restore memory tools.

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
  *Recording a fresh export*), and update the **Plugins** inventory above if the
  dependency set, a spec, or an installed version moved.
- **Preset change** → edit the legacy source, re-run the generator, check
  `dsh --profile web --dump-config`, then re-copy `agent-presets/` (byte-identical
  to the live sources) and refresh `prompts/`.
- **Settings change** → these are patch rows now; the backup records them, so
  re-export and correct the table above.