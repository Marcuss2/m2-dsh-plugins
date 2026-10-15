# Changelog

Dated record of changes to the live DeepSeek Harness setup on this machine.
The other directories hold the *current* state; this file holds how it got
there.

Keep the two in step: a change recorded in only one of them is a bug in the
record. Each entry states what changed, why, and the evidence — including
what was found to be *unchanged*, so a later reader can tell "verified
identical" from "not checked".

## 2026-10-15 — `@brucezhang1993/dsh-computer-use-linux` installed (computer use for Hyprland)

Searched for a "computer use" plugin so the agent can operate GUI surfaces
that CLI automation cannot reach — the motivating case is creating Kahoot
quizzes directly in the browser. This machine is Arch Linux + Hyprland
0.56.2 on Wayland, which rules out the X11/xdotool-based servers.

### What changed

- **Plugin added to the `web` profile: `@brucezhang1993/dsh-computer-use-linux`
  0.1.1** (released 2026-10-10; repo `BruceZhang1993/dsh-computer-use-linux`).
  It bridges the upstream `agent-sh/computer-use-linux` Rust MCP server
  (upstream at v0.7.16) via the in-box `@deepseek-ai/dsh-mcp-client`
  0.2.0-rc.2 into the `mcp__cul__*` tool surface — `doctor`, `get_app_state`,
  `list_windows`, `focused_window`, `screenshot`, `click`, `perform_action`,
  `set_value`, `type_text`, `press_key`, `scroll`, `drag`, window
  move/resize, `setup_accessibility`, `setup_window_targeting`, plus the
  bundled `computer-use-linux` skill.
- **Chosen over two alternatives found in the same search**:
  `berker-z/hyprhands` (Hyprland-native MCP server; v0.1, single machine,
  no releases, drag needs ydotool) and `ziggy42/wayland-computer-use-mcp`
  (weekend project, tested on GNOME only, pointer-only). The winner is the
  only one that is a DSH bundle with a maintained upstream, compositor-aware
  window targeting (Hyprland via `hyprctl`), and AT-SPI semantic actions.
- **Install form: local checkout link.** The package is served from GitHub
  Packages, and the first registry install failed with
  `ERR_PNPM_FETCH_404 … No authorization header was set for the request`
  (classic PAT with `read:packages` needed). Instead:
  `git clone https://github.com/BruceZhang1993/dsh-computer-use-linux
  ~/repos/dsh-computer-use-linux` then
  `dsh plugin --profile web add ~/repos/dsh-computer-use-linux`,
  which pnpm-links the directory. Profile went from 14 deps / 17 bundles to
  **15 deps / 18 bundles**; `dshmarket` was **not** re-inserted this time
  (single occurrence in `dsh.profile.bundles`).
- **AT-SPI enabled by hand** — on Hyprland nothing owns the accessibility
  switches, so `gsettings set org.gnome.desktop.interface
  toolkit-accessibility true` and the D-Bus property
  `org.a11y.Status IsEnabled = true` were both set directly; both verified
  as true afterwards. `/dev/uinput` already carries an rw ACL for the user
  (getfacl shows the user with `rw-`), so ydotool will run without root.
- **Profile backup re-exported** and re-stripped per the
  `dsh-market/README.md` flow; privacy grep clean (no `/home/` hits, no
  username hits). Diff against the previous record: only `createdAt`, the
  new dependency (`link:$HOME/repos/dsh-computer-use-linux`), the new bundle
  entry, and plugin-manager log entries — nothing else moved.

### Evidence

- `node scripts/doctor.mjs` (standalone, no DSH needed) downloaded the pinned
  upstream binary v0.7.13 to `~/.cache/computer-use-linux/plugin/` and
  reported: Hyprland windowing backend **OK** (`can_query_windows`,
  `can_focus_apps`, `can_focus_windows` all true), portals **OK**
  (Screenshot + ScreenCast + input_capture present; the Hyprland portal's
  RemoteDesktop lacks pointer methods, so clicks route via ydotool),
  AT-SPI bus present. Blockers recorded: accessibility was off (fixed above)
  and input tools missing (below).
- `mcp__cul__screenshot` in a live session captured the full desktop
  (5640×2880) through `xdg-desktop-portal` — capture verified live, before
  any restart. This also surfaced the first-run portal consent dialog
  ("Allow Apps to Take Screenshots?"), left for the user to grant.
