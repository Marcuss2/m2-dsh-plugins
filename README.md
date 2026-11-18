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
| Harness | `@deepseek-ai/dsh` **0.2.2-rc.1** (global npm install) |
| Launch | `dsh --profile web` — Web GUI, `DSH_HOME=~/.dsh` |
| Profile | `web` — **23 dependencies, 25 ordered bundles** |
| Default agent preset | `custom` — **Productivity Mode**, PTC tool presentation (`run_code` + generated SDK) |
| Default model | `deepseek-v4-1-flash-1017` on provider `mistral-vibe`, reasoning effort `high` |
| Mistral Vibe route | `@khuraie/dsh-mistral-vibe-provider` 0.1.29 (GitHub, unpinned) — Settings → **Mistral Vibe** |
| Forge / worktree | `@deepseek-ai/dsh-experimental-forge-bundle` 0.2.2-rc.1 (host-shipped) — worktree option + change-request panel |
| Web search | `dsh-free-search` 0.9.51, engine **`exa`**, keyless |
| Plugin market | `dshmarket` **1.70.2** |
| MCP 管理 | `dsh-mcp-setting` 0.2.0 — Settings → **MCP Servers** |
| Agent Teams models | `dsh-agent-team-model-selection` 0.7.0 — Settings → **Agent Teams models** |

Profile inventory last recorded **2026-11-18**, after the Mistral Vibe route
and the host's forge bundle joined the profile and the default model moved
onto that route; the 0.2.2-rc.1 update before it had dropped the Hindsight
bundle (see `CHANGELOG.md`). Preset prompts last compacted **2026-11-11**,
with the additive `run_code` paragraph on 2026-11-16. What changed, and when,
is in `CHANGELOG.md`.

## Plugins

The `web` profile as recorded **2026-11-18**. *Spec* is what
`$DSH_HOME/profiles/web/package.json` records, *installed* is the version
resolved in the profile's `node_modules`; `~` stands for `/home/vrbkam`. The
machine-readable copy of every row is `dsh-market/profile-backup.json`.

| Package | Recorded spec | Installed | What it adds |
| --- | --- | --- | --- |
| `@brucezhang1993/dsh-computer-use-linux` | `link:~/repos/dsh-computer-use-linux` | 0.1.1 | desktop computer use (`mcp__cul__*`), mounted **only** by the `computeruse` preset |
| `@idealclover/dsh-session-title-studio` | `0.8.1` | 0.8.1 | session titles: recipes, refresh policy, topic-drift detection |
| `@khuraie/dsh-mistral-vibe-provider` | `github:Khuraie/dsh-mistral-vibe-provider` | 0.1.29 | the `mistral-vibe` LLM route, PKCE sign-in and Vibe/Studio budget meters |
| `@linxin666/dsh-client-ui-git-graph` | `^0.3.20` | 0.3.20 | git branch selector + graph — loader row **disabled** (see constraints) |
| `@linxin666/dsh-client-ui-task-board` | `0.4.8` | 0.4.8 | Host-authoritative task board with real session runs and cron |
| `@local/dsh-custom-presets` | `link:~/dsh-custom-presets` | 1.0.0 | the four agent presets — see `agent-presets/` |
| `@michengai/dsh-skills-manager` | `1.4.9` | 1.4.9 | loads and toggles local skills (`~/.dsh/skills`) |
| `@vectorize-io/hindsight-coding-agents` | `0.8.2` | 0.8.2 | Hindsight memory — **installed, bundle not mounted** |
| `dsh-agent-team-model-selection` | `github:devloom1024/dsh-agent-team-model-selection#5150ff9d87799320fa04577db44786175fd1db4f` | 0.7.0 | per-member Agent Teams route selection; Settings → **Agent Teams models** |
| `dsh-better-reasoning-effort` | `0.5.4` | 0.5.4 | per-model reasoning effort and input modalities |
| `dsh-better-sidebar` | `0.28.0` | 0.28.0 | file tree, editor, changes, tasks and side chat in one sidebar |
| `dsh-context` | `0.84.1` | 0.84.1 | context dashboard and `/context` command |
| `dsh-free-search` | `0.9.51` | 0.9.51 | web search + fetch: 39 engines, engine `exa`, keyless |
| `dsh-lsp-actions` | `0.5.21` | 0.5.21 | the `lsp_*` tools over language servers |
| `dsh-mcp-connector` | `link:~/repos/dsh-mcp-connector` | 0.2.77 | MCP server connections, catalog and cross-server tool search |
| `dsh-mcp-setting` | `0.2.0` | 0.2.0 | Settings → **MCP Servers** over the `dsh-mcp-client` rows |
| `dsh-subagent-workspace-ui` | `^1.3.3` | 1.3.3 | subagent manager UI — **patch-pinned**, cannot upgrade (see constraints) |
| `dsh-tool-ast-grep` | `0.1.2` | 0.1.2 | AST structural search (`ast_search`) and outline (`ast_outline`) tools |
| `dsh-workboard` | `link:~/Projects/dsh-workboard/workboard` | 0.1.0 | one merged, urgency-ordered workboard |
| `dsh-workboard-gitlab` | `link:~/Projects/dsh-workboard/workboard-gitlab` | 0.1.0 | GitLab provider for the workboard |
| `dsh-workboard-jira` | `link:~/Projects/dsh-workboard/workboard-jira` | 0.1.0 | Jira Cloud provider for the workboard |
| `dshmarket` | `1.70.2` | 1.70.2 | Settings → **Plugin Market**, Browse/install/upgrade + Backup & Restore |
| `mattpocock-skills-dsh` | `0.1.8` | 0.1.8 | Matt Pocock's skills bundle |

