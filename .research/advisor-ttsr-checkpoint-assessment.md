## 3. Advisor, TTSR and checkpoint/rewind

This report maps three agent-loop features onto DeepSeek Harness (DSH) extension seams, using the oh-my-pi (OMP) reference implementation as the design source and the shipped DSH plugins (`dsh-agent-loop`, `dsh-llm`, `dsh-llm-retry`, `dsh-compaction`, `dsh-compaction-basic`, `dsh-output-retention`, `dsh-agent`) as the integration surface. External reusable pieces were scanned on npm and GitHub; essentially none exist for any of these three features (see §3.4).

### 3.1 Reference designs extracted from oh-my-pi

#### A. Advisor / Watchdog (~12 lines)

- **Files:** `packages/coding-agent/src/advisor/{runtime,advise-tool,emission-guard,watchdog,config,transcript-recorder,delta-split,message-fingerprint,loop-guard,index}.ts`, `src/session/session-advisors.ts`, `src/prompts/advisor/{system,advise-tool}.md`, plus `WATCHDOG.md` / `WATCHDOG.yml` discovery. Doc: `docs/advisor-watchdog.md`.
- **Transcript feed:** `AdvisorRuntime` receives only the *delta* since its last cursor via `transcript-recorder.ts`; deltas include reasoning, tool intent, watched-role markers, and expanded constraint context. Provider-bound secrets are obfuscated before reaching the advisor model. Already-injected `<advisory>` elements are filtered out to prevent self-review loops.
- **Isolation:** Each advisor is a full `Agent` with its own `ToolSession` (id suffixed `-advisor`). It does not share file snapshots, seen-lines, conflict state, or summary cache with the primary. Investigative tools default to `read/grep/glob`; `WATCHDOG.yml` can grant mutating tools (`edit/write/bash/eval/browser`), which run in the isolated session but honor the host approval mode.
- **Note injection:** The `advise` tool accepts severity `nit | concern | blocker`. `nit` batches into the next step boundary; `concern`/`blocker` steer the live turn when delivery constraints permit, otherwise render as a visible card. Notes land in the primary transcript as XML-escaped `<advisory advisor="…" severity="…" guidance="…">…</advisory>`. An `AdvisorEmissionGuard` enforces one-note-per-update, normalizes/dedupes, and filters content-free phrases.
- **Sync/backpressure:** `advisor.syncBacklog ∈ {off,1,3,5}` caps how far the advisor may lag before the primary waits (max 30 s). Three dropped-backlog cycles halt the runtime; quota failures pause with batch retained.
- **Reset triggers:** compaction, session switch/resume, branch/fork history replacement, and advisor-context re-prime all reset the cursor and replay the bounded primary transcript.
- **Persistence:** Each finalized advisor turn appends to `<session>/__advisor[.<slug>].jsonl`; excluded from peer rosters, hub broadcast, and `history://` lookup.

#### B. Time-Traveling Stream Rules (TTSR) (~14 lines)

- **Files:** `src/session/ttsr-coordinator.ts`, `src/cli/ttsr-cli.ts`, `src/commands/ttsr.ts`, `src/export/ttsr.ts`, `src/modes/components/ttsr-notification.ts`, `src/prompts/system/{ttsr-interrupt,ttsr-tool-reminder,checkpoint-active-notice}.md`, capability loader `bucketRules`. Doc: `docs/ttsr-injection-lifecycle.md`.
- **Registration:** At session creation, `loadCapability("rules")` dedupes by name; `TtsrManager.addRule()` drops disabled/uncompilable/out-of-scope rules. Rules carry regex `condition`, optional ast-grep `astCondition`, optional `globs`, and per-rule overrides of `interruptMode ∈ {always,prose-only,tool-only,never}`, `contextMode ∈ {discard,keep}`, `repeatMode ∈ {once,after-gap}`, `repeatGap`.
- **Stream monitoring:** `AgentSession.#handleAgentEvent` delegates to `TtsrCoordinator`. On `turn_start` the buffer resets. On each `message_update`, buffers are isolated by source/tool-call key; per-file AST matchers use reconstructed `matcherDigest`/`matcherEntries` from the active tool. Identical consecutive snapshots are skipped.
- **Abort path:** When ≥1 matched rule allows interruption: dedupe into pending injections → set abort-pending flag + resume gate → `agent.abort()` synchronously (scoped to tool-call id for tool matches) → fire-and-forget `ttsr_triggered` → schedule retry task at +50 ms tagged with prompt generation + retry token. Abort is *not* blocked on extension callbacks.
- **Retry & injection:** After 50 ms the task re-validates token/generation/abort-state/target-message; stale tasks clear state and resolve the gate. Otherwise: clear flags → read `contextMode` → if `discard`, `agent.replaceMessages(...slice(0, targetAssistantIndex))` drops partial output → render `ttsr-interrupt.md` as a hidden `custom_message` with `customType: "ttsr-injection"` + persist `ttsr_injection` entry → `agent.continue()`. Non-interrupting tool-source matches instead prepend `<system-reminder>` into the matched tool's `toolResult.content[0]` via the `afterToolCall` hook; non-interrupting prose matches queue a hidden follow-up after a successful assistant message.
- **Repeat policy:** `#messageCount` increments on `turn_end`; `lastInjectedAt` per rule. Restored injections record age zero, so `after-gap` eligibility restarts after reload.
- **Race safety:** Retry is guarded by (retry-token, prompt-generation, abort-state, target-message-identity); extension notification is intentionally un-awaited.