- **Anomaly, recorded as observed**: the `mcp__cul__*` tools were available
  inside the session that installed the plugin, although the established
  convention says plugin-provided tools appear only in a session created
  after the boot that mounted it. Either the surface recomposed or the
  deployment serves `cul` out of band; not investigated further — flagged
  so the next verification pass can check which it is.

### Not done

- `wtype` and `ydotool` are **not installed** — pacman needs the user's
  password: `sudo pacman -S wtype ydotool`. Until then typing has no backend
  and clicks have no pointer backend (`can_send_development_input: false`).
- Portal screenshot consent not yet granted by the user.
- No harness restart yet; bundle layers compose at boot, so a restart is
  still required for the profile to boot with the plugin permanently.
- `verify.sh` still absent from the repo — pre-existing gap, unchanged.

## 2026-10-15 — `computeruse` preset added; computer use scoped to it

Follow-up to the plugin install above. The user wants the desktop
computer-use capability available **only** in an explicit agent preset, not
in every session of the profile. A preset is an agent-plane composition that
can mount plugin rows of its own, so the capability moved from the profile
layer into a new preset.

### What changed

- **New agent preset `computeruse` ("Computer Use")**, declared as
  `preset-computeruse` in the `@local/dsh-custom-presets` bundle. Source:
  `$DSH_HOME/.agent-presets/computeruse/{preset.yml,agent.cordis.yml}`,
  built from the `custom` preset with three changes:
  1. two rows before the presentation row — `mcp-computer-use-linux`
     (`@deepseek-ai/dsh-mcp-client`, `serverName: cul`, stdio,
     `toolCallTimeoutMs: 120000`, `failOnStartupError: false`) and
     `dsh-computer-use-linux` (the plugin's JS entry: registers the bundled
     skill, claims the sole computer-use provider slot). Both consume host
     registries (`tools`, `skills`) and provide nothing, so like the tool
     rows they need no `isolate` realm.
  2. the persona suffix gains the computer-use paragraph — `doctor` first,
     semantic selectors over pixels, prefer agent-browser/bash when they
     reach the same target, confirm before destructive clicks, never click
     consent dialogs.
  3. `preset.yml`: name "Computer Use", order 0. Id is the single lowercase
     word `computeruse` per the preset-id convention.
- **The plugin's bundle was removed from the web profile**:
  `dsh.profile.bundles` went 18 → 17; the package stays in `dependencies`
  (the preset's `!!js` launcher resolution is anchored at the profile's
  `package.json`, so the link must survive). This also avoids the
  duplicate-registration collision a profile-level mount and a preset-level
  mount would cause on the `mcp__cul__*` tool names.
- **The generator was extended** to freeze three presets:
  `generate-patch.cjs` now iterates `custom`, `coding`, `computeruse`
  (both the live copy and the repo copy). `cordis.patch.yml` re-froze,
  687 → 1028 lines.

### Evidence

- `dsh --profile web --dump-config` composes cleanly (exit 0): three preset
  decls present (`preset-custom`, `preset-coding`, `preset-computeruse`),
  and the `mcp-computer-use-linux` row appears ONLY inside the
  `preset-computeruse` config.plugins list — not at profile level.
