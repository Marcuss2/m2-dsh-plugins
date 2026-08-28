# Tier-1 feature plugin research — closing the oh-my-pi gaps

Date: 2026-08-26. Companion to `.research/oh-my-pi-gaps.md`.

Scope: for each of the 10 tier-1 features omp has and DSH lacks, find existing
plugins / MCP servers / libraries / borrowable source to implement it without
building from scratch. All versions and dates were verified live against the
npm registry and GitHub on the research date (do not trust cached knowledge).

**Headline finding:** the DSH community ecosystem (`dsh-plugin` GitHub topic,
~11.7k repos; curated list `awesome-dsh-plugin/awesome-dsh-plugin` ★12.9k,
saved at `.research/awesome-dsh-plugin.md`) has **already ported several of
omp's headline features as native Cordis plugins** — DAP debugging, LSP
actions, checkpoint/rewind, LLM fallback chains, web-search failover, git
worktree isolation. MCP servers plug in drop-in via the shipped
`@deepseek-ai/dsh-mcp-client` plugin. Only **Advisor** and **TTSR** have no
off-the-shelf solution anywhere.

## Verified MCP client row format (use this shape)

From the shipped `dsh-mcp-client` README — one row per server, tools exposed
as `mcp__<serverName>__<tool>`:

```yaml
- id: mcp-<name>
  name: '@deepseek-ai/dsh-mcp-client'
  config:
    serverName: <name>          # [A-Za-z0-9_-]{1,32}, unique per live instance
    transport: stdio             # or streamable-http (then: url, headers)
    command: npx                 # executable to spawn
    args: ['-y', '<package>']
    env: { KEY: value }          # optional
    # toolCallTimeoutMs, reconnect.*, failOnStartupError optional
```

---

## 1. LSP integration

**Top pick (native): `dsh-lsp-actions` v0.3.4** — PerryLink/dsh-lsp-actions
(npm; created 2026-08-15, published 2026-08-23). "LSP action surface for DSH:
diagnostics, formatting, completion, code actions, symbols, signature help,
inlay hints and rename tools over language servers, plus the editor action
protocol (lsp.actions.*)". Install: `dsh plugin add dsh-lsp-actions`.
Caveats: young; verify it covers your language servers and whether it speaks
`workspace/willRenameFiles` (its description suggests symbol rename only).

**MCP candidates** (any of these is one `dsh-mcp-client` row):

| Candidate | Surface | Health | Notes |
|---|---|---|---|
| **isaacphi/mcp-language-server** ✅ primary | definition, references, diagnostics, hover, rename_symbol, edit_file (6 tools) | ★1,586, BSD-3, pushed 2026-03 | Go binary (`go install …@latest`); one instance per language/workspace |
| **LoganBresnahan/pharos-mcp** (power user) | 53 tools incl. call/type hierarchy, rename_preview, code actions, `lsp_request_raw` escape hatch | ★4, Apache-2.0, pushed 2026-08-12, benchmarked | Gleam/Erlang binary via npm; filter tools to avoid context bloat |
| **@theupsider/lsp-mcp** (zero-config) | 13 tools incl. rename, code_action, formatting | ★3, published 2026-07-26 | `npx -y @theupsider/lsp-mcp@latest`, auto-detects 13 languages |
| ProfessioneIT/lsp-mcp-server | 29 tools, safe rename preview | ★20, MIT, 2026-06 | needs clone+build |
| ❌ Tritlo/lsp-mcp, SteelPhase/mcp-lsp-server, @mizchi/lsmcp | — | stale/incomplete | rejected |

**Gap vs omp:** no MCP server exposes `workspace/willRenameFiles` (file
rename with semantic import updates). omp reference:
`.research/oh-my-pi/packages/coding-agent/src/lsp/tool.ts` (1,503 lines, 14
actions, 40+ built-in server definitions in `defaults.json`, multi-server
mux). Full parity path: native Cordis plugin over `vscode-languageserver-protocol`
v3.18.2 + `vscode-jsonrpc` v9.0.1, or port omp's lsp module.

---

## 2. DAP debugger

