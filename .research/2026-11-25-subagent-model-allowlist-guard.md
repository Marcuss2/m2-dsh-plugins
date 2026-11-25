# Subagent Model Allowlist Enforcement — Market Scout (follow-up)

**Date:** 2026-11-25
**Scope:** Find a DSH plugin that stops an agent session from creating a subagent whose *effective*
`provider/model` is not in Settings → **Subagent** → "Models agents may choose" (the
`subagent-model-selection` / `allowedModels` allowlist). Raised after a probe delegation with no
model fields succeeded and fell back to the default child route.
**Method:** Read the installed harness source and docs directly; grepped every installed
`@deepseek-ai/*` package for allowlist references; consulted the GUI market catalog
(`awesome-dsh-plugin.com/plugins.json`), npm registry metadata, GitHub READMEs / design docs,
the DSH Hub listing and upstream issue discussion. All version/compatibility claims below were
read from primary sources, not inferred from names.
**Host baseline:** `@deepseek-ai/dsh` **0.2.2-rc.5**, `web` profile, 23 dependencies / 25
bundles. The `subagent-model-selection-settings` patch row is `enabled: true` with an
allowlist of eight routes (one `synthetic`, seven `dsh-opencode-go`). Compatibility
judgments are against rc.5.
**Constraint:** research only — **nothing was installed, no profile was modified**.
**Companion:** `.research/2026-10-24-subagent-model-routing-market-scout.md` surveyed plugins
that let the *model choose* a route. This note surveys plugins that *enforce the user's*
allowlist — a different question, with mostly different packages. The saved catalog snapshot
`.research/awesome-dsh-plugin.md` (2026-08-28) predates every plugin below.

---

## Headline finding