- The new preset YAML parses (`yaml.parse`), 20 top-level entries
  (= custom's 18 + the 2 new rows), and carries both generator SUBST anchor
  lines verbatim so the freeze substitution still applies.
- Persona fidelity: the `suffix` block parsed from the preset file matches
  `prompts/computeruse-persona.md` line-for-line after de-indentation.
- Profile backup re-exported and re-stripped; privacy grep clean; diff
  against the previous record is only `createdAt` and the removed bundle
  entry.

### Not done

- No restart yet. After the next `dsh --profile web` restart the acceptance
  check is: a new session on **Computer Use** lists the `mcp__cul__*` tools;
  a session on Productivity Mode does not. Whether the mcp-client row mounts
  correctly from an agent-plane preset (vs the profile plane it was verified
  from) is recorded as untested until that session exists.

## 2026-10-15 — `agent-browser` added to both presets' personas

The machine already had **`agent-browser` 0.38.2** installed globally (global
npm package, binary `/usr/bin/agent-browser`) — a browser-automation CLI for
agents (`open`, `snapshot` with click/type `@refs`, `get text|html|title|url`,
`eval`, `screenshot`, CDP `connect`), found while answering whether a browser
tool was available. Nothing in the setup recorded it, and no harness tool
exposes it: it is plain CLI reached through the `bash` tool.

### What changed

- Persona suffix of both presets (`custom` = Productivity Mode, `coding`)
  now carries a **browser-access paragraph**: that the CLI exists, the main
  subcommands, when to reach for it (JS-rendered or interactive pages that
  `web_fetch` cannot handle), its built-in usage guide
  (`agent-browser skills get core --full`), and `agent-browser close` to
  release the session. The persona is the seam for this because the tool is
  a shell binary, not a mounted tool row — the same reason the
  `run_code`-composition instruction already lives there.
- Legacy sources edited, then re-frozen per the preset editing flow:
  `~/.dsh/.agent-presets/{custom,coding}/agent.cordis.yml` →
  `node /home/vrbkam/dsh-custom-presets/generate-patch.cjs`
  (patch rewritten, 687 lines) → repo copies re-synced
  (`agent-presets/*-agent.cordis.yml`, `prompts/*-persona.md`).

### Evidence

- Smoke test (before recording): `agent-browser open https://example.com` →
  launched a browser on the live display (`DISPLAY=:1`/`wayland-1`), returned
  `Example Domain`, `snapshot` gave the accessibility tree with refs,
  `close` released it.
- Regenerated patch greps 8 `agent-browser` mentions, 4 per preset, inside
  the `persona` config of both `preset-custom` and `preset-coding` rows.
- Verified before editing: live legacy files were byte-identical to the repo
  copies (`diff` clean both presets), so the repo record stayed in step.

### Not done

- No restart yet: the frozen patch composes at boot, so running sessions
  (including this one) still run without the paragraph; it takes effect on
  the next `dsh --profile web` restart.
- `verify.sh` is referenced by `README.md` but is absent from the repo —
  pre-existing gap, unrelated to this change, recorded here as noticed.

## 2026-10-14 — `dsh-secret-guard` installed (tool-call screening, step 1)

First line of defense of the tool-call screening initiative: a deterministic
gate that blocks the agent's file tools from touching sensitive files
(`.env`, credentials, key material) before they execute, and masks
secret-shaped values in tool results as a fallback — the "don't load API keys
into context" half of the screening goal. The semantic half (screening every
tool call through the local Cloudflare **clef-flash** decision model at
`127.0.0.1:8080/v1/systemone`) is planned next, candidate
`dsh-jev-interceptor` (market-listed, `provider: custom`); `dsh-decision-layer`
was evaluated first but rejected because it is **not** in the plugin market
(absent from `awesome-dsh-plugin.com/plugins.json` and `dsh.directory`).

### Install — from GitHub, deliberately not from npm

```sh
dsh plugin --profile web add github:JohnXu22786/secret-guard   # → dsh-secret-guard 0.1.0
```

Installed from the GitHub source the market entry links, **not** the npm
registry: npm's `dsh-secret-guard@0.1.1` is a *different* plugin by a
different author (`aazjzkskkw/dsh-secret-guard`, intercepts keys typed into
shell commands, not market-listed). Same package name, unrelated code —
running `dsh plugin add dsh-secret-guard` from npm would install the wrong
one. Recorded here so a future reinstall does not repeat that lookup.

Source was vetted before install: pure-TypeScript, zero-build, no lifecycle
scripts, MIT; `import type`-only use of `@deepseek-ai/dsh-tools`/`dsh-llm`
except one runtime import (`defineTool` in `src/inspect.ts`).

### Version exemption (peers pin 0.1.x, runtime is 0.2.0-rc.2)

First `add` was rejected: peers pin `@deepseek-ai/dsh-llm` /
`@deepseek-ai/dsh-tools` `^0.1.0-rc.6`, and the harness rolled the profile
back cleanly. Granted the exact-version exemption (`dsh plugin allow-version
dsh-secret-guard@0.1.0 --dsh-version 0.2.0-rc.2 --accept-risk`) after
verifying every seam the plugin touches is unchanged in 0.2.0-rc.2:

- `tools/pre-execute` / `tools/post-execute` event names — present (5 refs
  each across shipped plugins);
- `PreToolDecision` `kind: 'deny'` shape — present in `dsh-tools` typings;
- `ctx.tools.register(definition)` and `defineTool` — present, and the
  plugin's `dsh-tools` import resolves to the host's own 0.2.0-rc.2 copy.

### Verification

