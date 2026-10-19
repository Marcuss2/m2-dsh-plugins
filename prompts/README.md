# Prompts

The prompt text carried by the agent presets in `../agent-presets/`, extracted
verbatim so the wording can be read and revised without wading through the
compositions.

| File | Preset | Row it comes from |
| --- | --- | --- |
| `custom-persona.md` | `custom` | `persona.config.prefix` + `persona.config.suffix` |
| `coding-persona.md` | `coding` | the same rows, with a longer suffix |
| `plan-mode.md` | all three (byte-identical) | `planning` → `plan-mode` → `config.section` |

## Persona

`@deepseek-ai/dsh-persona` composes the agent's system prompt as `prefix`,
then the harness's own guidance, then `suffix`. `{{model}}` is the only prompt
variable the loop registers, so it is the only one substituted per agent and
the same file serves every model. There is no `{{cwd}}`: the working directory
arrives as required runtime context, and a `{{cwd}}` reference fails prompt
assembly before any model request.

- **prefix** — the one-line identity statement.
- **suffix** — the instruction to prefer composing multi-step work into a
  single `run_code` program, and (in `coding`) the engineering contract.

## Plan mode

The `section` of the `plan-mode` row inside the `planning` group. It is the
text injected while an agent is in plan mode: explore first, do not mutate,
and submit a decision-complete plan through `exit_plan_mode`. All three
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
re-copy the preset and refresh these files so all three stay in step.
