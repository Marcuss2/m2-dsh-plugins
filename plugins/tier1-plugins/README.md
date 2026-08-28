# tier1-plugins — coding-agent capability pack (DAP debugger, LSP, checkpoints, fallbacks, web/AST)

## What it is and why

Five community profile-bundle plugins plus four MCP servers that close the
highest-value feature gaps between this DeepSeek Harness setup and the
oh-my-pi (omp) coding agent (gap analysis: `.research/oh-my-pi-gaps.md`,
plugin research: `.research/tier1-plugin-research.md`). Python eval kernels
were intentionally **not** included — the built-in `ptc` covers that.

| Piece | Feature closed | Source |
|---|---|---|
| `dsh-debugger-dap` | DAP debugger tool (launch/attach, breakpoints, stepping, stack/variables) — a port of omp's DAP design | npm, MIT, publisher `master0071` |
| `dsh-lsp-actions` | LSP action surface: diagnostics, formatting, completion, code actions, symbols, signature help, inlay hints, rename | npm, PerryLink/dsh-lsp-actions |
| `dsh-checkpoint-rewind` | `/checkpoint` + `/rewind`: session+workspace+config snapshots, timeline UI, one-shot rollback | npm, PerryLink/dsh-checkpoint-rewind |
| `dsh-llm-fallbacks` | Automatic provider/model fallback chains on retry-exhausted/auth/quota/rate-limit | npm, omdsh-dev/dsh-llm-fallbacks |
| `dsh-search-failover` | Provider pool for the *native* `web_search` tool: DDG/SearXNG/Brave/Tavily/Exa/Jina/Firecrawl/Serper/SerpApi with quota-aware circuit breaking (patches the `dsh-base` layer) | npm, Walvez/dsh-search-failover |
| MCP `ast-grep` | Structural code search + preview-gated rewrites (ast-grep) | npm `ast-grep-mcp` (spiritledsoftware wrapper, self-contained `@ast-grep/cli` binary) |
| MCP `ddg-search` | Keyless web search (DuckDuckGo): search, search_and_crawl, research, fetch | npm `mcp-duckduckgo` |
| MCP `web-fetch` | URL → clean markdown via Mozilla Readability (official reference server) | PyPI `mcp-server-fetch` via `uvx` |
| MCP `markitdown` | PDF/DOCX/PPTX/XLSX → structured markdown (best free option for arXiv PDFs) | PyPI `markitdown-mcp` via `uvx` (thin MCP wrapper around Microsoft `markitdown`) |

## Dependencies

- `nodejs-npm` (baseline; `npx` spawns the two npm MCP servers).
- `uv` — required for the two `uvx` MCP servers (`mcp-server-fetch`,
  `markitdown-mcp`); see `DEPENDENCIES.md` → `uv`.
- Language servers and debug adapters are NOT installed by this entry;
  install per language as needed (e.g. `typescript-language-server`,
  `pyright`/`pylsp` for LSP; `pip install debugpy`, `dlv`, `lldb-dap` for
  debugging). `dsh-lsp-actions` and `dsh-debugger-dap` expose what is found.
- Requires a **restart of the DSH web profile** after install (profile
  bundles and patch rows load at boot).

## Install steps (baseline install)

1. Install machine dependencies first (`DEPENDENCIES.md`), including `uv` **and**
   the `pnpm-build-approval` row: pnpm 10+ skips dependency build scripts unless
   approved, so the two npm MCP servers would install without their binaries.

2. Install the five plugins **in one batched command** — one resolution pass and
   one atomic `package.json` write. Never install in parallel: two concurrent
   `pnpm add` processes in the profile both exit 0 while the last writer wins,
   silently dropping the other's dependency *and* its bundle entry.

   ```sh
   dsh plugin --profile web add \
     dsh-debugger-dap dsh-lsp-actions dsh-checkpoint-rewind \
     dsh-llm-fallbacks dsh-search-failover
   ```

   Versions recorded when this entry was authored (2026-08-26):
   dsh-debugger-dap 0.1.8 · dsh-lsp-actions 0.3.4 · dsh-checkpoint-rewind
   0.5.5 (spec `^0.5.5`) · dsh-llm-fallbacks 0.3.4 (spec `^0.3.4`) ·
   dsh-search-failover 0.3.9. What is installed right now lives in
   `../../setup/versions.txt`; `setup/verify.sh --record` rewrites it and
   `setup/verify.sh` reports drift.

   The resulting `$DSH_HOME/profiles/web/package.json` must list all five in
   both `dependencies` and `dsh.profile.bundles` (after the existing
   `dshmarket` / `dsh-better-edit` / `@vectorize-io/hindsight-coding-agents`
   entries):

   ```json
   "dsh": {
     "profile": {
       "bundles": [
         "@deepseek-ai/dsh-base",
         "@deepseek-ai/dsh-web-app",
         "dshmarket",
         "dsh-better-edit",
         "@vectorize-io/hindsight-coding-agents",
         "dsh-checkpoint-rewind",
         "dsh-debugger-dap",
         "dsh-llm-fallbacks",
         "dsh-lsp-actions",
         "dsh-search-failover"
       ]
     }
   }
   ```