- Shipped test suite **77/77 pass** (run from a `/tmp` copy with the host's
  `@deepseek-ai/*` linked in; Node refuses type-stripping under
  `node_modules`, which is a test-harness limitation, not a plugin one — the
  dsh host loads `.ts` with its own loader).
- Default policy probe (real `PolicyEngine` from the installed copy):
  `~/.env` → block · `~/.ssh/id_ed25519` → block-read · `~/.aws/credentials`
  → block · `*.key` → block-read · workspace `README.md` → allow ·
  `.env.example` → allow (sensible exemption).
- **Known gap:** `/etc/shadow` (and other system credential files) are *not*
  covered by the default rules. Fixable with one custom rule in
  `cordis.patch.yml` config (`rules:`) or the hot-reloadable `rulesFile` —
  not yet added.
- **Not yet live:** the running `dsh web` host loads bundle layers at boot,
  so the gate activates at the next restart. No restart was performed (it
  would terminate the live session).

### Backup refreshed; drift recorded

`dsh-market/profile-backup.json` re-exported (strip verified: no `/home/`,
no username). The live profile had drifted from the 2026-10-02 record:
`@michengai/dsh-skills-manager`, `dsh-better-reasoning-effort` and
`mattpocock-skills-dsh` were added since, unrecorded — they appear in this
backup refresh and are noted in `dsh-market/README.md`, not given separate
entries. Counts: **14 dependencies, 17 bundles** (was 10/12).

## 2026-10-02 — language-server backends installed

`typescript-language-server` 6.0.0 and `pyright` 1.1.412, both **global npm**
installs (not pip, not pipx — one install path), alongside the already-present
`typescript` 6.0.3.

`dsh-lsp-actions` 0.5.6 was installed since 2026-09-20 but had almost nothing
to drive: the machine's only language servers were `rust-analyzer` and
`clangd`, so the `lsp_*` tools were mounted and inert for the languages this
checkout is written in. Now both are served.

Verified:

```
typescript-language-server  /usr/bin/typescript-language-server   6.0.0
pyright                     /usr/bin/pyright                      1.1.412
pyright-langserver          /usr/bin/pyright-langserver
tsserver                    /usr/bin/tsserver
```

No harness restart needed — LSP backends are discovered on PATH per call, so
they surface in the next session rather than on the next boot.

Recorded as **machine tooling** in the root README's new *Machine tooling*
section, with the install and verify commands. That section now carries the
table the deleted `DEPENDENCIES.md` used to: software outside the profile that
plugins depend on. Also recorded there as still missing: no DAP debug adapter
(`debugpy`, `dlv`, `codelldb`, `netcoredbg` all absent), so the debugger
surface has nothing to attach to.

## 2026-10-02 — search provider: `dsh-free-search` installed, engine set to Exa

Recorded 2026-10-02. Fills the gap left by the `dsh-search-failover` removal
earlier the same day.

### Chosen: `dsh-free-search`

Three candidates were compared on the `ctx.web` seam, the extension point the
removed plugin used. The harness ships only `dsh-web-search-deepseek`, and the
official `@deepseek-ai/dsh-web-search-exa` on npm is stale at `0.0.1-rc.1`
with peers pinned to ancient versions — not usable.

| | Chosen `dsh-free-search` 0.6.5 | `@tonydua/dsh-web-search-exa` 0.1.5 | `@yugasun/dsh-web-search` 0.2.5 |
| --- | --- | --- | --- |
| Engines | 18, Exa among them | Exa only | 5, Exa among them |
| Exa without a key | ✅ anonymous MCP | ✅ anonymous MCP | ❌ key required |
| Core package as a regular dep | `@deepseek-ai/schemastery` | none | none |
| Declares a harness range | `engines.dsh >=0.1.7-rc.1` | peers only, untested ≥0.1.8 | README claims 0.1.0-rc.7 |
| Last published | 2026-10-01 | 2026-08-15 | 2026-08-24 |
| Settings UI | ✅ | ❌ config via patch layer | ✅ |

Deciding factors: the most current of the three, a Settings UI, and Exa works
keyless. The `schemastery` regular dep was checked rather than assumed:
per the project's ground rule 2 record, `schemastery` is an inert
non-composition package — not in `CORE_MODULES` — and the profile already
hoists **3.18.4**, the exact version the plugin wants, so no second copy is
introduced. The package that actually bricked the harness was `dsh-tools`,
whose dual copies produced two different `Symbol("@deepseek-ai/dsh-tools.scheduler")`
keys. Verified after install: the profile still hoists only `cosmokit` and
`schemastery`, both 3.18.4, unchanged.