**Top pick (native): `dsh-debugger-dap` v0.1.8** (npm, MIT, created
2026-08-20, published 2026-08-25; explicitly a port of omp's DAP design).
One model-facing `debug` tool with **41 actions** (superset of omp's 28):
launch/attach, breakpoints (line/function/exception/data), stepping incl.
reverse, evaluate, set_variable, threads/stack/scopes/variables, watch,
disassemble, read_memory, completions, ledger. Built-in adapter recipes:
debugpy, dlv, netcoredbg, lldb-dap, codelldb; custom stdio/TCP adapters via
config. Install: `dsh plugin init debugger && dsh plugin add --profile debugger dsh-debugger-dap`
(or plain `dsh plugin add`).
Caveats: 5 days old at research time, no public repo linked, docs in Chinese;
pin version and verify `disassemble`/`read_memory` against a real adapter
(debugpy is easiest: `pip install debugpy`).

**Complement (MCP): `@debugmcp/mcp-debugger` v0.24.2** — ★159, MIT, pushed
2026-08-26, OpenSSF badges. 28 tools; languages: Python (debugpy), JS/TS
(js-debug), Ruby (rdbg), Rust/C/C++ (CodeLLDB), Go (Delve), Java (JDI),
.NET (netcoredbg); extras: logpoints, IDE mirror (`expose_session`), k8s
sidecar flow. Run: `npx @debugmcp/mcp-debugger stdio` → one `dsh-mcp-client`
row (`serverName: debugger`).

Rejected: microsoft/DebugMCP (requires a running VS Code),
@bloopai/debugger-mcp (stale 14 months), cmsis-dap-mcp (hardware protocol),
breakpoint-mcp (Godot-only).

**Adapter provisioning** is orthogonal: lldb-dap (LLVM), `dlv dap`,
`python -m debugpy.adapter`, `gdb -i dap`, netcoredbg all speak stdio DAP;
js-debug is TCP-only and not on npm (extract from GitHub releases).

**omp reference:** `.research/oh-my-pi/packages/coding-agent/src/dap/` (~4,020
LOC: client.ts transport/framing, session.ts lifecycle/child sessions,
config.ts adapter resolution, defaults.json 14 recipes) + `src/tools/debug.ts`.

---

## 3. Advisor / watchdog

**No off-the-shelf solution exists** (npm + GitHub scanned; only offline
LLM-judge packages). Full assessment in
`.research/advisor-ttsr-checkpoint-assessment.md`.

- omp reference: `.research/oh-my-pi/packages/coding-agent/src/advisor/` —
  delta-based transcript feed to an isolated advisor ToolSession, severity-routed
  `advise` tool (nit/concern/blocker), emission guard (dedupe/rate-limit),
  JSONL persistence, WATCHDOG.yml roster.
- DSH path: shipped-plugin-level work (`@deepseek-ai/dsh-advisor`), hooking
  `session/event`, `ctx.agents.create`, `agent.steer/inject/followup`.
  Complexity L. Not viable as a dynamic plugin (needs durable sub-agent +
  persistence).
- **Ecosystem stepping stones (verified, usable today):**
  - `dsh-auto-review` v0.7.0 (PerryLink, npm, published 2026-08-26) —
    second-model read-only reviewer subagent on the **approval** answerer
    chain with fail-closed fallback and audit log. Same "second model judges"
    pattern, different hook point.
  - `dsh-approval-llm` (Letter2025) — reviewer model as approval answerer.
  - `hezhongtang/dsh-capability-optimizer` — headless Claude Code
    consultations with advisor/reviewer/designer roles.
  - `TaurenMountain/dsh-llm-as-a-verifier` — logprob-based verification.

---

## 4. Model routing depth (roles + fallback chains)

**Top pick (native, installable today): `dsh-llm-fallbacks` v0.3.5** —
omdsh-dev/dsh-llm-fallbacks (npm; created 2026-08-13, published 2026-08-26).
"Automatic provider/model fallback chains for DeepSeek Harness agents when
LLM requests keep failing (retry exhausted, auth, quota, rate limit)."
Install: `dsh plugin add dsh-llm-fallbacks`.

Alternatives/additions:
- `dsh-llm-failover` v0.3.0 (HB00) — provider failover on rate limit/quota
  with configurable per-provider models.
- Role routers (GitHub-only, verify before use): BruceLanLan/dsh-tier-router
  (strong tier plans/advises/reviews, cheap tier implements),
  SnowAmberX/dsh-role-router (default/planner/subagent),
  wenheguo2/dsh-delegation-suite (role-based subagent routing with failover),
  CypherNaught-0x/DSH-Subagent-Model-Router,
  SeverusZh/dsh-plugin-subagent-director, dingminhua/dsh-subagent-default-model,
  llmpolska/oh-my-dsh (tiered routing + vision delegation).
- Subagent model pickers: ringoage/dsh-subagent-model-picker (GUI seat).

**External gateways** (point a `dsh-llm-pi-ai` profile `baseURL` at them):
- **Portkey AI Gateway** — `@portkey-ai/gateway` v1.15.2, MIT, Node.js,
  12.8k★. Fallback chains, load balancing, caching; `npx @portkey-ai/gateway`
  sidecar. Best fit (same runtime, MIT).
- **LiteLLM** — PyPI v1.98.0 (2026-08-22), 57.3k★. Richest features:
  fallback maps, routing strategies, virtual keys with budgets, cooldowns,
  key rotation. Python sidecar; OpenAI-compatible.
- OpenRouter: already consumable as a provider route; server-side
  `automatic_fallbacks`, not self-hostable. RouteLLM: stale (2024), rejected.

**Custom plugin feasibility: YES, no core changes.** Hook `agent/request`
(rewrite provider/model by role; `purpose` field already classifies calls) +
`agent/request-error` waterfall (fallback traversal, cooldown suppression) —
the same waterfall `dsh-llm-retry` uses; composes cleanly with it
(retry = same model, fallback = different model).

**omp reference config shape** (`model-roles.ts`/`settings-schema.ts`):
roles default/smol/slow/vision/plan/designer/commit/tiny/task/advisor;
`retry.fallbackChains` keyed by role, `provider/model-id`, or `provider/*`
wildcard; `fallbackRevertPolicy: cooldown-expiry | never`.

---

## 5. Time-traveling stream rules (TTSR)

**Nothing exists anywhere** — no plugin, library, or MCP in DSH, npm, or
GitHub (scanned Aug 2026). This is omp's most novel mechanism.

- omp reference: `.research/oh-my-pi/packages/coding-agent/src/session/ttsr-coordinator.ts`
  — synchronous `agent.abort()` on regex match of the live stream → 50 ms
  delayed retry guarded by (token, generation, abort-state, target-message) →
  `agent.replaceMessages(...slice)` + hidden `custom_message` rule injection →
  `agent.continue()`. Non-interrupting matches prepend `<system-reminder>` to
  tool results via `afterToolCall`. Per-rule turn-count repeat policy;
  injections survive compaction.
- DSH feasibility: needs a **shipped plugin plus two small `dsh-agent-loop`
  seam additions** (`agent/replace-partial`, `agent/continue-from`) — without
  them, faithful retry-from-same-point is impossible. Observation is already
  proven feasible from community plugins: `dsh-sseye` v0.4.1 (jhuanxx44, npm)
  captures every model call "at the llm/stream waterfall", and
  WM-CODER/custom-first-control-prompt mentions "stream intercept" injection.
  Complexity: L (coordinator) + S–M (seam). Details in
  `.research/advisor-ttsr-checkpoint-assessment.md`.

---

## 6. Subagent workspace isolation

**Finding:** native git-worktree isolation plugins existed on npm at research
time (first published 2026-08-25). Nothing from this gap is installed in this
setup — the install list is `../plugins/README.md`.

Alternatives:
- `dsh-task-worktree` v0.4.1 (Letter2025, npm) — task-scoped worktrees,
  durable per-repo manifest, auto-creation instruction on first message.
- JohnXu22786/worktree-mgr (GitHub) — full create/sync/finish lifecycle,
  double-checked merge targets, batch cleanup.
- february2015/dsh-taskswarm — dependency-ordered waves in parallel
  worktree lanes with cross-model review and crash recovery.
- Web0926/dsh-llm-verifier — runs N agent candidates in detached worktrees,
  validates patches, ranks passing candidates (worktree + verification combo).
- Palaiologos1453/dsh-worktree-studio, alpacachen/dsh-worktree (minimal UI).

**DSH seam status:** `dsh-subagent` already has `resolveChildCwd(prefix,
configured, parentCwd)` — per-child cwd is architecturally supported, but the
spawn provider doesn't expose the override in its config schema. A wrapper
plugin (create worktree → pass cwd → cleanup on dispose) is ~200–800 lines.

**omp reference:** `crates/pi-iso` probes Btrfs→Zfs→Reflink→Overlayfs→Rcopy
(Linux), Apfs→Zfs→Rcopy (macOS); Rcopy = git worktree when the lower dir is a
git repo. **Even omp falls back to git worktrees on ordinary Linux** — fancy
backends only matter on CoW filesystems. Worktrees are the right call.

---

## 7. Eval kernels with tool re-entry

**Python kernel — plug in via MCP today:**
- **datalayer/jupyter-mcp-server v2.0.0** ✅ (BSD-3, ★1,261, pushed
  2026-08-26). 20+ tools: execute_code/cell, notebook ops, kernel listing,
  cloud sandboxes (E2B/Modal/Colab…). `uvx jupyter-mcp-server@latest`
  (stdio) + a running Jupyter server (`JUPYTER_URL` + token). Persistent
  kernel = state across calls.
- **iota-uz/repl-mcp v2.1.1** (lightweight fallback) — single
  `execute_python` tool over persistent ipykernel, crash isolation, real
  interrupt; built-in `mcp.call()` bridge to *other MCP servers* (not Cordis
  tools). No sidecar needed.

**JS kernel:** nothing mature. `mycrl/node-repl-cli` (MCP mode) is the best
available stopgap (★1, immature). Gold standard is omp's Bun worker VM —
would need porting.

**Native DSH neighbors:** `poplarity/dsh-science-workbench` v0.3.0 (npm,
published 2026-08-26 — agent-driven cells, inline figures, rerun, env
snapshots), omicverse/dsh-omicos (persistent Python kernel, GitHub),
muyuanjin/dsh-ptc-plus (session-bound persistent TypeScript REPL).

**Tool re-entry: NO off-the-shelf solution.** Closest is repl-mcp's
MCP-to-MCP bridge, which cannot reach Cordis tools. Plan a small
**`dsh-eval-bridge` Cordis host plugin (~150 LOC)** mirroring omp's design:
per-execution loopback HTTP server on 127.0.0.1 (bearer token), kernel
prelude defines `tool.<name>(...)` proxy (sync urllib / async fetch), resolve
against the session's tool registry, lifecycle under `ctx.effect()`,
shielded abort for critical sections. omp reference:
`packages/coding-agent/src/tools/eval.ts` + eval-backends.ts + kernel preludes.

Pyodide options rejected (too constrained for real coding work).

---

## 8. Checkpoint / rewind

**Top pick (native, installable today): `dsh-checkpoint-rewind` v0.6.0** —
PerryLink/dsh-checkpoint-rewind (npm; created 2026-08-14, published
2026-08-26). "Unified DSH checkpoints: session + workspace + config
three-state snapshots with one-shot rollback — /checkpoint and /rewind
commands, a checkpoint tool, automatic interval snapshots, a Settings page
timeline with pairwise diffs, and seed-replay session restore." This is
arguably *more complete* than omp's checkpoint/rewind (which only collapses
context + branches the session).

Companions:
- `dsh-checkpoint-diff` (tmpdot) — timeline UI + per-file diffs between
  checkpoints produced by dsh-checkpoint-rewind.
- limbo947/dsh-recall-plugin — recall any user message: forks the session
  and rolls workspace files back via per-message shadow git snapshots.
- Taler97/dsh-rollback — observational file-mutation rollback for fs tools
  (git-blob pre-images).

**omp reference:** `src/tools/checkpoint.ts` — rewind =
`sessionManager.branchWithSummary(checkpointEntryId, report)` (branch-based,
not truncation), reconciles advisors/todos/provider sessions.
DSH build-it-ourselves path (if needed): compose `ctx.compaction` seams; M.

---

## 9. Rich web reading (search, PDF, extraction)

**Top pick (native — fixes the broken web_search seam): `dsh-search-failover`
v0.3.9** — Walvez/dsh-search-failover (npm; published 2026-08-23).
"Provider-level web search+fetch pool for DeepSeek Harness: bypass the
official LLM search channel (0 model tokens), failover/rotate across
Exa/Tavily/Jina/Firecrawl/Serper/SerpApi/SearXNG/DDG/Brave with quota-aware
circuit breaking, multi-key rotation." Works with the *native* web_search
tool. DDG/SearXNG backends are keyless.

Alternative: `dsh-web-search-multi` v0.2.0 (zmh2000829, npm) — selectable
SearXNG/Brave/Tavily/Gemini-Search-Grounding/Wikipedia backend for the native
web_search. Also: anysearch-team/anysearch-dsh, dhicoc/dsh-codex-web-search-mcp,
taxueseek/argo (120+ engines).

**Keyless MCP stack** (drop-in rows, verified versions):

| Purpose | Package | Run |
|---|---|---|
| Search | `mcp-duckduckgo` 3.1.0 (MIT) — search, search_and_crawl, research, fetch | `npx -y mcp-duckduckgo` |
| Fetch→markdown | `mcp-server-fetch` 2026.8.18 (official, MIT) — Readability-based, chunked | `uvx mcp-server-fetch` |
| PDF/DOCX/PPTX→markdown | `markitdown` (Microsoft, MIT) — best structure preservation for arXiv | `uvx markitdown-mcp-npx` |
| Search (key, better) | `@brave/brave-search-mcp-server` 2.1.3 (free 2K/mo), `tavily-mcp` 0.2.22, `exa-mcp-server` 3.4.1, `firecrawl-mcp` 3.24.0 (AGPL; best JS-heavy scraping) | npx |
| Private meta-search | `@tadmstr/searxng-mcp` 3.18.0 + self-hosted SearXNG docker | npx + env |

**PDF native plugins:** `pdf-extractor-dsh-plugin` v1.1.2 (npm — page
extraction, splitting, merging, rotation), Tianbuyu-wwx/DSH-FormatForge
(30+ formats incl. PDF/DOCX/PPTX/XLSX), sensedeal cue-omni-reader
(omni-reader-mcp URL/file parsing). npm libs if building natively: `unpdf`
v1.8.1 (unjs, serverless pdfjs, flat text), `pdf-parse` (legacy).

**Dead ends:** r.jina.ai free reader endpoint timed out in live test (dead
as of Aug 2026); `@modelcontextprotocol/server-brave-search` archived
(replaced by @brave/brave-search-mcp-server); PyPI `mcp-jupyter`/npm
`mcp-jupyter` unrelated orphans.

**Remaining gap vs omp:** the 80+ site-specific handlers (GitHub/npm/arXiv/
SO/HN/MDN…) and vuln-DB lookups (NVD/OSV/CISA KEV) have no plugin; generic
fetch+markitdown covers most reading needs. omp reference:
`packages/coding-agent/src/tools/fetch.ts` + web search provider chain.

---

## 10. ast_grep / ast_edit

**Top pick (MCP, official): `ast-grep/ast-grep-mcp`** — ★453, pushed
2026-08-25, "experimental" but first-party under the ast-grep org. Python:
`uvx --from git+https://github.com/ast-grep/ast-grep-mcp ast-grep-server`.
Tools: `dump_syntax_tree`, `test_match_code_rule`, `find_code`,
`find_code_by_rule` (text output ≈75% fewer tokens). Requires the `ast-grep`
binary on PATH (env `AST_GREP_PATH` configurable). **Search-only — no
apply-rewrite tool**; rewrites need the CLI or a native plugin.

Native options:
- **`@ast-grep/napi` v0.45.2** (published 2026-08-23, MIT, zero deps) +
  `@ast-grep/cli` 0.45.2 — official bindings; the right base for a Cordis
  host plugin implementing both `ast_grep` and preview→accept `ast_edit`.
- `ast-grep-mcp` npm 0.0.2 (spiritledsoftware) — Node wrapper of the CLI
  claiming safe rewrites; tiny, secondary.
- `@juvio15/pi-ast-grep` 0.4.2 — ast-grep search/scan/rewrite/outline tools
  for the Pi ecosystem (design reference only).

Ecosystem neighbors (code intelligence via graphs, not AST rewriting):
trench-xinxin/dsh-tool-lens (AST code graph, blast radius),
JohnXu22786/codegraph + jiangzhenguo/dsh-codegraph (SQLite call graphs),
Roarpeng/GraphFlow (10 MCP tools, layered context compression),
wulun811/LiuHe (44-tool MCP toolkit incl. edit_batch with tolerant matching).

**omp reference:** `packages/coding-agent/src/tools/ast-grep.ts` +
`ast-edit.ts` — ast_edit returns a ⟨proposed⟩ preview card, registers a
pending action, then `xd://resolve` applies atomically with stale-preview
detection (replacement-count reconciliation); engine = `pi-ast` Rust crate
(tree-sitter, 50+ grammars). Full parity = native plugin; the MCP covers
structural *search* today.

---

## Recommended quick-start stack (all verified 2026-08-26)

Zero-code installs covering 7 of 10 tier-1 features:

| # | Feature | Install |
|---|---|---|
| 2 | Debugger | `dsh plugin add dsh-debugger-dap` (+ optional `@debugmcp/mcp-debugger` MCP row) |
| 1 | LSP | `dsh plugin add dsh-lsp-actions` (or isaacphi/mcp-language-server MCP rows) |
| 8 | Checkpoint/rewind | `dsh plugin add dsh-checkpoint-rewind` |
| 4 | Fallback chains | `dsh plugin add dsh-llm-fallbacks` (+ Portkey gateway sidecar for heavy routing) |
| 6 | Worktree isolation | not installed (see section 6) |
| 9 | Web search fix | `dsh plugin add dsh-search-failover` (+ `mcp-duckduckgo` + `uvx mcp-server-fetch` + markitdown MCP rows for keyless coverage) |
| 10 | Structural search | ast-grep-mcp via one `dsh-mcp-client` row |
| 7 | Python eval | datalayer/jupyter-mcp-server MCP row (+ Jupyter sidecar) or iota-uz/repl-mcp |

Still requires building (no off-the-shelf anywhere):
- **Advisor** (3): shipped plugin, complexity L; stepping stone: `dsh-auto-review`.
- **TTSR** (5): shipped plugin + two small `dsh-agent-loop` seam additions;
  observation seam proven by `dsh-sseye`.
- **Eval tool re-entry** (7b): `dsh-eval-bridge` host plugin, ~150 LOC,
  design in omp's eval tooling.
- **willRenameFiles** (1b): native LSP plugin or upstream contribution.

## Ecosystem notes & cautions

- Discovery: `awesome-dsh-plugin/awesome-dsh-plugin` (saved copy:
  `.research/awesome-dsh-plugin.md`); in-agent discovery plugins
  `dsh-find-plugin` v0.3.7 and ChengxiuCDP/dsh-plugin-advisor search the
  GitHub `dsh-plugin` topic; marketplaces: dsh-market/dsh-market ★2.5k,
  dsh-plugin-console, @1e0zj/dsh-plugin-mall, dsh-plugin-studio.
- Community plugins run in the host process with full access. Vet before
  install: `ateen18/dsh-plugin-security-review`, hackerFish/dsh-lab
  (tested-curation with install/static-scan gates),
  dsh-plugin-observatory (compatibility audit),
  pengxuding/dsh-plugin-judge (LLM judge). This repo's own ground rule
  (reuse before reinvention) should pair with a source-review step.
- Verified registry snapshot (name — version — created — last publish):
  dsh-debugger-dap 0.1.8 (08-20/08-25) · dsh-lsp-actions 0.3.4 (08-15/08-23) ·
  dsh-checkpoint-rewind 0.6.0 (08-14/08-26) · dsh-llm-fallbacks 0.3.5
  (08-13/08-26) · dsh-search-failover 0.3.9 (08-17/08-23) ·
  dsh-task-worktree 0.4.1
  (08-18/08-24) · dsh-auto-review 0.7.0 (08-15/08-26) · dsh-sseye 0.4.1
  (08-21/08-25) · dsh-web-search-multi 0.2.0 (08-24) ·
  dsh-science-workbench 0.3.0 (08-14/08-26) · pdf-extractor-dsh-plugin 1.1.2 ·
  ast-grep-mcp (GitHub, 08-25) · @ast-grep/napi 0.45.2 (08-23).
- Full sub-reports: DAP, LSP, routing/isolation, eval, and web sections
  above were compiled from six parallel research agents; advisor/TTSR detail
  in `.research/advisor-ttsr-checkpoint-assessment.md`.
