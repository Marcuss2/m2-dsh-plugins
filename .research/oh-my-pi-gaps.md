# oh-my-pi (omp) vs DeepSeek Harness — feature gap findings

Research date: 2026-08-26. Clone: `.research/oh-my-pi` (shallow).
Source: https://github.com/can1357/oh-my-pi — terminal coding agent, fork of
badlogic/pi-mono (Can Bölük). ~80k LoC Rust core + TypeScript, 31 built-in
tools, 60+ providers, 14 LSP ops, 28 DAP ops.

Compared against DSH 0.1.0-rc.8 (commit 141eb6be) as deployed at
/usr/lib/minke/resources/host (plugin inventory under node_modules/@deepseek-ai).

## Parity — DSH already has these (do not re-propose)

- Hashline-style editing: DSH `edit` tool with 3-char hash anchors == omp `edit`/hashline.
- Plan mode, todo, structured ask, session resume/fork/export, session log export.
- Subagents (+fork, control, report), workflows, Ralph loops, goals, background jobs.
- Skills, MCP client, persistent PTY bash, compaction (basic + tool-result pruner).
- `web_fetch` with HTML→markdown (turndown).
- tmux context, durable schedule/reminders, attachments/deliverables.
- Sandbox + approval stack, token meter, OTel telemetry.
- Cordis host+client plugin system incl. dynamic session-scoped plugins.
- Hindsight memory tools (≈ omp retain/recall/reflect with Hindsight backend).
- Provider breadth: DSH uses `@earendil-works/pi-ai` (dsh-llm-pi-ai) — the same
  provider library omp builds on; custom OpenAI-compatible providers via config.
- `read_image` ≈ omp `inspect_image`.

## Gaps — omp features DSH lacks (prioritized)

### Tier 1 — high value
1. **LSP tool** — diagnostics, navigation, symbols, renames via
   `workspace/willRenameFiles` (re-exports/barrel files update before move),
   code actions, raw requests. "Everything your IDE knows, the agent knows."
2. **DAP debugger tool** — attach lldb/dlv/debugpy; breakpoints, stepping,
   threads, stack, variables. 28 DAP ops.
3. **Advisor / watchdog** — reviewer model on its own context reads every turn
   of the main agent and injects inline notes (aside/concern/hard blocker).
   Configured via WATCHDOG.yml roster; advisors can get their own tool session
   (read-only by default), honoring approval mode.
4. **Model routing depth** — 10 roles (default/smol/slow/plan/commit/vision/
   designer/task/advisor/tiny), per-role fallback chains (`retry.fallbackChains`,
   cooldown restore), path-scoped enabledModels/disabledProviders, round-robin
   credential rotation with session affinity. DSH today: one per-session model
   selection + per-provider retry policy only.
5. **Time-traveling stream rules (TTSR)** — rules stay dormant until a regex
   matches the live stream; the stream aborts mid-token, the rule is injected as
   a system reminder, and generation retries from the same point. Course
   correction without per-turn context tax; injections survive compaction.
6. **Subagent workspace isolation** — `task` fans out into isolated worktrees
   (pi-iso: APFS clones, btrfs/zfs reflinks, overlayfs, projfs, rcopy); typed
   schema-validated results. DSH subagents share one workspace → merge conflicts.
7. **eval kernels with tool re-entry** — persistent Python + Bun/JS cells whose
   code can call back into agent tools (read/search/task) over a loopback bridge.
8. **checkpoint / rewind** — user-directed collapse of exploratory context into
   a concise report (DSH only compacts automatically).
9. **Rich web reading** — `read` handles URLs/PDFs/archives/SQLite/notebooks/ssh;
   site-aware extraction (GitHub, npm/PyPI/crates, arXiv, SO/Reddit/HN, MDN…)
   preserving anchors; 23-provider search chain with keyless fallbacks;
   vuln DB lookups (NVD/OSV/CISA KEV). DSH: single deepseek search provider,
   plain fetch→markdown, no PDF.
10. **ast_grep / ast_edit** — structural search and rewrites over 50+
    tree-sitter grammars; edits return a proposed card, then a one-line reason
    to `xd://resolve` accepts atomically.

### Tier 2 — useful, more situational
11. **Collab** — /collab puts a live session on a relay, returns link + QR;
    read-write pairing or read-only view; client-side sealed frames.
12. **Git intelligence** — git_overview/git_file_diff/git_hunk tools; `omp commit`
    splits unrelated changes into dependency-ordered atomic commits (cycles
    rejected, source>tests/docs scoring, lockfiles excluded); `conflict://N`
    URL per merge conflict, write `@theirs|@ours|@base` to resolve, bulk `conflict://*`.
13. **Internal URL schemes** — 16 schemes (pr://, issue://, agent://, skill://,
    ssh://, …) resolved transparently inside every FS-shaped tool.
    `agent://<id>/findings.0.path` pulls fields from subagent output by path.
14. **/review** — parallel reviewer subagents sweep branch/commit/uncommitted
    work; verdict + P0–P3 issues with confidence scores.
15. **computer tool** — desktop control: windows/displays, screenshots, native
    input, OS accessibility tree, clipboard.
16. **Browser upgrades** — stealth by default; browser-relay Chrome extension
    adopts already-open tabs without focus stealing; same API drives Electron
    apps (e.g. Slack).
17. **generate_image / tts** — image gen/edit via Gemini/GPT/Grok; TTS via Grok
    Voice (DSH has image *input* via read_image, no generation or speech).
18. **security_scan** — native security reviews via Codex Security.

### Tier 3 — nice-to-have / niche
19. Magic keywords — `ultrathink` / `orchestrate` / `workflowz` prose triggers
    (context-aware matching, ignored inside code spans/paths).
20. Config inheritance — reads .claude, .cursor, .windsurf, .gemini, .codex,
    .cline, .github/copilot, .vscode rules/skills/MCP natively, no migration.
21. ACP (Agent Client Protocol) — run inside Zed; tool I/O routes through the
    editor, writes gated by permission prompts.
22. learn → promote-to-managed-skill pipeline (`learn`, `manage_skill` tools).
23. Voice (Opus/WebRTC), omp-stats dashboard, plugin marketplace, benchmark
    metaharness, snapcompact bitmap-frame compression.

## DSH advantages over omp (for balance)

- Cordis composition: host services + browser UI slots + dynamic session-scoped
  plugins with approval flow + HMR; omp extensions are TS modules only.
- Web GUI surface (omp is TUI-only; web is view-only collab guest).
- MCP client built in; durable schedule/reminders; landlock sandbox stack.
- Hindsight memory integration; workflow orchestration tool; SQLite session query.

## Feasibility notes for DSH

- Advisor ≈ a persistent background subagent fed the transcript via host events,
  injecting through a steering message — Cordis events + subagent registry exist.
- Model roles/fallbacks fit the existing dsh-llm seam (per-provider retryPolicy
  already exists; roles/fallback chains would extend routing config).
- TTSR needs a stream-level hook; the llm seam + waterfall events are the seam
  to inspect (`agent/request-error` waterfall pattern already used by llm-retry).
- eval kernels: dsh-code-runtime-worker-thread already runs dynamic code in
  worker threads; a persistent kernel + tool-loopback bridge is a new service.
- LSP/DAP: no existing seam; would be new host plugins + tools.
