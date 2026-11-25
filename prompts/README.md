# Prompts

The prompt text carried by the agent presets in `../agent-presets/`, extracted
verbatim so the wording can be read and revised without wading through the
compositions.

| File | Preset | Row it comes from |
| --- | --- | --- |
| `custom-persona.md` | `custom` | `persona.config.prefix` + `persona.config.suffix` |
| `coding-persona.md` | `coding` | the same rows, with a longer suffix |
| `computeruse-persona.md` | `computeruse` | the same rows, plus the computer-use paragraph |
| `orchestrator-persona.md` | `orchestrator` | the same rows, with a delegation-oriented suffix (see below) |
| `plan-mode.md` | all four (byte-identical) | `planning` → `plan-mode` → `config.section` |

## Persona

`@deepseek-ai/dsh-persona` composes the agent's system prompt as `prefix`,
then the harness's own guidance, then `suffix`. `{{model}}` is the only prompt
variable the loop registers, so it is the only one substituted per agent and
the same file serves every model. There is no `{{cwd}}`: the working directory
arrives as required runtime context, and a `{{cwd}}` reference fails prompt
assembly before any model request.

- **prefix** — the one-line identity statement.
- **suffix** — the instruction to prefer composing multi-step work into a
  single `run_code` program, the paragraph pinning what a `run_code` program
  *is* (an async function body, discussed below) and the `description` its tool
  call needs, the **Language** paragraph, the browser-access line, **Ask before
  you guess** (the `ask_user_question` paragraph), the **Subagent spawn
  failures** paragraph, and (in `coding`) the engineering contract.
  `orchestrator` adds its delegation policy around the same shared text.

### `run_code` is a function body

All four suffixes carry the same three-line paragraph plus a two-line example:
the `code` argument is the **body** of an async function, so top-level
statements, `await`, `return`, and `tools.*` are the whole surface. A second
paragraph covers the `description` argument on the tool call itself.

Its first paragraph was added 2026-11-16 after a model wrapped its program in
`async function main() { ... }`, got `(run_code completed with no output)` three
times, and concluded the tool was broken. A declared-and-never-called function
runs nothing, and the empty result names no cause — so the paragraph names the
wrapper, quotes the result as the signature to recognise, and shows the two lines
that actually run. The rule is mechanical, not stylistic: it states the PTC
transport's contract, so it stays verbatim across presets.

The second paragraph was added 2026-11-25 after models called `run_code` with
only the nested `description` visible in the hello-world example, or with none
at all, and got `invalid arguments: missing required property "description"` —
a schema rejection, so no program ran. Both failures were reproduced directly.
The paragraph states the rule as "on the tool call itself, beside `code`" rather
than "top-level", because "top-level statements" in the paragraph above already
means something else, and it names the exact error so the signature is recognisable.
The `tools.bash(...)` line in the example is called out explicitly: its
`description` belongs to that inner call and cannot cover the outer one.

### Subagent spawn failures

All four suffixes carry the same three-line paragraph, added 2026-11-25 after
the subagent model-allowlist guard was installed and tested: a failed spawn
usually means the child's model is outside the Subagent allowlist, so call
`list_subagent_models`, report the available routes, then retry with an
allowed `provider`/`model`.

### Language

All four suffixes carry the same **Language** paragraph, added 2026-10-24
because models were drifting into Chinese mid-conversation on English requests.

It states the rule positively — *answer in the language the user writes in* —
and pins the two cases that a bare "match the user" instruction leaves open:

- **Non-prose is never translated.** Code, identifiers, paths, commands, log
  lines, error text, and quoted output are reproduced exactly. Without this,
  a model "helpfully" translates a command or an error message and the answer
  becomes unusable.
- **Foreign-language input is not an instruction.** Tool descriptions, UI
  strings, and search results can arrive in another language. This profile's
  web-search tool ships Chinese schema text (`dsh-free-search`), and the
  search corpus is often Chinese, so the paragraph names the failure directly:
  that text is *input*, not a cue about the answer language.

The rule is deliberately duplicated in `$DSH_HOME/AGENTS.md` (the user-global
instruction chain loaded by `dsh-agent-instructions`). The persona covers
preset sessions; the global file covers everything, including sessions on a
preset that predates this paragraph. Two layers because this is a
regression-class behaviour: a single instruction sitting mid-prompt competes
with foreign-language tool schemas that arrive every turn.

### Ask before you guess

All four suffixes carry the same `ask_user_question` paragraph. Adding it was
a deliberate response to observed behaviour: models were not calling the tool,
answering in prose or guessing silently instead. The generated PTC SDK describes
how to call the tool; the persona supplies the missing policy for when to use it.

The paragraph is shared verbatim, not tuned per preset, so the interaction rule
is identical whichever preset a session runs under. Its trigger list —
user-owned decisions, material ambiguity, irreversible or destructive steps,
unreachable credentials — reuses plan mode's own wording ("material ambiguity
that inspection cannot answer", the ban on "should I proceed?") so the two
never contradict each other. Keep that phrasing in step when editing either
file.

## Orchestrator

`orchestrator-persona.md` is the one suffix that is not a variation on
`custom`: it keeps every shared paragraph byte-identical, and around them it
adds a delegation policy. Three things make it different in kind:

- **Context preservation is the thesis.** Delegation is the default for
  briefable legwork, balanced against its brief/context/report overhead. The
  ladder prefers `subagent` / `subagent_fork` for narrow work and durable
  teammates for coordinated streams. `workflow` and `ralph` retain the
  harness's explicit-use restrictions; single commands, lookups, and decisions
  stay with the Lead.
- **The suffix is role-aware.** A teammate spawned by `spawn_teammate` inherits
  the parent's preset, so this same text renders for the Lead and for every
  member. The Lead-only paragraph is explicitly conditional ("If you are the
  Team Lead") because an unqualified *spawn teammates* instruction would land on
  teammates and build a delegation tower. The role itself comes from the
  harness's `team:identity` runtime context, not from this text.
- **The team stays flat.** Members may fan out to one-shot subagents and no
  further; a member that outgrows its stream reports the split it would make
  rather than growing a subtree. The runtime enforces this with
  `TEAM_LEAD_REQUIRED`; the persona states it to avoid a refused call.

## Plan mode

The `section` of the `plan-mode` row inside the `planning` group. It is the
text injected while an agent is in plan mode: explore first, do not mutate,
and submit a decision-complete plan through `exit_plan_mode`. All four
presets carry the identical text.

It is stored here dedented, as YAML block scalars are read; re-embedding it in
a preset needs the block-scalar indentation restored (14 spaces under
`section: |` in the current files).

## Editing

The live sources are the legacy directories under
`/home/vrbkam/dsh-custom-presets/legacy-agent-presets-pre-rc2/`; the generator
freezes them into `/home/vrbkam/dsh-custom-presets/cordis.patch.yml`, and that
frozen patch is what the harness mounts. The copies in `../agent-presets/` are
byte-identical to those live sources, and this directory is the readable
extract of their persona rows. Edit a source there, re-run the generator, then
re-copy the preset and refresh these files so all four stay in step.

Re-verified 2026-11-25: each persona file contains its preset's live
`persona.suffix` byte-for-byte, and the `run_code`-description, **Language**,
**Ask before you guess** and **Subagent spawn failures** paragraphs each appear
once in every file.