Set aside: `@tonydua/dsh-web-search-exa` — cleaner deps and the closest match
to "just Exa", but its own compat matrix stops at `0.1.7-alpha.1` and marks
`>=0.1.8` (which covers this host) as untested. `@yugasun/dsh-web-search` —
requires an Exa key.

### Install

```sh
PATH=/usr/bin:$PATH dsh plugin --profile web add dsh-free-search
```

Added `^0.6.5` to dependencies and the bundle list. **Resolved 0.6.5, not
0.6.6** — pnpm's fresh-release hold substituted an older version because
0.6.6 was published 2026-10-01, inside the hold window. Same mechanism the
market logged for `dsh-thinking-effort` on 2026-09-28.

### Engine pointed at Exa

The plugin's own bundle layer ships `provider: bing`, and the profile layer
applies after the bundle layer — so an override row in
`$DSH_HOME/profiles/web/cordis.patch.yml` selects the engine:

```yaml
- id: web-search-free
  config:
    provider: exa
    disabledEngines: []
    bingMarket: zh-CN
```

Every field the bundle row sets is restated, not just `provider`: patch
semantics replace a row's whole `config` (DSH 0.1.2+), so a one-field override
would silently drop the rest. `disabledEngines` and `bingMarket` are the
plugin's own defaults, restated verbatim.

Keyless by decision: the `exa` engine in the plugin's source calls
`resolveApiKey("EXA_API_KEY", "exaApiKey")` and falls back to the anonymous
`mcp.exa.ai/mcp` endpoint without one, switching to REST `api.exa.ai/search`
when a key appears. The user's Exa key is not currently wired — it still sits
in the dead `search-pool` block of `settings.yaml.imported` — so Exa runs on
the anonymous quota until they add it under Settings → Plugins → Free Search.

### What the plugin registers

Provider id **`ddg`** (line 2497 of `lib/index.js` — the loader entry is
`web-search-free`, the seam provider is `ddg`; the two are deliberately
different). Its patch also overrides the `web` row with
`searchProvider: ddg, fetchProvider: http`, and the code additionally takes
over at runtime when `searchProvider` is unset or still the factory default
`deepseek-official` — so search follows this plugin even if a patch layer
strip erased the row.

### Not yet active

The CLI install schedules no restart, and nothing in the market log shows a
hot-mount. **A `dsh --profile web` restart is required** for the bundle layer
to compose.

### Profile state after install

**10 dependencies / 12 bundles.** `dsh-market/profile-backup.json`
regenerated, `createdAt 2026-10-02T17:38:35.371Z`.
## 2026-10-02 — second sweep; `dsh-search-failover` removed

Recorded 2026-10-02 from the market log and the live files. Three dated
batches, a harness upgrade chain, and a settings migration that changed where
configuration lives.

### Settings moved into the profile patch layer

`~/.dsh/settings.yaml` is no longer read: the harness renamed it
`settings.yaml.imported` (2026-09-26 12:21) and its keys are now expressed as
**patch rows in `$DSH_HOME/profiles/web/cordis.patch.yml`** —
`agent-default-model`, `agent-preset-registry`, `locale`, `llm-pi-ai`,
`better-sidebar`.

The imported file still holds the old document verbatim, including the
`search-pool` block that belonged to `dsh-search-failover` — dead config now.

**Current live settings, read from the patch layer:** default model
`z-ai/glm-5.3-flash` on provider `openrouter-custom`, `reasoningEffort: high`;
default agent preset `custom`; locale `en`; and a two-model `openrouter-custom`
provider (`fireworks/ember-1`, `z-ai/glm-5.3-flash`) — down from the five
models and two providers the imported file records.

### Harness upgraded twice

`0.1.5-rc.2` → `0.1.7-rc.2` (visible in the 2026-09-28 compat warnings) →
**`0.2.0-rc.2`** (current).

### 2026-09-28 11:37–12:54 — thinking-effort installed then dropped

`dsh-thinking-effort` installed at 0.3.5, then toggled off and **uninstalled**
the same hour (`live-removed=true`) — gone from the profile.

### 2026-09-28 17:46 — the compat gate refused a bundle