Two more entries in `dsh.profile.bundles` have **no dependency row** because
they ship inside the harness install: `@deepseek-ai/dsh-experimental-forge-bundle`
(0.2.2-rc.1 — `worktree`, `tool-worktree` and the `forge*` change-request rows)
and `@deepseek-ai/dsh-experimental-agent-team-profile` (0.2.2-rc.1). The list
also opens with the host's own `@deepseek-ai/dsh-base` and
`@deepseek-ai/dsh-web-app` layers. Bundle order matters and is recorded in the
backup, not here.

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
`subagent-model-selection-settings` and `tool-agent-team-model-selection`
now carry the `mistral-vibe` routes. See `dsh-market/README.md` for the
backup that records it.

## Machine tooling

Software outside the profile that the installed plugins depend on, or that
makes them worth having. Install these **before** restoring the profile — a
plugin whose backing binaries are missing mounts fine and then does nothing.

| Tool | Version | Backs | Why it matters here |
| --- | --- | --- | --- |
| `@deepseek-ai/dsh` | 0.2.2-rc.1 | everything | the harness itself |
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

### Agent Teams models (Settings GUI)

`dsh-agent-team-model-selection` 0.7.0 (added 2026-11-11) adds Settings →
**Agent Teams models** and turns the Agent Teams route from one team-wide model
into a per-member one. It is installed as a **GitHub bundle**, pinned to commit
`5150ff9d87799320fa04577db44786175fd1db4f`, because the package is not
published to npm under this name; `dshmarket` therefore will not offer it
updates.

- **It replaces the shipped Team tool plugin.** The bundle's patch disables the
  `tool-agent-team` row and inserts its own `tool-agent-team-model-selection`
  row; both register the same nine Team tool names in each member scope, so
  they cannot coexist. The reimplementation carries no peer dependencies and
  vendors the schema helper it needs, which is why it mounts on 0.2.2-rc.1
  (its `list_agents` route reporting was re-checked live after the update).
- **What the tools gained.** `spawn_teammate` accepts optional `provider`,
  `model` and `reasoning_effort`; `list_agents` reports the live route of every
  member as an `llm` field; and the new `list_team_models` lists providers,
  one provider's models, or one model's reasoning efforts.