3. Install the two **npm** MCP servers as profile dependencies and let their
   build scripts run, so no row depends on the `npx` cache at all:

   ```sh
   cd "$DSH_HOME/profiles/web" && pnpm add ast-grep-mcp mcp-duckduckgo
   pnpm install          # prints [ERR_PNPM_IGNORED_BUILDS] the first time
   ```

   That error is the hint, not a failure: pnpm has written an `allowBuilds:` stub
   into `pnpm-workspace.yaml` with `set this to true or false` placeholders. Set
   both to `true` and install again (~30 s, ~60 MB downloaded):

   ```yaml
   allowBuilds:
     '@ast-grep/cli': true
     mcp-duckduckgo: true
   ```

   Use plain `pnpm add` here, **not** `dsh plugin add`: these are tool binaries,
   not dsh bundles, and must not appear in `dsh.profile.bundles`. After the
   second install `node_modules/@ast-grep/cli/ast-grep` (~52 MB) and
   `node_modules/mcp-duckduckgo/bin/duckduckgo-mcp` (~8.9 MB) must exist.

4. Add the MCP rows to `$DSH_HOME/profiles/web/cordis.patch.yml` from
   `cordis.patch.yml.example` in this directory — do not retype them; one wrong
   indent mounts zero tools without any error:

   ```sh
   T="$DSH_HOME/profiles/web/cordis.patch.yml"
   sed "s|__PROFILE__|$DSH_HOME/profiles/web|g" cordis.patch.yml.example > /tmp/mcp.yml
   sed -i '/^\[\]$/d' "$T" && cat /tmp/mcp.yml >> "$T"
   ```

   (A pristine target is comments plus `[]`, which the `sed` removes; if the file
   already holds your own rows, drop the `sed` and append.) The two npm rows point
   at the profile's own `node_modules/.bin/`, and the ast-grep row additionally
   passes `env: AST_GREP_BIN: <profile>/node_modules/@ast-grep/cli/ast-grep`:
   the wrapper resolves its binary from `AST_GREP_BIN`, then `PATH`, then
   `<pkg>/node_modules/.bin/ast-grep` — and under pnpm's hoisted layout that last
   path does not exist, so without the env var the server answers
   `binary_resolution_failed`. The two `uvx` rows need nothing similar.

   Tool names exposed to agents: `mcp__ast-grep__*`, `mcp__ddg-search__*`,
   `mcp__web-fetch__*`, `mcp__markitdown__*`.

5. Restart the DSH web profile (close and relaunch `dsh web` / the desktop app)
   so the bundle layers mount. The patch file is watched, so the four MCP rows
   respawn within seconds of step 4 without a restart.

6. Verify: `../../setup/verify.sh --full` (deps, layers, rows, built binaries,
   shadowing guard, plus a raw JSON-RPC `initialize` per server). Then in a NEW
   session, call one tool from each.

## Field notes from the 2026-08-28 restore

Applied on a fresh baseline install with `dsh` 0.1.1-rc.2 / node 26.8.1. Two
upstream drifts and one reload behavior were found; the install steps above
already reflect the corrections.

- **Installed versions** (pnpm resolves `latest`, so these drift from the
  authoring record above): dsh-better-edit 0.4.1 ·
  @vectorize-io/hindsight-coding-agents 0.4.3 · dsh-checkpoint-rewind 0.6.0 ·
  dsh-debugger-dap 0.1.8 · dsh-llm-fallbacks 0.3.5 ·
  dsh-lsp-actions 0.3.4 · dsh-search-failover 0.3.9. All registered
  correctly in `dependencies` **and** `dsh.profile.bundles`.
- **Second restore the same day (fresh `$DSH_HOME`, dsh 0.1.1-rc.2 / node
  26.8.1)** resolved two versions higher: dsh-checkpoint-rewind **0.6.1** and
  dsh-lsp-actions **0.4.0**; the rest were unchanged. Every bundle layer again
  landed in both `dependencies` and `dsh.profile.bundles`, and
  `--dump-config` showed a layer per plugin with sane defaults (the
  `search-pool` row hooks the `@deepseek-ai/dsh-base` layer as documented).
  Treat the version numbers as a snapshot, not a pin.
- **Correction to an earlier note here.** `mcp-duckduckgo`'s missing native
  binary was blamed on the `npx` cache install "leaving it out". It was not an
  npx quirk: **pnpm 10+ does not run dependency build scripts unless approved**,
  and only prints `[ERR_PNPM_IGNORED_BUILDS] Ignored build scripts:
  @ast-grep/cli@0.43.0, mcp-duckduckgo@3.1.0` — the install still exits 0, so the
  package lands without `bin/duckduckgo-mcp` and dies at startup with
  `Binary not found. Please reinstall the package.`, mounting zero tools. Same
  mechanism, same silent failure, for `@ast-grep/cli`. Durable fix (step 3): own
  the two servers as **profile** dependencies, approve their builds in
  `pnpm-workspace.yaml` (`allowBuilds`), and point the rows at the profile
  `.bin`. The old manual workaround (`node install.js` inside the npx cache) does
  clear the symptom but leaves it one cache eviction away from returning, and is
  no longer the recorded path.