`dsh-better-sidebar@0.24.1` update **refused before installing**: the release
declares `^0.2.0-rc.1` and the host was then `0.1.7-rc.2`. It succeeded once
the host reached 0.2.0-rc.2. A backup recorded on one release therefore does
not automatically apply on another.

### 2026-09-28 ~16:17–18:20 — presets migrated into a local plugin

DSH 0.1.7-rc.2 **stopped reading the legacy `$DSH_HOME/.agent-presets/<id>/`
directories**. The user authored `@local/dsh-custom-presets` at
`/home/vrbkam/dsh-custom-presets` and installed it as a bundle:

- `generate-patch.cjs` freezes the two legacy presets into a `cordis.patch.yml`
  declaring each as an `@deepseek-ai/dsh-agent-preset` row, with the plugin
  entry lists taken verbatim from the legacy `agent.cordis.yml` files.
- One substitution: `@deepseek-ai/dsh-workflow-worker-thread` (removed in
  0.1.7-rc.2) → `@deepseek-ai/dsh-workflow-ptc`, keeping
  `config.provider: spawn`.
- The `custom` preset was renamed **"Productivity Mode"**; its id stays
  `custom`, so the registry default keeps working.
- `agent-presets/generate-patch.cjs` in this repository is a copy of that
  generator — the legacy files here are the source it freezes from.

### 2026-10-02 17:24–17:26 — the sweep and the search-pool removal

| Plugin | 2026-09-23 | Now |
| --- | --- | --- |
| `@linxin666/dsh-client-ui-task-board` | 0.3.24 | **0.4.4** |
| `@vectorize-io/hindsight-coding-agents` | 0.6.1 | **0.8.0** |
| `dsh-better-sidebar` | 0.19.1 | **0.24.1** |
| `dsh-context` | 0.54.0 | **0.62.2** |
| `dsh-lsp-actions` | 0.5.3 | **0.5.6** |
| `dshmarket` | 1.51.0 | **1.66.8** |
| `@linxin666/dsh-client-ui-git-graph` | 0.3.20 | 0.3.20 (unchanged) |
| `dsh-subagent-workspace-ui` | 1.3.3 | 1.3.3 (updates blocked) |

and **`dsh-search-failover` uninstalled**:

```
17:25:19  toggle     dsh-search-failover: no loader entry matched
17:25:19  uninstall  dsh-search-failover exit=0 live-removed=false
```

`live-removed=false` with "no loader entry matched" — the plugin had already
stopped contributing a loader entry on this host. Reason, in the user's words:
this machine will use Exa directly, not a provider pool. **A replacement search
provider was not yet chosen.**

### Still blocked: `dsh-subagent-workspace-ui`

Attempts on 2026-09-28 (1.9.0) and 2026-10-02 (1.9.1) both failed on
`ERR_PNPM_UNUSED_PATCH` against the pinned 1.3.3 patch and rolled back. The
gap is now 1.3.3 → upstream 1.9.1.

### Verified unchanged

- Both agent presets byte-identical to `agent-presets/` — which matters more
  now, since they are the source the local plugin freezes from.
- The `ui-git-graph` disable is still in the patch layer.
- `patches/dsh-subagent-workspace-ui@1.3.3.patch` unchanged.
- `$DSH_HOME/AGENTS.md` and a home-level `$DSH_HOME/cordis.patch.yml` are
  still absent.
- Profile is **9 dependencies / 11 bundles**.
## 2026-09-20 — plugin sweep; `dsh-better-edit` removed

Recorded 2026-09-23 from `$DSH_HOME/profiles/web/.dsh-market/log.ndjson`, which
timestamps every action the market takes.

### Removed: `dsh-better-edit`

```
17:21:02  uninstall  dsh-better-edit exit=0 live-removed=true
```

Gone from `dependencies` **and** `dsh.profile.bundles`. Reason, in the user's
words: it did more harm than good.

It also took its hashline `read` / `write` / `edit` / `undo_last_edit` tools
with it. The stock tools are back, and file edits are now literal
`old_string` / `new_string` replacement rather than hash-anchored patches.

Leftovers it did not clean up:

- `$DSH_HOME/plugins/dsh-better-edit/` still exists — `config.yaml`, the
  `standard` / `code` / `minimal` / `cordis` prompt directories, and a
  `runtime/` tree of per-workspace hash stores. Nothing reads it now.
- `dsh-better-edit@0.8.1` is still listed under `minimumReleaseAgeExclude` in
  `pnpm-workspace.yaml`.

