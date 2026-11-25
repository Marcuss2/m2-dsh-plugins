# Compact fails after removing the `mistral-vibe` provider

Recorded 2026-11-24. DSH `0.2.2-rc.5`, profile `web`, working directory
`/home/vrbkam/repos/m2-dsh-plugins`.

**Status: fixed and verified live.** `/compact` now succeeds in the affected
session: `Compacted 237 history items (~126661 tokens)`. No host restart was
needed.

## Symptom

`/compact` failed four times in a row in *Redesign website design language
with subagents* (workspace `job-analyzer`, session
`session-3d45559c-89d4-441c-8ef5-1ffb1b0c85ac`):

```
Compaction could not produce a useful summary. The attempt is recorded in the session log.
```

Switching provider/model in the GUI (OpenCode Go `hy4`, `deepseek-v4.1-flash`,
`synthetic` GLM-5.3-Flash, `openrouter-custom` free models) did not help.

## Root cause

The GUI message is a **mask**. The session log
(`~/.dsh/sessions/--home-vrbkam-Projects-job-analyzer--/session-3d45559c-.../session.v4.jsonl.zstd`)
records the real error on every `compaction/end`:

```json
{"type":"compaction/end","seq":4429,"data":{...,"error":"no adapter registered for provider \"mistral-vibe\""}}
```

Chain:

1. `dsh-compaction-basic/src/summarizer.ts:127-137` picks the summarization
   route as `configured ?? latest ?? agentTarget`, where `latest` is
   `agent.session.requestHeader()?.config` — the **last routed request** of
   that session. `configured` (explicit `summarizationProvider`/`Model`) is
   unset and the stale header wins over `agent.options` (the live selection).
2. Those sessions were originally routed through `mistral-vibe`. The package
   was removed from the profile, so `dsh-llm` raises
   `LlmError('no adapter registered for provider "mistral-vibe"', 'NO_ADAPTER')`
   (`dsh-llm/src/index.ts:1037`). The summarizer never reaches a model.
3. `dsh-compaction-basic/src/region.ts:294` classifies **every** summary-stage
   failure as `ManualCompactionError('summary', ...)`; `dsh-command-compact`
   maps that code to the fixed "could not produce a useful summary" string.
   The cause is only visible in the session log.

The older `summarization truncated at the token cap (incomplete checkpoint)`
failures captured in `.diag/target.jsonl` (session `1ddfbf55`, 2026-10-22) are
a **different** failure of the same masking layer, not this bug. They are why
the October investigation chased output-token limits; that diagnosis was later
corrected in the same session.

## Why a plain `cordis.patch.yml` override does not work

The top-level `compaction-basic` / `command-compact` rows are
`disabled: true`; the live engines sit inside `compaction` groups nested in
each agent preset's `config.plugins`. `applyPatches()` only indexes the root
Include's entries and `insert` clones — it never indexes nested preset plugin
rows — so an `- id: compaction-basic` patch hits only the disabled row.
Verified with `dsh --profile web --dump-config --patch <overlay>`: the nested
rows keep their defaults and the loader prints
`patch: entry "compaction" not found`. Root-owned harness files cannot be
patched either (`root:root 0644`, no passwordless sudo).

## Fix

### 1. Compatibility alias (primary; live, no restart)

`~/.dsh/plugins/dsh-provider-alias/index-v2.js` registers the removed
`mistral-vibe` id as a thin `LlmAdapter` that forwards every call to
`dsh-opencode-go`/`hy4`. It is mounted by a **top-level `insert` row** in
`cordis.patch.yml`:

```yaml
- insert:
    - id: provider-alias-mistral-vibe-v2
      name: /home/vrbkam/.dsh/plugins/dsh-provider-alias/index-v2.js
      config:
        alias: mistral-vibe
        targetProvider: dsh-opencode-go
        targetModel: hy4
```

A plain `- id: ...` patch is treated as an override of an existing row and
logs `entry not found`; a new row must go through `insert`. The row was
mounted **without restarting the host** by changing the GUI model selection,
which calls `agentDefaultModel.saveSelection()` → `configEditor.edit()` →
`reconcileProfilePatches()`. The selection was then restored to `hy4`.