Such a plugin exists and is already listed in the GUI's Plugin Market:
**[`a-molecule-of-ATP/dsh-subagent-model-guard`](https://github.com/a-molecule-of-ATP/dsh-subagent-model-guard)**
(v0.2.1, MIT). It is the fit for this host. A workflow-only complement
([`Rayzenchen/dsh-workflow-model-guard`](https://github.com/Rayzenchen/dsh-workflow-model-guard))
is tested on exactly 0.2.2-rc.5. The npm package of the same name
(`dsh-subagent-model-guard` 0.1.0, mimajiushi) is **not** compatible with rc.5.

A plugin is genuinely needed: the harness enforces the allowlist in exactly one place, and
three delegation paths bypass it.

---

## Native baseline, verified on this host

| Fact | Evidence |
| --- | --- |
| The only allowlist check is `assertAllowedModelSelection()` | `/usr/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-tool-subagent/lib/index.js`; the error is `child LLM route "<provider>/<model>" is not allowed for this Session` |
| It lives in **one** package | A grep for `assertAllowedModelSelection` across all installed `@deepseek-ai/*` packages hits `dsh-tool-subagent` only. The only other `allowedModels` / `subagent/model-selection-policy` hits are inside an embedded type-declaration string in `dsh-agent-team/lib/typert.host.js`, not enforcement. `dsh-workflow-ptc` and `dsh-tool-workflow` have no hits at all |
| Only *explicit* routes are checked | `requestedAgentOptions()` starts with `if (!hasDelegationModelRequest(request)) return configured;` — omitting all three route fields inherits the parent route with no validation |
| The policy is a frozen session snapshot | `subagent/model-selection-policy` is a log-only event appended before the first model request; `model-selection-state.ts` takes the first one. This is the "Applies only to new sessions" line on the settings page |
| Discovery is filtered by the same snapshot | `dsh-tool-subagent/README.md`: "With a recorded policy, provider model lists intersect the advertised catalog with the Session's authorized routes… Execution independently enforces the same policy." Unauthorized lookups fail with `LLM provider "…" is not allowed for this Session` |
| Host settings owner | `/usr/lib/node_modules/@deepseek-ai/dsh/docs/subsystems/subagent.md`: `ctx.subagentModelSelection` — "Host settings owner that records Session authorization before the first model request" |
| Local config | `dsh-market/profile-backup.json` lines 245–267: `- id: subagent-model-selection-settings`, `enabled: true`, eight `allowedModels` entries |

**The three gaps a plugin must close**

1. **Pure inheritance.** No `provider`/`model` in the call → child silently runs the parent's
   route, which may not be in the allowlist. Native code never checks it.
2. **Other child-Agent creation paths.** `workflow`'s `agent()` and Agent Teams spawn through
   `ctx.subagents.startActivation()` / `start()` / `startContinuable()`, never through the
   `subagent` tool's validator. Confirmed upstream in
   [discussion #13257 "workflow agent() does not consult the subagent model-selection policy"](https://github.com/deepseek-ai/deepseek-harness/discussions/13257).
3. **Snapshot staleness.** Editing the allowlist does not affect already-open sessions; a model
   published mid-session is reported as `not allowed for this Session` by
   `list_subagent_models` even though it is now in the list, and the official `subagent`
   tool keeps validating against the frozen policy.

---

## Shortlist

| Plugin | Mechanism | Coverage | Fit for 0.2.2-rc.5 |
| --- | --- | --- | --- |
| [`a-molecule-of-ATP/dsh-subagent-model-guard`](https://github.com/a-molecule-of-ATP/dsh-subagent-model-guard) v0.2.1 | Live read of `subagentModelSelection.current().allowedModels`; gate at `agent/created` and/or wrapped `ctx.subagents` + `tools/pre-execute` | `subagent`, `subagent_fork`, workflow `agent()`, teams, **inherited routes** | **Recommended.** Design doc based on 0.2.2-rc.3; in the [GUI market catalog](https://awesome-dsh-plugin.com/p/a-molecule-of-ATP/dsh-subagent-model-guard/) (added 2026-11-20) |
| [`Rayzenchen/dsh-workflow-model-guard`](https://github.com/Rayzenchen/dsh-workflow-model-guard) v1.0.0 | Prompt section + `tools/pre-execute` deny on `workflow` scripts | workflow only | **Exact match** — README says tested on DSH 0.2.2-rc.5. Heuristic static scan; defense-in-depth, not a replacement |
| [`dsh-subagent-model-guard` 0.1.0 (npm / mimajiushi)](https://dshhub.org/en/plugins/mimajiushi/dsh-plugins--plugins-dsh-subagent-model-guard/) | Wraps `ctx.subagents.start` / `startContinuable` + `ctx.tools.guard` | All creation paths incl. Agent Teams and inheritance | **Avoid.** `dsh.engines` is `<0.2.0`; built for 0.1.5-rc.1; docs reference the removed `@nanmicoder/dsh-agent-teams` |

---

## Detail

### 1. a-molecule-of-ATP/dsh-subagent-model-guard — recommended

- Repo / [market catalog entry](https://awesome-dsh-plugin.com/p/a-molecule-of-ATP/dsh-subagent-model-guard/)
  / [DESIGN.md](https://github.com/a-molecule-of-ATP/dsh-subagent-model-guard/blob/main/DESIGN.md)
  (v0.3 draft, 2026-11-17, "based on DSH 0.2.2-rc.3") /
  [docs/DETAIL.md](https://github.com/a-molecule-of-ATP/dsh-subagent-model-guard/blob/main/docs/DETAIL.md)
  / [VENDORED.md](https://github.com/a-molecule-of-ATP/dsh-subagent-model-guard/blob/main/VENDORED.md).
  `@local/dsh-subagent-model-guard`, v0.2.1, MIT, ★0, no npm publish.
- **Single source of truth.** It keeps no list of its own — on every dispatch it reads DSH's
  official `subagentModelSelection.current().allowedModels`, so the Settings → Subagent page
  remains the only place to configure; removing a model there blocks it immediately. No
  wildcards, no blacklist.
- **One rule, all paths.** The child's *actual* `provider/model` (explicit or inherited from
  `agent.options`) must hit an allowed route exactly. `enforcement` picks the checkpoint:
  `agent-created` (stable contract, covers workflow `agent()`, but a refusal leaves an empty
  session record), `start-activation` (refuses before construction, zero residue, depends on
  the internal `internal/get` hook), or `both`. A `tools/pre-execute` layer gives readable
  denial reasons for `subagent` / `subagent_fork`; denial text names the rejected route and
  can list the allowed ones.
- **Eight volatile settings** (take effect without reload): `strict` (master switch),
  `includeAllowedListInError`, `recentDenialLimit` (in-memory only, never persisted),
  `auditDedupeMs`, `enforcement`, `replaceListModelsTool`, `replaceSubagentTool`,
  `auditEveryStep`. `guard_selfcheck` is a read-only diagnostic that answers whether a given
  `"provider/model"` would be allowed right now, without dispatching.
- **Snapshot bypass (optional).** `replaceSubagentTool` shadows the official global `subagent`
  tool with one that calls `ctx.subagents.startActivation()` directly, so newly published
  models work in old sessions; `replaceListModelsTool` makes `list_subagent_models` answer
  from current settings instead of the frozen snapshot. `subagent_fork` is deliberately not
  replaced (different fork-provider semantics), and the replacement supports only `spawn`.
- **Fail-open by design.** No restriction when the official list is empty, official `enabled`
  is off, or the service is unavailable — matching DSH's native behavior.
- **Caveats.** Vendored `@deepseek-ai/schemastery` 3.19.0 and `cosmokit` 1.9.0 are unmodified
  copies from the running harness; VENDORED.md says **link install only** — a git/registry
  install drops `node_modules` and breaks the settings form — and they must be re-extracted
  after a DSH upgrade. Turning a replacement switch on mid-session does not retrofit already
  existing agents. `agent-created` refusals leave an empty session record. New, unstarred
  project; no independent verification yet.
- **Install spec (from the market catalog):**
  `dsh plugin --profile web add github:a-molecule-of-ATP/dsh-subagent-model-guard` — but
  prefer a `link:` install per VENDORED.md so the vendored deps survive.

### 2. Rayzenchen/dsh-workflow-model-guard — exact-version complement

- [Repo / README](https://github.com/Rayzenchen/dsh-workflow-model-guard), v1.0.0, MIT,
  zero-config. Install: `dsh plugin --profile web add github:Rayzenchen/dsh-workflow-model-guard`.
- Extends the same official allowlist to the `workflow` path with two layers: a system-prompt
  section (rendered only when the `workflow` tool is visible to that agent) telling the model to
  call `list_subagent_models` first and pick only from authorized routes, and a
  `tools/pre-execute` waterfall gate that denies a script whose `agent()` names an off-list
  route — the denial reason names the illegal route (with line and source fragment), lists the
  allowed routes, and offers two fixes (`list_subagent_models` or omit the fields).
- Reads the session projection `subagentModelSelectionPolicy` first, falling back to the
  settings service; a `null` projection means no restriction, deliberately aligning with the
  native `subagent` path.
- **Limitations, stated in its own README:** the hard layer is a **lexical heuristic**, not a
  guarantee — it never evaluates the script. Runtime-computed routes, variables, `args`-supplied
  routes and string-built `agent` calls are invisible; `unresolvedRoute` defaults to `allow`.
  It does **not** cover inherited routes or Agent Teams. Complete coverage would require
  wrapping `ctx.workflowEngine` at `startChild`, which the author lists as future work.
  Reasoning-effort validation is likewise out of scope.
- Ships `node tools/self-test.mjs` (58 checks) and a `VERIFICATION.md` acceptance record.

### 3. mimajiushi/dsh-plugins — npm `dsh-subagent-model-guard` 0.1.0 — not for this host

- [DSH Hub listing](https://dshhub.org/en/plugins/mimajiushi/dsh-plugins--plugins-dsh-subagent-model-guard/)
  (version 0.1.0, MIT, last updated 2026-09-27, compatibility "Unverified"),
  [npm registry metadata](https://registry.npmjs.org/dsh-subagent-model-guard),
  [repo](https://github.com/mimajiushi/dsh-plugins).
- Conceptually the most complete design: it wraps the *single* operation that creates a child —
  `ctx.subagents.start` / `startContinuable` — so `subagent`, `subagent_fork`,
  `agent_teams_*`, `workflow` and `ralph` all pass the gate, **including pure inheritance**.
  A second `ctx.tools.guard` layer rejects out-of-list routes before team records are written.
  Denials include the rejected route, the full allowed list and where to change it.
- **Why not here.** Its `dsh.engines` is
  `>=0.1.5-rc.1 <0.1.6-0 || >=0.1.6-rc.1 <0.1.7-0 || >=0.1.7-rc.1 <0.2.0-0` — i.e. **<0.2.0**.
  The parent repo README says the plugins were "written for, and are verified against, `dsh`
  0.1.5-rc.1 on Windows", and this plugin's README names `@nanmicoder/dsh-agent-teams`, a
  package the rc.2+ host-shipped Agent Teams replaced. Install spec from the Hub pins a commit:
  `npx -p @deepseek-ai/dsh dsh plugin --profile web add github:mimajiushi/dsh-plugins#1aa8b9d851070af475ca10703d84c000562ef8d7&path:plugins/dsh-subagent-model-guard`.
  Treat as a design reference, not an install candidate on rc.5.

### 4. Adjacent plugins, not selected

- [`SeverusZh/dsh-plugin-subagent-director`](https://github.com/severuszh/dsh-plugin-subagent-director) —
  per-subagent provider/model with role templates; docs say explicit routes must come from the
  official `allowedModels` and unauthorized defaults are refused, but it is a **replacement
  delegation tool**, not a pure guard.
- [`nobodyhere34/dsh-session-subagent-models`](https://github.com/nobodyhere34/dsh-session-subagent-models) —
  per-session editable allowlists that override the global snapshot; self-described
  "experimental / known design flaws / not maintained".
- [`dsh-dev-plan-presets`](https://awesome-dsh-plugin.com/p/hongcha-dsh/dsh-dev-plan-presets/) —
  a preset with a built-in "subagent model guard" that pins every child to one configured route;
  it is an agent preset, not a general allowlist enforcer (and its market description warns its
  HTTP routes lack DSH access checks).
- Generic tool-denial machinery ([kouyichi/dsh-plugins dsh-guard](https://github.com/kouyichi/dsh-plugins),
  [truelove-dreamer/dsh-plugin-hooks](https://github.com/truelove-dreamer/dsh-plugin-hooks),
  [OPaimon/dsh-model-gate](https://github.com/OPaimon/dsh-model-gate)) could be configured to
  deny `subagent` calls or hide models, but none of them reads the official
  `subagent-model-selection` allowlist, so they would duplicate policy in a second place.

---

## Operational notes if this is ever installed

- **Keep "Allow agents to choose models for Subagents" ON** with a curated list. The guard is
  deliberately fail-open when the official list is empty or the setting is disabled — switching
  the toggle off would *remove* enforcement, not strengthen it.
- **Strict mode pins the parent too.** If the parent session's own model is not in the
  allowlist, plain inherited subagents are denied as well. List the parent route.
- Suggested config: `strict: true`, `enforcement: both`, replacement tools off unless the
  session-snapshot problem actually bites.
- Installing changes the live `web` profile (one dependency + one bundle row) and requires a
  DSH restart; host-side plugin code loads at boot. Re-verify the profile backup afterward.

---

## Sources

Local (installed harness and this repo):

- `/usr/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-tool-subagent/` —
  `lib/index.js`, `src/model-selection.ts`, `src/list-models.ts`,
  `src/model-selection-settings.ts`, `src/model-selection-state.ts`, `README.md`
- `/usr/lib/node_modules/@deepseek-ai/dsh/docs/persistence-catalog.md` —
  `subagent/model-selection-policy` (log-only)
- `/usr/lib/node_modules/@deepseek-ai/dsh/docs/subsystems/subagent.md` —
  `ctx.subagentModelSelection`, `resolveMaxDepth`, `startActivation`
- `/usr/lib/node_modules/@deepseek-ai/dsh/docs/tool-catalog.md` —
  `list_subagent_models`, `@deepseek-ai/dsh-tool-subagent` row
- `dsh-market/profile-backup.json` — `subagent-model-selection-settings` patch row
- `.research/2026-10-24-subagent-model-routing-market-scout.md` — companion scout

External:

- <https://github.com/deepseek-ai/deepseek-harness/discussions/13257>
- <https://github.com/a-molecule-of-ATP/dsh-subagent-model-guard>
- <https://awesome-dsh-plugin.com/p/a-molecule-of-ATP/dsh-subagent-model-guard/>
- <https://awesome-dsh-plugin.com/plugins.json> (dshmarket GUI catalog)
- <https://github.com/Rayzenchen/dsh-workflow-model-guard>
- <https://dshhub.org/en/plugins/mimajiushi/dsh-plugins--plugins-dsh-subagent-model-guard/>
- <https://registry.npmjs.org/dsh-subagent-model-guard>
- <https://github.com/mimajiushi/dsh-plugins>
- <https://github.com/severuszh/dsh-plugin-subagent-director>
- <https://github.com/nobodyhere34/dsh-session-subagent-models>
- <https://dshpluginhub.ai/en/plugins/dsh-plugin-team-model-routing> ("Pure inheritance is never
  restricted" — search snippet only; page is client-rendered)

---

**Status:** recommendation only. No plugin installed, no profile file edited, no bundle row
changed. 23 dependencies / 25 bundles unchanged.