#### C. Checkpoint / Rewind (~11 lines)

- **Files:** `src/tools/checkpoint.ts` (both `CheckpointTool` and `RewindTool`), `src/session/checkpoint-entries.ts`, `src/session/agent-session.ts` (`#checkpointState`, `#extractRewindReport`, `#applyRewind`, `#checkpointActiveReminderFor`), `src/prompts/tools/{checkpoint,rewind}.md`, `src/prompts/system/{checkpoint-active-notice,rewind-report}.md`.
- **Checkpoint tool:** Takes `{ goal }`, records `{ checkpointMessageCount, checkpointEntryId, startedAt }` on the session. Returns immediately with "Finish exploration and formulate findings." Synchronously sets `#checkpointState` *before* the tool-result entry is persisted so an immediate `rewind` still finds an active checkpoint; backfills `checkpointEntryId` once the tool-result entry lands. Queues a transient `<checkpoint-active-notice>` steer so the model knows a checkpoint is live; the notice sits after the checkpoint entry so a rewind branch-cut drops it automatically.
- **Rewind tool:** Takes `{ report }`. Requires an active checkpoint (or errors; a completed rewind also errors with "continue from the retained report"). Returns `{ report, rewound: true }`.
- **Apply rewind:** `#applyRewind` calls `sessionManager.branchWithSummary(checkpointEntryId, report, { startedAt })` inside `bash.withBranchTransition` — this creates a new session branch rooted at the checkpoint entry, with the report as the branch summary. Falls back to root if the checkpoint entry is missing. Then appends a `rewind-report` custom message (rendered via `rewind-report.md`), splices `activeMessages` in place with `buildDisplaySessionContext().messages`, calls `agent.replaceMessages(...)`, resets advisors (`preserveCost: true`), syncs todo, closes codex provider sessions, and clears `#checkpointState` / `#pendingRewindReport`.
- **Semantics:** This is *branch-based* rewind, not in-place truncation. The exploratory tail lives on a dead branch; the active path continues from the checkpoint with only the report. Advisor state, todos, and provider sessions are explicitly reconciled.

### 3.2 External reusable pieces (August 2026 scan)

Searched npm (`llm judge`, `agent reviewer`, `llm critic stream`, `mcp server judge`) and GitHub (`llm stream judge reviewer`, `streaming llm abort retry`). Findings:

- **No streaming second-model reviewer exists.** Everything found is an offline/batch judge: `llm-scorer` (JSONL judge, 2k downloads/mo), `@skill-harness/core` / `skill-harness` (eval grading), `agentic-test-runner` (YAML test cases → LLM PASS/FAIL). None observe a live transcript or abort a stream.
- **No MCP judge server.** `@modelcontextprotocol/sdk/server` are transport; no published server exposes a streaming-reviewer tool.
- **`pi-subagents`** (330k downloads/mo) is single-agent delegation for OMP itself — relevant only as evidence that even OMP's ecosystem treats reviewer-as-subagent as bespoke.
- **Constitutional-AI / self-critique libraries** are training-time or post-hoc; none hook a live SSE/token stream.

Conclusion: all three features are greenfield integrations against DSH's own seams. There is nothing to import; the OMP reference is the only usable prior art.

### 3.3 DSH implementation assessments

#### A. Advisor / Watchdog