- **Two policy modes.** `inherit` (automatic) follows the Lead unless a spawn
  pins a route; `fixed` pins every new teammate to one configured route and
  rejects any route parameter on `spawn_teammate`. An optional `allowedModels`
  list bounds every route a teammate may actually run on — explicit,
  effort-only, and inherited — in `inherit` mode.
- **The route is applied through the subagent seam.** The plugin hooks
  `ctx.subagents.startActivation` and merges the selected route into the
  child's `agentOptions`; both in-process providers (`spawn`, `fork`) declare
  that capability, so no other configuration is needed.

### Mistral Vibe route (Settings GUI)

`@khuraie/dsh-mistral-vibe-provider` **0.1.29** (installed 2026-11-16) registers
the **`mistral-vibe`** LLM route against `https://api.mistral.ai/v1` and adds
Settings → **Mistral Vibe**: PKCE browser sign-in through
`console.mistral.ai/api/vibe/sign-in`, the live `/v1/models` catalogue with a
price line and a tier badge per model, per-model thinking levels mapped onto
`reasoning_effort`, and the two real allowance meters (Vibe Code and
Studio/API) on the settings page and in the sidebar foot. It also puts an
approximate Session cost on the composer's token-usage pill.

- **One row, one provider.** The bundle's patch inserts only
  `llm-mistral-vibe`; no shipped row is replaced. The key is read from the
  credential record named by `apiKeyEnv` — `MISTRAL_API_KEY` — so it never
  appears in YAML, and the profile backup carries no sign-in state;
  re-authenticating after a restore is a GUI step.
- **Installed from GitHub without a pin.** The package is not published on npm;
  `dshmarket` installed `github:Khuraie/dsh-mistral-vibe-provider` at branch
  head (market log `2026-11-16T12:10:56Z`, `exit=0 hot=true`). Updating
  re-resolves the branch, and the market cannot offer updates for it.
- **Where it shows up.** `agent-default-model` points at
  `deepseek-v4-1-flash-1017` on this provider, and the subagent and Agent
  Teams allowlists carry its two routes (`mistral-large-4`,
  `deepseek-v4-1-flash-1017`). Model ids come from the live catalogue, so the
  allowlist strings must match what `/v1/models` advertises.

## Contents

| Path | What it records |
| --- | --- |
| `dsh-market/README.md` | How `dshmarket` is installed, and why it is registered the way it is |
| `dsh-market/profile-backup.json` | Canonical record of the `web` profile — dependencies, bundle order, profile config files and pnpm patches — with private data stripped |
| `agent-presets/` | The four presets in use, verbatim, plus the generator that freezes them into the live plugin |
| `prompts/` | The prompt text those presets carry — personas and plan mode |
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
  now happened on 1.3.4, 1.4.0, 1.9.0 and 1.9.1; upstream is 1.9.1. Upgrading
  means re-deriving the patch from the new `lib/client.js` first.
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
- **`tool-agent-team` is disabled on purpose.** The shipped Agent Teams tool
  row is turned off by `dsh-agent-team-model-selection`'s bundle patch, which
  inserts the replacement row that owns the same nine tool names. Re-enabling
  the shipped row without removing the plugin puts two registrants on one tool
  name. The disable lives inside the installed bundle, not in the profile's
  patch layer.
- **The Agent Teams models plugin is a moving GitHub target.** Its pin is a
  commit, not a release, and it reimplements the Team tool surface rather than
  wrapping it. A future DSH Agent Teams change can drift from it silently;
  bump the commit (`dsh plugin --profile web add
  github:devloom1024/dsh-agent-team-model-selection#<sha>`) only after checking
  its `ctx.agentTeams.*` calls against the new host.
- **The Mistral Vibe provider is an unpinned GitHub target.** The spec is
  `github:Khuraie/dsh-mistral-vibe-provider` with no commit, so a reinstall
  follows the branch head; **0.1.29** is what is installed. It is not published
  on npm, so `dshmarket` will not offer updates — update with
  `dsh plugin --profile web add github:Khuraie/dsh-mistral-vibe-provider` and a
  restart. Its model ids are live-catalogue data, not constants: the allowlist
  strings must match `/v1/models`.
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