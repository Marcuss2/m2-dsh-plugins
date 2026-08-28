# dsh-better-reasoning-effort

## What it is

Reasoning-effort **and input-modality** configuration for third-party
(`llm-pi-ai`) models: the community plugin `dsh-better-reasoning-effort`
(npm, HaoyueQin/dsh-better-reasoning-effort, **0.2.3 installed** on
2026-08-28).

The DSH core `llm-pi-ai` adapter natively supports per-model
`reasoningEfforts` declarations (which thinking levels a model accepts and
the exact wire spelling for each), but the official Models page editor
deliberately hides that field. Consequences without this plugin:

- hand-declared custom-provider models get **no thinking-level picker** in
  the composer (`getSupportedThinkingLevels` short-circuits to `["off"]`);
- enabling levels meant hand-writing `reasoningEfforts` blocks into
  `settings.yaml`;
- hand-declared models are treated as **text-only** (`input` defaults to
  `["text"]`), so image attachments and the read-image tool refuse them.

This plugin restores both surfaces:

- **In-page injection** — an editor block appears inside the official Models
  page under each model row's disclosure (next to context window / max
  tokens), using the same `settings.mutate` contract as the official fields.
  Two sections: **Reasoning effort** (levels + per-level wire spelling) and
  **Input modalities** (image-input checkbox), one Apply/Reset pair.
- **Auto-adapt** — one click fills recommended levels and wire spellings
  from a built-in model knowledge base (DeepSeek V3/V4/R1, GPT families,
  Claude, Gemini, Grok, Qwen incl. the 3.8 generation, GLM incl. 5.2/5.3,
  Kimi, MiniMax and more — re-verified against vendor docs 2026-08) plus
  wire-protocol inference from the route (`openai-completions` /
  `openai-responses` / `anthropic-messages`), with source · confidence
  labels. Also works on unsaved rows (provider create card, new model rows)
  via staging; existing declarations are never overwritten.
- Host-side auto-fill backs the suggestions; a durable `inputUnset` marker
  lets a deliberate "no declaration" survive re-syncs.

It matters here because this machine's only LLM route is the custom
provider `llm-pi-ai → qwencloud` (Qwen 3.8, GLM-5.2, DeepSeek V4 family),
whose models are hand-declared and therefore had no reasoning levels at all.

## Why this plugin (checked per ground rule 1)

Candidates compared (npm metadata + GitHub READMEs, 2026-08-28) for
"custom provider offers no reasoning levels":

- **`dsh-better-reasoning-effort`** — chosen: edits inside the official
  Models page (no parallel UI), one-click auto-adapt whose knowledge base
  covers exactly this machine's model families, also fixes the hidden
  image-input modality, most actively maintained (0.2.3 published the day
  it was evaluated), peer ranges target this core line (`^0.1.1-rc.1`).
- `@hytime/dsh-thinking-effort` (0.1.8) — strong runner-up: dedicated
  settings page, gateway-value mapping (DSH `high` → wire `ultra`),
  subagent default effort, cordis-only peer dep, excellent docs. Pick this
  instead if subagent defaults or gateway remapping become the priority.
- `dsh-model-reasoning` (TikaFlow, 0.2.1) — zero-config auto-fill from
  models.dev; least control, no UI for per-model editing.
- `@chengwd96/dsh-thinking-effort` (0.1.3), `dsh-model-memory` (0.1.11),
  `@kingsunb/dsh-model-plus` (0.1.38) — peer ranges on the older
  `0.1.0-rc.x` core line and/or slower release cadence.

The separate complaint "built-in providers have hard-coded model lists" is
**not** fixed by this plugin (it only adds capability declarations). The
ecosystem answers there are `dsh-model-pro` (full llm-pi-ai lifecycle with
remote `GET /models` discovery) and `@goodandready/dsh-model-sync` (live
catalog sync with dry-run diffs); neither was adopted — the model list is
still hand-declared in `settings.yaml`.

## Dependencies

None beyond the dsh web profile — no machine-level software, so no
`DEPENDENCIES.md` row. Hygiene per ground rule 2: `@deepseek-ai/*` are
declared as `peerDependencies` only (`autoInstallPeers: false` is set in
the profile), so nothing core gets hoisted by this plugin. The profile's
`node_modules/@deepseek-ai/` gains nothing new beyond the pre-existing
same-version `schemastery`/`cosmokit` copies already shared with the other
plugins (WARN, not FAIL, in `setup/verify.sh` section 4).

## Install

```sh
dsh plugin --profile web add dsh-better-reasoning-effort@0.2.3
```

The explicit version matters: the profile runs pnpm with
`minimumReleaseAge`, and 0.2.3 was published the same day it was installed,
so a bare `add dsh-better-reasoning-effort` resolved to the older 0.2.2.
Adding the `@0.2.3` spec makes pnpm write the required
`minimumReleaseAgeExclude: dsh-better-reasoning-effort@0.2.3` entry into
`$DSH_HOME/profiles/web/pnpm-workspace.yaml` automatically. (On a future
restore the bare spec is fine once 0.2.3 is older than the minimum release
age — or keep the explicit spec, which is idempotent.)

This pnpm-installs the package into `$DSH_HOME/profiles/web/` AND adds it to
`dsh.profile.bundles` in the profile's `package.json` — no manual
composition editing. Confirm the layer: `dsh --profile web --dump-config`
shows a `# == dsh-better-reasoning-effort` layer.

When restoring the whole kit, this add joins the single batched command in
`../README.md` (never run installs concurrently against the profile) and
`../../setup/verify.sh` checks the dependency, the bundle entry, and the
composed layer in one pass.

## Activation

Bundle layers compose at boot: **restart `dsh --profile web`** after
installing. Running sessions keep their old state; the editor appears in
the Models page for every browser after the restart (client-side), and the
host-side auto-fill suggestion engine starts with the process.

## Verify (after restart)

1. Settings → Models → expand a `qwencloud` model row: the disclosure now
   contains **Reasoning effort** and **Input modalities** sections.
2. Click **Auto-adapt** on e.g. `qwen3.8-max`: levels and wire spellings
   fill in with a source · confidence line. Apply.
3. In the composer, select that model: the thinking-level picker now offers
   the declared levels instead of only `off`.
4. Send a short prompt with a non-`off` level and confirm the request
   succeeds (the gateway accepts the reasoning parameter).

## Remove

```sh
dsh plugin --profile web remove dsh-better-reasoning-effort
```

Declarations the plugin wrote (`reasoningEfforts` / `input` / `inputUnset`)
remain in `settings.yaml` and stay valid core schema — removal only takes
away the editor and the suggestion engine. Also delete the
`minimumReleaseAgeExclude` line from `pnpm-workspace.yaml` if no other
entry needs it.