- **`pnpm peers check` in the profile prints conflicting/missing peer
  warnings** (`@deepseek-ai/dsh-commands`, `-llm`, `-settings`) for
  `dsh-checkpoint-rewind`, `dsh-lsp-actions`, `dsh-llm-fallbacks` and
  `dsh-search-failover` against dsh 0.1.1-rc.2. They are advisory: the layers
  mount and dump-config composes fine. Worth re-checking after a DSH upgrade.
- **`dshmarket` is installed first, before this pack** — see `../dshmarket/`
  for what it is and why it leads the order. It is not part of this entry; the
  snippet above is the full bundle list with it in its first custom slot. After a
  restart its **Settings → Plugin Market** panel is the human (or browser-driven)
  alternative to `dsh plugin add`: on this machine it rendered Discover / Themes /
  Installed / Advanced / Tasks tabs and counted the installed bundles correctly,
  so market-driven installs work — but the market writes the same
  `package.json`, so never run it while a CLI install is in flight.
- **`uvx markitdown[mcp]` is dead**: `markitdown` 0.1.7 has no `mcp` extra, so
  uvx silently falls back to the plain conversion CLI, which is not an MCP
  server (no tools mount, no error). The working spec is
  `uvx --from markitdown-mcp markitdown-mcp` (PyPI `markitdown-mcp` 0.0.1a4,
  which pins `markitdown[all]`). Confirmed with a raw JSON-RPC
  `initialize` probe over stdio, which answered
  `serverInfo: {"name":"markitdown"}`.
- **Reload behavior:** the profile's `cordis.patch.yml` is watched — editing it
  made the running host spawn the MCP servers within seconds, no restart. The
  npm **bundle** layers (the profile plugins) are composed at boot: they need a
  real restart, and an already-running session keeps its stock tools either
  way. On the second restore the four MCP rows were live in the *same* session
  that wrote the file — all four verified functionally
  (`mcp__ast-grep__ast_grep_version` → `ast-grep 0.43.0`,
  `mcp__ddg-search__search` → live results, `mcp__web-fetch__fetch` → markdown,
  `mcp__markitdown__convert_to_markdown` on a `.txt` → markdown), and
  `ps` showed the `uvx mcp-server-fetch` / `uvx --from markitdown-mcp
  markitdown-mcp` / `duckduckgo-mcp` children under the running host.

Run `setup/verify.sh --full` from the kit root: it checks one `# == <name>`
layer per plugin, the four `mcp-*` rows, that both npm MCP binaries exist and are
executable, that no `@deepseek-ai/*` core module is hoisted into the profile, and
answers a raw JSON-RPC `initialize` on each of the four servers — no session
needed for any of that.

Then, in a NEW session after a restart: `debug`, LSP action tools, and the
checkpoint tool are registered; `mcp__ast-grep__*`, `mcp__ddg-search__*`,
`mcp__web-fetch__*`, `mcp__markitdown__*` appear and answer; `web_search` works
without a DeepSeek API key once dsh-search-failover has at least one keyless
backend (DDG/SearXNG).

## Rollback

```sh
dsh plugin --profile web remove dsh-debugger-dap dsh-lsp-actions \
  dsh-checkpoint-rewind dsh-llm-fallbacks dsh-search-failover
cd "$DSH_HOME/profiles/web" && pnpm remove ast-grep-mcp mcp-duckduckgo
```

then delete the `- insert:` block in `cordis.patch.yml` (the watched file
reloads it without a restart), drop the two `allowBuilds:` entries pnpm added,
and restart to unmount the bundle layers.

## Caveats

- All five plugins are young third-party community packages (created within
  three weeks of this writing, mostly single authors). Review their source
- The profile installs with pnpm's **`nodeLinker: hoisted`**, so a plugin's own
  dependencies land inside the profile. One that declares `@deepseek-ai/*` core
  packages as regular dependencies shadows the installation and breaks tool
  dispatch harness-wide — see RESTORE.md, Step 4, and `setup/verify.sh`
  section 4. Check `dependencies` vs `peerDependencies` before installing any
  new bundle.
  process with full access.
- `dsh-debugger-dap` was v0.1.x at install time; its `disassemble` /
  `read_memory` actions were not verified end-to-end. Debug adapters must be
  installed separately per language.
- `dsh-search-failover` contributes a patch to the `@deepseek-ai/dsh-base`
  layer (it hooks the native web seam); keep it updated together with DSH.
- The `markitdown` uvx package pulls Microsoft markitdown plus extras on
  first run; `mcp-server-fetch` honors robots.txt.
- MCP servers mounted at the profile level inherit the harness launch
  directory as cwd; ast-grep path scoping follows that directory.