### Upgraded

All within the same 17:20–17:22Z window:

| Plugin | From | To |
| --- | --- | --- |
| `dshmarket` | 1.45.1 | **1.51.0** |
| `@hytime/dsh-thinking-effort` | 0.2.4 | **0.3.1** |
| `@linxin666/dsh-client-ui-task-board` | 0.3.20 | **0.3.24** |
| `@vectorize-io/hindsight-coding-agents` | 0.5.4 | **0.6.1** |
| `dsh-context` | 0.49.4 | **0.54.0** |
| `dsh-lsp-actions` | 0.5.0 | **0.5.3** |

### Failed again: `dsh-subagent-workspace-ui`

```
17:22:04  update-rollback  dsh-subagent-workspace-ui: restored npm build v1.3.3
17:22:04  warn             dsh-subagent-workspace-ui: failed update command; previous build restored and verified
17:22:04  error            dsh-subagent-workspace-ui -> 1.4.0 exit=1
                           err=ERR_PNPM_UNUSED_PATCH: The following patches were not used: dsh-subagent-workspace-ui@1.3.3
```

The same failure as the 1.3.4 attempt on 2026-09-11: the English-labels patch
is pinned to 1.3.3, so no other version installs under it. Upstream is now
1.6.0. See *Known constraints* in the root README.

### Also changed

- **Harness upgraded** — `@deepseek-ai/dsh` 0.1.5-rc.1 → **0.1.5-rc.2**. Not in
  the market log; observed from `dsh --version`.
- **`settings.yaml` gained a second provider**, `alibaba-qwencloud`
  (`apiKeyEnv: ALIBABA_QWENCLOUD_API_KEY`, the Alibaba MaaS compatible-mode
  endpoint, models `qwen3.8-max` and `deepseek-v4.1-flash`), plus two more
  models on `openrouter-custom`: `stealth/union-alpha` and
  `xiaomi/mimo-v2.6-pro`.
- **Default model moved back** to `deepseek/deepseek-v4.1-flash` on
  `openrouter-custom`, having been `z-ai/glm-5.3-flash` since 2026-09-13.

### Stale `minimumReleaseAgeExclude` entries

Left as-is — this repository records the live profile, it does not edit it.
Three entries no longer match an installed version:

- `dsh-better-edit@0.8.1` — the plugin is uninstalled.
- `@hytime/dsh-thinking-effort@0.2.4` — 0.3.1 is installed.
- `@vectorize-io/hindsight-coding-agents@0.5.3 || 0.5.4` — 0.6.1 is installed,
  and 0.6.1 is not exempt.

### Verified unchanged

- Both agent presets byte-identical to `agent-presets/`; the `prompts/`
  extraction still round-trips against the live YAML.
- The `ui-git-graph` disable in `cordis.patch.yml` is still in place.
- `patches/dsh-subagent-workspace-ui@1.3.3.patch` unchanged.
- `$DSH_HOME/AGENTS.md` and `$DSH_HOME/cordis.patch.yml` still absent.

## 2026-09-23 — version currency sweep

`npm view <name> version` against the ten installed profile plugins. **Five have
newer releases; none are installed.**

| Plugin | Installed | npm latest |
| --- | --- | --- |
| `@hytime/dsh-thinking-effort` | 0.3.1 | 0.3.2 |
| `@linxin666/dsh-client-ui-git-graph` | 0.3.20 | 0.3.24 |
| `@linxin666/dsh-client-ui-task-board` | 0.3.24 | 0.3.24 |
| `@vectorize-io/hindsight-coding-agents` | 0.6.1 | 0.6.1 |
| `dsh-better-sidebar` | 0.19.1 | 0.19.1 |
| `dsh-context` | 0.54.0 | 0.55.0 |
| `dsh-lsp-actions` | 0.5.3 | 0.5.4 |
| `dsh-search-failover` | 0.3.9 | 0.3.9 |
| `dsh-subagent-workspace-ui` | 1.3.3 | 1.6.0 |
| `dshmarket` | 1.51.0 | 1.58.0 |

## 2026-09-13 — record refreshed against the live setup

Diffed the live machine against the 2026-09-11 capture (`50d8262`). Two
changes; everything else byte-identical.

### Fixed: `ui-git-graph` disabled in the profile patch layer

`$DSH_HOME/profiles/web/cordis.patch.yml` gained:

```yaml
- id: ui-git-graph
  disabled: true
```