Two details that matter for the alias adapter:
- `resolveModel(provider, model)` must echo the **requested** provider and
  model id; returning the target's ids fails
  `normalizeModelInfo()` with `INVALID_MODEL_INFO`.
- Changing a row's `name` in place does not re-import the module (ESM cache);
  the row id must change too (`-v2`).

The alias also fixes any other stale `mistral-vibe` route (session titles,
teammate pins), not just compaction.

### 2. Resilient summarizer (defense in depth; active after restart)

`~/.dsh/profiles/web/node_modules/@deepseek-ai/dsh-compaction-basic/` is a
profile-local wrapper that subclasses the stock engine and, on `NO_ADAPTER`,
retries summarization against the agent's live route. Canonical copy:
`~/.dsh/plugins/dsh-compaction-basic-compat/`. Bare specifiers resolve from
the profile directory, so it shadows the stock package for **every** preset row
on the next boot. Last-resort route overrides:
`DSH_COMPACTION_FALLBACK_PROVIDER`, `DSH_COMPACTION_FALLBACK_MODEL`
(defaults `dsh-opencode-go` / `hy4`).

After any `pnpm install` in the profile (plugin install/upgrade) re-create it
— pnpm can prune an unmanaged `node_modules` entry:

```sh
mkdir -p ~/.dsh/profiles/web/node_modules/@deepseek-ai/dsh-compaction-basic/lib
cp ~/.dsh/plugins/dsh-compaction-basic-compat/package.json \
   ~/.dsh/profiles/web/node_modules/@deepseek-ai/dsh-compaction-basic/package.json
cp ~/.dsh/plugins/dsh-compaction-basic-compat/lib/index.js \
   ~/.dsh/profiles/web/node_modules/@deepseek-ai/dsh-compaction-basic/lib/index.js
```

Also cleaned the two dead `mistral-vibe` teammate pins in
`agent-team-model-pin.sessions` in `cordis.patch.yml`; no config references
the removed package any more (only historical market logs remain).

## Verification

Feedback loop (stale `mistral-vibe` header, live `dsh-opencode-go/hy4`
selection, mocked `ctx.llm` that throws `NO_ADAPTER` for the removed
provider and streams a checkpoint otherwise):

```
$ node /tmp/compact-regression.mjs          # stock engine
routes tried: ["mistral-vibe/deepseek-v4-1-flash-1017"]
RED: no adapter registered for provider "mistral-vibe"          exit=1

$ node /tmp/compact-regression-fixed.mjs    # wrapper
routes tried: ["mistral-vibe/deepseek-v4-1-flash-1017","dsh-opencode-go/hy4"]
GREEN: compacted via dsh-opencode-go/hy4 (53 chars)             exit=0
```

End-to-end in the running GUI, after the alias row reconciled:

```
compaction/start  seq 4445
compaction/summary seq 4446
compaction/end    seq 4448   (no error)
command/done      seq 4449   kind=success  "Compacted 237 history items (~126661 tokens)."
```

A second `/compact` after the surface had shrunk also reached the LLM; it was
rejected only by the normal size guard (`summary is not smaller than the
shadowed content (4540 estimated framed tokens >= 4284)`). That confirms the
alias survived the later config reconciles — and is another example of the
masking layer: a healthy "nothing left worth compacting" outcome is still
reported as "could not produce a useful summary".

Also verified:

- `import.meta.resolve('@deepseek-ai/dsh-compaction-basic', 'file:///home/vrbkam/.dsh/profiles/web/cordis.yml')`
  → the profile-local wrapper; from the harness root it still → the stock file.
- `dsh --profile web --dump-config` exits 0 (only the three pre-existing
  `session-title-studio` "entry not found" warnings).
- The live failure was reproduced before the fix (six failed `compact` rows).

## Upstream issues worth filing

1. `summarizeWithLlm` should prefer the agent's live selection over a durable
   request header that can outlive its provider package.
2. `throwManualFailure` collapses all summary-stage errors into `summary`;
   the command should surface `error.cause.message` (e.g.
   `no adapter registered for provider "mistral-vibe"`) so the session log is
   not the only place the real reason appears.