| Dimension | Assessment |
|---|---|
| Feasibility tier | **Shipped-plugin-level change** (new plugin in `@deepseek-ai/dsh-advisor`, loaded via `cordis.yml`). Not viable as a dynamic session plugin because it must own a persistent sub-agent, its own `ToolSession`, JSONL persistence under the session artifacts dir, and cross-turn cursor state that survives HMR. Dynamic plugins could prototype the note-injection half but not the durable reviewer agent. |
| Primary seam(s) | `session/event` (observe `assistant/chunk`, `turn/start`, `turn/end`, `tool/call`, `tool/result`); `agent/created` / `agent/disposed` (lifecycle); `ctx.agents.create({ setup })` to spawn the advisor agent with its own scoped world; `agent.steer()` / `agent.inject()` / `agent.followup()` to deliver notes at the right priority; `tools.guard()` + `tools/pre-execute` if advisor-granted mutating tools must respect the primary's approval context; a new `advisor/note` event for UI cards. |
| Compaction/reset hook | Listen to `compaction/start` / `compaction/end` and `session/event` for branch/fork markers; on either, reset the advisor cursor and replay via `deriveMessages()`. |
| Backpressure | Implement `syncBacklog` as a plugin-owned promise gate resolved when the advisor's pending-delta count drops below threshold or a 30 s timer fires; primary turn-end listener awaits it. |
| Persistence | Use the existing session artifacts directory convention (`<session>/__advisor[.<slug>].jsonl`); register via `ctx.sessions` for path resolution. |
| Complexity | **L**. Rough parity with OMP's ~10 source files. Biggest risks: (1) correct delta rendering across every `session/event` kind including tool-result redaction, (2) emission-guard dedupe surviving compaction/reset, (3) approval-mode propagation to advisor tool sessions, (4) JSONL lifecycle across session switch / `/drop`. |
| OMP files to port ideas from | `advisor/runtime.ts` (cursor + delta dispatch), `advisor/emission-guard.ts` (dedupe/rate-limit), `advisor/transcript-recorder.ts` (JSONL writer), `advisor/advise-tool.ts` (severity routing), `session/session-advisors.ts` (per-session wiring), `prompts/advisor/system.md` (reviewer system prompt), `WATCHDOG.yml` schema. |

#### B. Time-Traveling Stream Rules (TTSR)

| Dimension | Assessment |
|---|---|
| Feasibility tier | **Needs shipped-plugin-level change AND a small core seam addition.** DSH currently exposes `session/event` (`assistant/chunk`) for observation and `agent.cancel(cause, { keepInbox: true })` for mid-stream abort, plus `llm/stream` waterfall for wrapping. What is *missing* is: (1) a public, per-step "replace partial assistant output" primitive equivalent to OMP's `agent.replaceMessages(...slice(0, idx))` — DSH has `surface.replaceGeneration` for compaction but no general-purpose partial-output discard; (2) a `agent.continue()` that resumes from the *same* request coordinates after an injection rather than opening a fresh step. Without these two, a plugin can detect violations and abort, but cannot faithfully retry-from-same-point with the injection in context. Adding them is a bounded `dsh-agent-loop` change (one new inbox/splice operation + one continue-path flag). |
| Primary seam(s) | `session/event` for `assistant/chunk` buffering (already emitted); `llm/stream` waterfall to wrap the iterator and detect regex hits *before* chunks reach persistence (lower latency than post-hoc `session/event`); `agent.cancel(cause, { keepInbox: true })` for the synchronous abort; new `agent/replace-partial` and `agent/continue-from` APIs; `agent/inject` for the rendered `<system-interrupt>` custom message; `tools/post-execute` or a new `tools/result` pre-hook for non-interrupting tool-source reminders prepended to `toolResult.content`. |
| Persistence | New session-event kind `ttsr/injection` (parallel to `compaction/*`) carrying rule names + rendered template; restored via `ResumeAgentOptions.setup`. |
| Repeat policy | Plugin-owned `Map<ruleName, lastInjectedTurn>`; increment counter on `turn/end`. |
| Race safety | Tag every scheduled retry with `(promptGeneration, retryToken, targetAssistantSeq)`; validate before injecting. Extension notification is fire-and-forget. |
| Complexity | **L** even with the seam additions. The coordinator logic (buffer isolation, per-file AST matching, interrupt-vs-deferred routing, repeat gating, race guards) is ~600 LOC in OMP and ports nearly 1:1. The seam additions themselves are **S–M** (a splice variant + a continue flag + tests). |
| OMP files to port ideas from | `session/ttsr-coordinator.ts` (the heart), `export/ttsr.ts` (rule schema), `prompts/system/ttsr-interrupt.md` + `ttsr-tool-reminder.md` (injection templates), `capability/index.ts` (`bucketRules`), `modes/components/ttsr-notification.ts` (UI affordance). |
| Blocker if seam is not added | Without `replace-partial` + `continue-from`, the best a plugin can do is abort + inject + open a *new* step, which changes the request coordinates and breaks the "time-travel" guarantee. Recommend landing the seam first. |

#### C. Checkpoint / Rewind