The plugin `@linxin666/dsh-client-ui-git-graph@0.3.20` stays in both
`dependencies` and `dsh.profile.bundles` — only its loader row is switched
off, so the code stays installed but is never mounted.

Reason, from the comment written into the file itself and dated 2026-09-11:
the plugin polls every 30 s — several git spawns per tick, even for workspaces
that are not git repositories, each through a `systemd-run` scope — and a
`git status` round can stall up to `STATUS_TIMEOUT_MS` (15 s). Its
auto-isolation hook is already disabled by the current `dsh`
workspaces-service shape, so it was adding poll churn without its main
feature. It was switched off while investigating a slow workspace list at
boot. **Re-enable by deleting the entry** — the file says so in place.

### Changed: default model

`$DSH_HOME/settings.yaml` → `agent-default-model.model` moved from
`deepseek/deepseek-v4.1-flash` to **`z-ai/glm-5.3-flash`**. Provider
(`openrouter-custom`) and `reasoningEffort` (`high`) are unchanged, and all
three models remain declared in the `llm-pi-ai` provider block, so this is a
default switch rather than a provider change.

`settings.yaml` is not reproduced in this repository — it holds API keys — so
only the fact is recorded, in the root README's setup table.

### Verified unchanged

- Harness `@deepseek-ai/dsh` **0.1.5-rc.1**.
- **11 dependencies, 13 ordered bundles**; every installed plugin version
  identical to the 2026-09-11 record.
- Both agent presets (`custom`, `coding`) byte-identical to `agent-presets/`
  (`diff -q` clean), and the `prompts/` extraction still round-trips against
  the live YAML.
- `$DSH_HOME/AGENTS.md` and `$DSH_HOME/cordis.patch.yml` still absent.
- `dsh-market/profile-backup.json` regenerated: the only `files[]` entry that
  differs from the 2026-09-11 copy is `cordis.patch.yml`.

## 2026-09-13 — version currency sweep

`npm view <name> version` against every installed profile plugin. **Seven have
newer releases; none are installed.**

| Plugin | Installed | npm latest |
| --- | --- | --- |
| `@hytime/dsh-thinking-effort` | 0.2.4 | 0.2.4 |
| `@linxin666/dsh-client-ui-git-graph` | 0.3.20 | 0.3.22 |
| `@linxin666/dsh-client-ui-task-board` | 0.3.20 | 0.3.22 |
| `@vectorize-io/hindsight-coding-agents` | 0.5.4 | 0.6.0 |
| `dsh-better-edit` | 0.8.1 | 0.8.1 |
| `dsh-better-sidebar` | 0.19.1 | 0.19.1 |
| `dsh-context` | 0.49.4 | 0.51.1 |
| `dsh-lsp-actions` | 0.5.0 | 0.5.1 |
| `dsh-search-failover` | 0.3.9 | 0.3.9 |
| `dsh-subagent-workspace-ui` | 1.3.3 | 1.4.0 |
| `dshmarket` | 1.45.1 | 1.46.1 |

### Known blocker: `dsh-subagent-workspace-ui` upgrade

A market upgrade of this plugin on 2026-09-11T13:08Z failed and rolled itself
back:

```
info   update-rollback  dsh-subagent-workspace-ui: restored npm build v1.3.3
warn   update           dsh-subagent-workspace-ui: failed update command; previous build restored and verified
error  update           dsh-subagent-workspace-ui -> dsh-subagent-workspace-ui@1.3.4 exit=1
                        err=ERR_PNPM_UNUSED_PATCH: The following patches were not used: dsh-subagent-workspace-ui@1.3.3
```

The profile patches this plugin's client bundle to translate its hardcoded
Simplified-Chinese UI strings to English. The patch is pinned to 1.3.3, so pnpm
refuses to install any other version under it. **Upgrading means re-deriving
`patches/dsh-subagent-workspace-ui@<version>.patch` from the new
`lib/client.js` first** — the same instruction is in `pnpm-workspace.yaml`
beside the pin.

## 2026-09-11 — baseline

The repository replaced its former plugin-reproduction kit with this record, at
commit `50d8262` (pushed the same day). Captured: the `web` profile backup (11
dependencies, 13 bundles, profile config, and the pinned
`dsh-subagent-workspace-ui@1.3.3` patch), the `custom` and `coding` agent
presets verbatim, and the persona and plan-mode prompts extracted from them.
