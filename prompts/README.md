# Prompts

The prompt text carried by the agent presets in `../agent-presets/`, extracted
verbatim so the wording can be read and revised without wading through the
compositions.

| File | Preset | Row it comes from |
| --- | --- | --- |
| `custom-persona.md` | `custom` | `persona.config.prefix` + `persona.config.suffix` |
| `coding-persona.md` | `coding` | the same rows, with a longer suffix |
| `plan-mode.md` | both (byte-identical) | `planning` → `plan-mode` → `config.section` |

## Persona

`@deepseek-ai/dsh-persona` composes the agent's system prompt as `prefix`,
then the harness's own guidance, then `suffix`. `{{model}}` and `{{cwd}}` are
substituted per agent, so the same file serves every model and workspace.

- **prefix** — the one-line identity statement.
- **suffix** — the working directory line, the instruction to prefer
  composing multi-step work into a single `run_code` program, and (in
  `coding`) the engineering contract.

## Plan mode

The `section` of the `plan-mode` row inside the `planning` group. It is the
text injected while an agent is in plan mode: explore first, do not mutate,
and submit a decision-complete plan through `exit_plan_mode`. Both presets
carry the identical 2340-character text.

It is stored here dedented, as YAML block scalars are read; re-embedding it in
a preset needs the block-scalar indentation restored (14 spaces under
`section: |` in the current files).

## Editing

The live files under `$DSH_HOME/.agent-presets/` are what actually runs — the
copies in `../agent-presets/` and here are the record. Edit a preset there,
then re-copy the preset and re-extract these files so the two stay in step.