| Dimension | Assessment |
|---|---|
| Feasibility tier | **Feasible as a shipped plugin that composes existing seams; no core change required.** DSH already has `ctx.compaction` with `compactRegion` / `compactNow` and the `surfaceOp: { op: 'replace', start, end }` primitive, plus `compaction/start` / `compaction/end` locking and `deriveMessages()` replay. OMP's branch-based rewind is *one* design; DSH can implement the same user semantics ("collapse exploration into a short report") as a specialized compaction backend that takes the report as input instead of generating one. This avoids inventing a parallel branching model. |
| Primary seam(s) | Register a new `CompactionEngine` subclass (sibling to `dsh-compaction-basic`) exposing two tools: `checkpoint` (records `{ goal, startedAt, surfaceSeq }`) and `rewind` (accepts `{ report }`, calls `compactRegion` over `[checkpointSeq, currentSeq]` with the report as the summary, bypassing the summarizer LLM call). Tools registered via `ctx.tools`; results observed via `tools/result` to backfill entry ids. |
| Alternative (closer to OMP) | If true branch semantics are desired (exploration preserved on a dead branch), add a `sessions.branchWithSummary(entryId, report)` method to `dsh-session`. This is a **small core addition** but gives identical semantics to OMP including drop-in compatibility with `checkpoint-entries.ts` helpers. Recommended if fork/resume UX is planned anyway. |
| Advisor / todo reconciliation | Listen to the rewind completion event and call the advisor-runtime reset + todo sync. Both are already exposed as plugin-accessible services (`ctx.agents`, session-scoped todo service if present). |
| Complexity | **M** for the compaction-backend approach (new engine + two tools + prompt templates). **M–L** for the branch-based approach (adds `sessions.branchWithSummary` + the same tools + reconciliation hooks). Either way, significantly smaller than Advisor or TTSR because the heavy lifting (locking, surface replacement, replay) already lives in `dsh-compaction`. |
| OMP files to port ideas from | `tools/checkpoint.ts` (tool contracts + state shape), `session/checkpoint-entries.ts` (semantic normalization, `completedRewindFromEntry`), `prompts/tools/{checkpoint,rewind}.md` (tool descriptions), `prompts/system/{checkpoint-active-notice,rewind-report}.md` (injected notices), `agent-session.ts#applyRewind` (reconciliation checklist). |

### 3.4 Cross-cutting observations

1. **All three features assume a stable `session/event` log as the source of truth.** DSH already provides this; any implementation must consume events through the canonical projection (`deriveMessages()` / `foldConsumedWork()`) rather than caching raw chunks.
2. **Approval propagation is the hardest cross-cutting concern for Advisor.** The advisor's tool session must inherit the primary's approval mode *and* per-tool policies without sharing the primary's file-snapshot/conflict state. OMP solves this with `ExtensionToolWrapper`; DSH should expose an equivalent wrapper via `dsh-tools` rather than rebuilding it.
3. **TTSR's 50 ms retry delay is load-bearing.** It lets the abort converge and the stream finalize its interrupted anchor before the injection lands. Any DSH port must preserve this timing contract; scheduling via `ctx.timer` (from `cordis-plugin-timer`) rather than raw `setTimeout` keeps it fiber-aware.
4. **Compaction interacts with all three.** Advisor resets on compaction; TTSR injected-rule state must survive compaction (persisted `ttsr_injection` entries); checkpoint/rewind *is* a compaction variant. Implement in dependency order: compaction seam extensions → checkpoint/rewind → TTSR → Advisor.
5. **Dynamic Cordis plugins are useful for prototyping only.** A dynamic plugin can demonstrate TTSR detection (listen to `session/event`, call `agent.cancel`) or checkpoint tool registration, but cannot durably own the advisor agent, the JSONL writer, or the compaction backend. Plan for shipped plugins from the start.
6. **Nothing external is reusable.** Budget zero time for integrating third-party judge/critic/stream-abort libraries; the entire integration surface is DSH-internal.

### 3.5 Recommended implementation order

1. **Land the two TTSR seam additions** (`agent/replace-partial`, `agent/continue-from`) in `dsh-agent-loop`. Small, testable, unblocks TTSR.
2. **Ship `@deepseek-ai/dsh-checkpoint-rewind`** as a compaction-backend plugin. M complexity, immediate user value, exercises the compaction seam.
3. **Ship `@deepseek-ai/dsh-ttsr`** using the new seams. L complexity, but the coordinator logic ports 1:1 from OMP.
4. **Ship `@deepseek-ai/dsh-advisor`** last. L complexity, depends on stable TTSR/checkpoint behavior for reset semantics, and benefits from having the approval-wrapper infrastructure proven by the earlier plugins.

Each plugin should land with its own `cordis.yml` row, a sibling `README.zh.md`, and an invariant companion package (following `dsh-agent/invariant`) so state transitions are machine-checked during development.
