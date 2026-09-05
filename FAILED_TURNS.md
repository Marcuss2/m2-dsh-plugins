# FAILED_TURNS — failure log for later investigation

Session: sidebar + subagent-monitoring plugin work (2026-09-05).
Every run_code / tool failure observed in this turn's exploration is recorded
here with its raw error, the phase/state markers, and the lesson drawn.

---

## F1 - hindsight_read_knowledge_page result shape assumed (`body` on object)

- **Cell:** `const [pages, comp] = await Promise.all([...])` - succeeded, but the
  follow-up cell that consumed it failed (F2). The tools return **JSON strings**,
  not parsed objects.
- **Lesson:** `hindsight_*` tools resolve to stringified JSON; `JSON.parse` before
  property access.

## F2 - TypeError on `dec.body.length`

```
error[PTC-X001]: uncaught TypeError: Cannot read properties of undefined (reading 'length')
 --> current:6:36
> 6 | return {conv: conv.body.length, dec: dec.body.length};
phase: execute
state: partially-applied
help: inspect existing bindings and retry only the failing expression
```

- **Cause:** same as F1 - page results are JSON strings, so `.body` is undefined.
- **Recovery:** ran `JSON.parse(conv)` / `JSON.parse(dec)` in a fresh cell. Worked.
- **Residual risk noted:** under `state: partially-applied`, earlier top-level
  bindings in the failed cell (`c`) may be uninitialized; re-check before reuse.

## F3 - hindsight_reflect HTTP 500

```
error[PTC-X001]: uncaught ToolCallError: {"error":"reflect 500"}
phase: execute
state: partially-applied
cause: {"error":"reflect 500"}
```

- **Cause:** server-side error from the Hindsight reflect endpoint (transient or
  overloaded); not a client bug. It killed the whole `Promise.all` cell, so the
  sibling search result was also lost.
- **Recovery:** retried `hindsight_search_knowledge_pages` alone in a new cell -
  succeeded. Did not retry reflect.
- **Lesson:** do not `Promise.all` a flaky call with a needed one; isolate risky
  calls or wrap in try/catch inside the program.

## F4 - cell produced no output (`console.log` chain after empty bash)

```
(run_code completed with no output)
```

- **Cell:** inspected `dsh-client-ui-slots/lib/types/...` - package does not exist
  at that path; `bash` exited 0 with empty stdout/stderr, and the cell logged only
  those empties.
- **Lesson:** "no output" here means the probe hit a missing path silently. Check
  existence (`ls | grep`) before assuming a package is present. In fact
  `@deepseek-ai/dsh-client-ui-slots` is **not installed** under
  `~/.dsh/profiles/node_modules/@deepseek-ai/` - it lives elsewhere (global
  install tree), which F5 confirmed.

## F5 - nested native tool call missing required `description`

```
error[PTC-X001]: uncaught ToolCallError: nested native tool arguments are missing
required `description` at JSON path $.description (bash); this does not satisfy
the outer run_code transport
phase: execute
state: partially-applied
cause: invalid arguments: missing required property "description"
```

- **Cause:** while writing a long bash command I omitted the mandatory
  `description` field on the nested `tools.bash` argument object. Under
  `mode: both`, native tool schemas are enforced through the run_code transport
  too.
- **Lesson:** every nested `tools.*` call needs `description` (bash) even when the
  command itself is obvious. This was the last failure before the user's
  interruption asking for this file.

## F6 - direct `write` tool call rejected in this session

```
Tool write does not exists.
```

- **Cause:** attempted to call the native `write` tool directly from the harness
  tool-call layer; in this session only `run_code` is callable directly, so
  `write` must be invoked as `tools.write(...)` from inside a program.
- **Recovery:** wrote this file via `await tools.write({...})`.
- **Lesson:** per the PTC conventions note - all native tools except run_code /
  edit_run_code must be called from inside a program.

---

## General takeaways for the sidebar task

1. Hindsight tool results are JSON **strings**; parse them.
2. `dsh-client-ui-slots` is a peer of the UI packages but resolves from the
   global install (`/usr/lib/node_modules/@deepseek-ai/dsh/node_modules/...`),
   not the profile tree - locate its real bundle before importing it in a plugin.
3. The web frontend dist is minified/one big asset
   (`dsh-web-frontend/dist/assets/index-*.js`); slot-name discovery there needs
   string greps, not source reading.

---

## F7 — ROOT-CAUSE INVESTIGATION: why a PTC-C001 parse error stopped the agent loop (2026-09-05)

**Symptom:** the run_code cell with the unterminated template literal returned
`error[PTC-C001]: cell could not be parsed ... phase: parse, state: unchanged`
and the turn ended — the model never got to react. Per design, a parse failure
should be a self-correctable tool result, not a loop killer.

**Mechanism traced through the installed code (core 0.1.1-rc.2 + dsh-ptc-plus 0.3.2):**

1. `dsh-tools/lib/types/code-mode.js:538` — when the kernel reports any
   program-level error (`result.error`, which includes `phase: parse`), the
   run_code transport **throws** `CodeRunFailedError` ("the registry's execution
   pipeline converts it into a structured isError result so the model can
   self-correct" — that is the intent).
2. `ToolRuntime.dispatchScheduledExecution` (`dsh-tools/lib/index.js:3198`)
   catches everything around the `tools/execute` waterfall and returns
   `{kind:'final-result', result: toolErrorResult(error)}` — still fine.
3. **The defect** is in `dsh-agent-loop/lib/index.js` `runGroup()`:
   - `commitReady()` calls `scheduler.finish/finalize(...)` **without a
     per-call try/catch** (line ~179);
   - `fillPool()` calls `await commitReady(); throwSchedulerFailure();`
     (lines ~235-248);
   - the outer `catch` stores it as `schedulerFailure` and **re-throws**
     (lines ~252-255), explicitly *without* committing results for the settled
     calls ("a terminal scheduler failure preserves already-recorded tool/call
     events without fabricating results").
4. The re-throw escapes `executeToolCalls` → the turn driver's catch (~line
   574) records `turn/end {kind:'error'}` and re-throws via `throwError` —
   **the loop stops**. A single poisoned finalize turns every sibling call of
   that step into an unrecovered scheduler failure.
5. Any throw from `finishScheduledExecution`'s conversion path itself is a
   poison pill: `materializeFinalResult` / `applyFinalContent` /
   `toolErrorResult` are only wrapped two levels up, so their failures become
   `schedulerFailure` instead of an isError result.

**Why this session hits it:** dsh-ptc-plus patches the run_code definition
(`runtime-bridge-owner.js patchRunCodeDefinition` + `executeTentative` deferred
settlement), so every cell outcome traverses extra plugin code inside
finalize; its journal/meta stamping on `isError` results is the plausible
thrower. The stock core path may simply never trigger it.

**Status:** upstream defect (harness), latent in the shipped scheduler;
ptc-plus 0.3.2 is the latest published version, no fix available. Next step if
it recurs: capture the thrown error identity (attach a temporary
`tools/result` observer or run with debug logging) to name the exact thrower
before reporting upstream.

**Workaround until fixed:** keep cells syntactically trivial-safe (this agent:
avoid nested-template-literal traps by building shell commands with joined
string arrays); after a stop, resume the session and resend corrected source —
REPL state survives (state: unchanged).
