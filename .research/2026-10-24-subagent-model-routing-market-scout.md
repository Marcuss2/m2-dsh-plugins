# Subagent Model Routing — Market Scout

**Date:** 2026-10-24
**Scope:** npm + GitHub survey for a DSH plugin that (a) lets the **model** choose a subagent/teammate
model and (b) lets the **user** attach free-text descriptors per model ("good general all-rounder",
"good at reviewing/critiquing") that the model can read when choosing.
**Method:** npm registry search API (12 query terms + 9 keyword sweeps), direct package metadata +
README inspection for every candidate, download counts from `api.npmjs.org`, GitHub repo search.
**Host baseline:** locally installed `@deepseek-ai/dsh` is **0.2.1-rc.2**. Installability judgments
below are against that version.
**Constraint:** research only — nothing was installed, no profile was modified.

---

## Shortlist

| Package | Version | Last publish | DL/mo | What it actually does | Fits descriptor need? | peerDeps / core range |
|---|---|---|---|---|---|---|
| [dsh-subagent-router](https://www.npmjs.com/package/dsh-subagent-router) | 0.6.0 | 2026-10-02 | 703 | `subagent_model` tool → model picks provider/model/max_tokens per call; `subagent_models` catalog; `model:"auto"` policy; `subagent_recommend` LLM classifier | **partial** — model choice: yes. Catalog metadata is **derived** (cost/speed/strength/specialty heuristics), **not user-authored** | `@deepseek-ai/dsh-*` `^0.2.0-rc.2` — ✅ compatible |
| [dsh-subagent-library](https://www.npmjs.com/package/dsh-subagent-library) | 0.3.5 | 2026-10-17 | 2,413 | Named subagent roster (one YAML per role): `description`, `provider`, `model`, persona, depth. `list_subagents` shows model+description to the model; `delegate` dispatches by id | **partial (best functional fit)** — user free-text yes, but keyed to a **role** that binds a model, not to the model itself | `@deepseek-ai/cordis ^4.0.1` only; README badge DSH 0.2.1-rc.2 — ✅ |
| [@aiwayds/dsh-subagent-registry](https://www.npmjs.com/package/@aiwayds/dsh-subagent-registry) | 0.14.1 | 2026-10-19 | 3,468 | `~/.dsh/agents/*.md` frontmatter (`description`, `model`, `thinking`) registered as subagents; `use_agent`/`ask_agent`; full Web management page; bundled skill | **partial** — same role-keyed shape as library; ships 3 presets (workhorse/oldfox/rubber-duck) already annotated "advisor, review/critique" | `>=0.2.0-rc.2 \|\| >=0.2.1-rc.1` (optional peers) — ✅ |
| [@neptune810/dsh-model-router](https://www.npmjs.com/package/@neptune810/dsh-model-router) | 0.14.2 | 2026-10-04 | 5,019 | Model pool + per-step routing; user authors **per-model `weights`** per task preset, plus `cost`, `tags`, `tier` | **partial** — user-authored per-model, but **numeric weights/tags**, no free text | none declared — ✅ |
| [dsh-subagent-conductor](https://www.npmjs.com/package/dsh-subagent-conductor) | 0.2.9 | 2026-10-17 | 1,060 | Settings/routing layer **over the official** `subagent` tool: per-root-session provider/model/effort in composer, role templates, global default | **no** — routes only; docs state roles "do not carry persona… v0.2" | none declared — ✅ |
| [dsh-plugin-subagent-roles](https://www.npmjs.com/package/dsh-plugin-subagent-roles) | 0.5.0 | 2026-10-17 | 1,835 | File-defined roles (`.dsh/roles/*.md`) with `description` + `provider`/`model` + tool filter + tool-call budget; compact catalog injected into prompt | **partial** — user free-text `description` per role, model sees it; again role-keyed | `^0.2.1-rc.1` — ✅ |
| [dsh-subagent-default-model](https://www.npmjs.com/package/dsh-subagent-default-model) | 2.1.8 | 2026-10-24 | 3,315 | Default model for subagents: ordered/random multi-model assignment, cross-provider failover, route shown in trajectory | **no** — no model-facing choice, no descriptors | `>=0.1.7-rc.1 <0.3.0-0` — ✅ |
| [dsh-subagent-profile](https://www.npmjs.com/package/dsh-subagent-profile) | 0.5.1 | 2026-09-03 | 1,065 | `dispatch` tool over named "profiles" (preset+model+effort+tools), cost estimates, decision ledger, `orchestrator-v2` preset | **no** — profiles bundle a model but descriptions aren't surfaced for model choice | `>=0.1.0-rc.6 <0.2.0` — ❌ **incompatible** with 0.2.1-rc.2 |
| [@pure01fx/dsh-subagent-tiers-hu](https://www.npmjs.com/package/@pure01fx/dsh-subagent-tiers-hu) | 0.3.1 | 2026-10-09 | 815 | Per-tier (fast/pro) route pinning, editable `description` + persona, immutable route revisions | **partial** — editable tool description, but route is fixed per tier, model doesn't choose | exact `0.2.0-rc.2` — ⚠️ pinned below installed |
| [dsh-subagent-workspace-ui](https://www.npmjs.com/package/dsh-subagent-workspace-ui) | 1.10.0 | 2026-10-08 | 2,209 | *(already installed)* searchable workspace subagent manager, read-only monitoring UI | **no** — UI-only, no model choice, no descriptors | `@deepseek-ai/cordis ^4.0.1` — ✅ |
| [dsh-model-switch](https://www.npmjs.com/package/dsh-model-switch) | 0.4.42 | 2026-10-24 | 1,989 | Explicit model routing + composer/Plan picker; injects route before subagent descriptor creation | **no** — human-facing picker, no per-model notes | `>=0.1.7-alpha.2` (37 peers) — ✅ |
| [dsh-model-picker](https://www.npmjs.com/package/dsh-model-picker) | 1.0.2 | 2026-08-15 | 939 | Prettier provider-tabbed model picker; searches provider/model/**description** from the live catalog | **no** — reads catalog descriptions, doesn't author them | `@deepseek-ai/cordis *` — ✅ |
| [dsh-plugin-model-capability](https://www.npmjs.com/package/dsh-plugin-model-capability) | 1.4.0 | 2026-09-27 | 1,684 | Per-model editor: context window, output cap, modalities, thinking levels, gateway compat | **no** — capability fields only, no free-text notes | `dsh-settings >=0.1.7-rc.2 <0.2.0` — ⚠️ |
| [dsh-model-extension](https://www.npmjs.com/package/dsh-model-extension) | 1.3.3 | 2026-10-17 | 2,504 | Models+ settings page: per-model reasoning efforts, modalities, compat flags, models.dev prefill | **no** — same, capability not descriptor | `^0.2.1-rc.2` — ✅ |
| [dsh-subagent-codex-pro](https://www.npmjs.com/package/dsh-subagent-codex-pro) | 0.6.2 | 2026-10-17 | 2,521 | Codex delegation carrying model + reasoning effort per call | **no** — Codex-only, no catalog/descriptors | none declared — n/a |

---

## Detail

### 1. dsh-subagent-router — closest on "model chooses", wrong shape on "user notes"

- npm: <https://www.npmjs.com/package/dsh-subagent-router>
- registry: <https://registry.npmjs.org/dsh-subagent-router>
- repo: <https://github.com/NinjaSln-labs/dsh-subagent-router> (★2)
- readme: <https://github.com/NinjaSln-labs/dsh-subagent-router#readme>
- roadmap: <https://github.com/NinjaSln-labs/dsh-subagent-router/blob/main/docs/ROADMAP.md>

Three tools, this is the only candidate that gives the model a *model-selection problem* to solve:

- `subagent_model` — delegate with explicit `provider` / `model` / `max_tokens`; omitted fields inherit the parent route.
  `model: "auto"` hands the pick to a deterministic policy (task tiering trivial/standard/complex → anchor to parent,
  escalate to strongest, fail-over to a healthy provider).
- `subagent_models` — the catalog the model reads. Per model it annotates `cost` tier, `speed` tier,
  `strength` tier, `specialty`, `contextWindow`, plus per-route `health` / `failingClass` / `retryAfterSec`.
- `subagent_recommend` — task description → ranked top-n, via a lightweight LLM classifier bounded to ≤12 candidates,
  degrading to a naming heuristic.

**Why it is only partial:** every one of those annotations is **derived** by the plugin — from model-id substring
heuristics (`flash`/`mini`/`lite` → cheap; `pro`/`max`/`reason` → strong) and from a static price/context table.
There is no field anywhere in the config schema — neither the settings page nor the composition row — where a user
types prose about a model. The configurable knobs are `autoProviderOrder`, `autoTierPolicy`
(`anchor|cheapest|strongest`), `autoTierPicks` (explicit model id lists), `autoEscalate`, `autoReroute`,
`recommendTimeoutMs`. All routing decisions, no descriptive text.

Its own roadmap lists "目录元数据" (catalog metadata) as delivered in 1c — delivered as *derived* metadata.
A user-authored-descriptor layer does not appear on the roadmap.

**Installability:** peerDeps are `@deepseek-ai/dsh-{llm,jobs,agent,tools,settings,subagent,system-prompt}` at
`^0.2.0-rc.2`, plus client UI peers — satisfied by the installed 0.2.1-rc.2. Note it also peers on `react ^18.2.0`.

### 2. dsh-subagent-library — user free-text, but the note belongs to a role

- npm: <https://www.npmjs.com/package/dsh-subagent-library>
- registry: <https://registry.npmjs.org/dsh-subagent-library>
- repo: <https://github.com/MaRi23333/dsh-subagent-library> (★6)

**This is the candidate that most nearly satisfies the literal requirement, via a re-keying.**

Roster = one YAML file per named role in `~/.dsh/subagents/`:

```yaml
description: Kimi K3-256K 代码审查，支持图片视觉走查   # free text, user-authored
provider: kimi-coding
model: k3-256k
persona: |
  ...
maxDepth: 1
backgroundMode: continuable
```

- `list_subagents` → "*列出名册条目（id / 角色描述 / 模型）*" — the model receives **id + user-authored description + model**.
- `delegate` → dispatch by `library_id`.
- Settings page for visual editing, hot-reload, per-file YAML (commentable, versionable), legacy migration.

So the model does choose a model *by reading user-written prose*. The gap: the prose is attached to a **role**,
and the model is chosen indirectly (role → model). To emulate "per-model notes", the user would have to author one
role per model, e.g. `v41-flash.yaml` (`model: deepseek-v4.1-flash`, `description: good general all-rounder`) and
`glm53-reviewer.yaml` (`model: glm-5.3-flash`, `description: good at reviewing/critiquing work`). That works and is
arguably more useful (it also carries a persona + depth + background mode), but it is not a model catalog — you cannot
list every configured model and annotate it, and roles showing the same model duplicate the note.

**Installability:** peerDeps only `@deepseek-ai/cordis ^4.0.1`. README states 0.3.5 aligns with DSH `0.2.1-rc.2`.
Note the documented host limitation: on DSH ≥0.2.1 per-entry `toolFilter` **cannot be enforced** and entries carrying
it are refused — read-only role isolation must come from host permissions instead.

### 3. @aiwayds/dsh-subagent-registry — same shape, heavier, better UI, more popular

- npm: <https://www.npmjs.com/package/@aiwayds/dsh-subagent-registry>
- registry: <https://registry.npmjs.org/@aiwayds%2Fdsh-subagent-registry>
- repo: <https://github.com/fan56/dsh-subagent-registry> (★7)

`~/.dsh/agents/<name>.md` — frontmatter `name`, `description` (shown in the `use_agent` roster), `display_name`,
`model` (`provider/model`), `thinking` (off/low/medium/high/max), `deep`, `background`, `maxRounds`; body = system prompt.
Main model calls `use_agent(agent, prompt)`; `ask_agent` follows up. Ships a full **子智能体 management page** in the
Web sidebar, an injected delegation-guidance prompt that tells the model to prefer a roster role, and a bundled skill.

Notable: the three seeded agents are *already* described the way the user wants to describe models —
**workhorse** (does the work, defaults `deepseek-flash`), **oldfox** (advisor, "review 挑刺", `glm-5.3`),
**rubber-duck** (vision). That is very close to the stated use case, one layer up from the model.

Same gap: descriptor is role-scoped, not model-scoped. 0.14.1, 29 versions, 3,468 DL/mo — the most actively
maintained of the role-roster family. Peers are **optional** and deliberately so (documented rationale: hard
dependencies shadow the host closure and brick boot). Requires host session persistence + `sessionQuery`.

### 4. @neptune810/dsh-model-router — user-authored per-model, but numeric

- npm: <https://www.npmjs.com/package/@neptune810/dsh-model-router>
- registry: <https://registry.npmjs.org/@neptune810%2Fdsh-model-router>
- repo: <https://github.com/Neptune810/dsh-model-router> (★2)
- Highest downloads of any candidate: **5,019/mo**.

Model pool with genuinely user-authored per-model attributes:

```yaml
pool:
  - { id: deepseek-official/deepseek-v4-pro, cost: 8, tier: strong, maxPerTask: 3 }
  - { id: deepseek-official/deepseek-v4-flash-vision-exp, cost: 1, tags: [vision] }
  - { id: vendor-x/writer-pro, cost: 20, weights: { 小说续写: 95 } }
```

`weights: { <task preset>: <0-100> }` is the closest thing on npm to "how good is this model at X" authored by the
user, and it is *used by the router* to pick. But: numeric only, keyed to user-defined task presets, routing happens
**per step of the main session** — it does not expose a subagent-model choice to the model, and there is no prose
channel. Also controls composer model seat, so it conflicts structurally with the existing subagent-workspace-ui
only insofar as both want composer seats (they don't — workspace-ui is a sidebar panel; no conflict).

### 5. dsh-subagent-conductor — routing layer, explicitly no persona/descriptors

- npm: <https://www.npmjs.com/package/dsh-subagent-conductor> · repo <https://github.com/YrracOwl/dsh-subagent-conductor> (★1)

Precedence: root-session composer selection > default role route > global default > official tool selection >
native inheritance. Validates the exact provider/model pair through `llm.resolveModelInfo`. Masterfully careful
(never breaks stock delegation; fails closed; portable across the `settingsScope`→`configForms` rename).

Disqualifying line, from the README: *"Roles are route presets with display metadata. They do not carry persona or
tool filters… and conductor does not claim a runtime channel for them in v0.2."* So roles have a display name and a
model, but no prose surfaced for model-driven choice. This is a **human** routing layer, not a model-facing one.

### 6. dsh-plugin-subagent-roles — richest free-text role metadata, strong enforcement

- npm: <https://www.npmjs.com/package/dsh-plugin-subagent-roles> · repo <https://github.com/troytse/dsh-plugin-subagent-roles> (★1)

Markdown role files with `description` (*"目录里显示的一行描述，主代理据此判断要不要委派"*), `whenToUse`
(appended to the catalog line), `provider`/`model`, `reasoningEffort`, tool allow/deny with globs, and a **hard**
per-role tool-call budget counted from the framework's own `tool/call` events. Catalog injected as a prompt section:
`- <id> (<displayName>): <description>`.

This has the best *descriptor plumbing* of the role family (`description` + `whenToUse` + configurable truncation,
and unknown frontmatter keys are **rejected** rather than ignored). Still role-keyed; still no model catalog.
Caveat: role files are version-bound to the plugin (new keys make older plugin versions skip the whole file).

### 7. Notable rejections

- **dsh-subagent-profile 0.5.1** — peerDeps `>=0.1.0-rc.6 <0.2.0`. Cannot install alongside DSH 0.2.1-rc.2.
- **@pure01fx/dsh-subagent-tiers-hu 0.3.1** — peers pinned to exact `0.2.0-rc.2`; target is one rc below the host.
- **dsh-subagent-default-model 2.1.8** — very active (26 versions, 2026-10-24, 3,315 DL/mo) but it *assigns* a default
  model (sequential/random + provider failover) and injects one line of routing text into the child's context.
  No model-facing choice, no descriptors. It is the opposite of the requirement.
- **dsh-subagent-workspace-ui** (installed) — monitoring/browsing only. No selection, no annotation.
- **dsh-plugin-model-capability / dsh-model-extension / dsh-model-switch / dsh-model-picker** — model *configuration*
  (context window, modalities, effort, compat) and picker polish. No descriptive layer; the picker merely *reads* a
  `description` field off the live catalog, it never writes one.
- Reserved-but-empty names (`dsh-router`, `dsh-persona`, `dsh-subagent` at 0.0.1) are placeholder squats, not software.
- Probed and **not found** on npm: `dsh-model-notes`, `dsh-model-descriptor`, `dsh-model-strengths`,
  `dsh-model-catalog-notes`, `dsh-model-annotations`, `dsh-model-guide`, `dsh-model-hints`,
  `dsh-model-selection-notes`, `dsh-subagent-chooser`, `dsh-model-advisor`.
- GitHub-only, not on npm (so not `dsh plugin add <name>`-installable): `themarchrain/dsh-subagent-route`,
  `bpc-oss/dsh-routed-subagent`, `LittleAlety/dsh-team-conductor`.

---

## Verdict

**Nothing on npm implements the request as stated.** No package in the DSH ecosystem offers a per-model
**user-authored free-text descriptor** that is shown to the model so it can choose a subagent model by
"what this model is good at".

The capability splits cleanly into two halves that exist separately and have never been joined:

| Half | Who has it |
|---|---|
| Model-facing model choice + a catalog the model reads | `dsh-subagent-router` |
| User-authored free-text descriptors surfaced to the model | `dsh-subagent-library`, `@aiwayds/dsh-subagent-registry`, `dsh-plugin-subagent-roles` |

The nearest thing to a working answer today is **role-keyed, not model-keyed**: author one roster entry per model
with the prose you want the model to read. `dsh-subagent-library` is the tightest fit (single deprecated-free
`cordis` peer, per-virtual package, plain YAML you can grep and version) and `@aiwayds/dsh-subagent-registry` the
most polished (Web CRUD page, bundled skill, 3,468 DL/mo, optional peers).

If the requirement is genuinely *per-model* — one catalog of every configured model, each with your own
"general all-rounder" / "good at reviewing" note, visible to the model when it delegates — then it does not exist
and would have to be built. The cheapest path is a thin plugin on top of `dsh-subagent-router`'s
`subagent_models` catalog: add a user-authored `notes` map keyed by `provider/model` and emit it in the catalog
output next to the derived `strength`/`specialty` fields. That is one settings field and one render change on a
plugin that already does everything else, mounted against `^0.2.0-rc.2` peers.

---

## Evidence index

- npm search API: `https://registry.npmjs.org/-/v1/search?text=<term>&size=50` — terms used: `dsh subagent`,
  `deepseek harness`, `dsh plugin model`, `dsh-model`, `dsh-catalog`, `dsh-router`, `dsh-persona`,
  `dsh-subagent`, plus 9 descriptor-flavoured sweeps.
- Download counts: `https://api.npmjs.org/downloads/point/last-month/<pkg>` (window 2026-09-23 → 2026-10-22).
- GitHub search: `https://api.github.com/search/repositories?q=dsh+plugin+subagent` (215 results),
  `q=deepseek+harness+plugin` (8,395), `q=dsh-personas` (87), `q=dsh-plugin+masterprompt` (1).
- Local curated index consulted: `.research/awesome-dsh-plugin.md` (619 KB community plugin list).
