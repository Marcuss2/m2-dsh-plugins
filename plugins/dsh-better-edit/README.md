# dsh-better-edit

## What it is

Hashline editing for DSH agents: the community plugin `dsh-better-edit`
(npm, Rianico/dsh-better-edit, v0.3.1 at record time; **0.4.1 installed** on
the 2026-08-28 restore) replaces the stock
`read`/`edit` tool behavior with the **hashline** algorithm from the
oh-my-pi (omp) ecosystem — every line is addressed by a 3-char content hash,
edits target hash ranges, stale/unseen anchors are hard-rejected with fresh
anchors returned, and up to 32 same-file edits apply atomically.

Tools it provides:

- `read` — returns `HASH│content` lines (offset/limit paging); the hash *is*
  the line address.
- `edit` — `{ "path", "edits": [[fromHash, toHash, replacement], …] }`;
  batched, atomic, diff with fresh anchors in the result.
- `undo_last_edit`, `read_skill` (plain read for skill files).

The stock `write` tool remains for creating brand-new files — hashline's own
docs say it doesn't pay off there. Writes go through `ctx.fs`, so the DSH
sandbox/approval policies still apply.

## Why this plugin (checked per ground rule 1)

Candidates found via GitHub/npm search for DSH + hashline:

- **`dsh-better-edit`** (★15) — chosen: most mature; native TS implementation
  of the hashline algorithm (same algorithm as upstream, benchmarked vs OMP:
  −40…−55% edit tokens, 23/23 correctness battery); zero-config install;
  sandbox-aware.
- `dsh-tool-hashline` (InklingYoshi584, ★2) — hash-anchored read/edit/grep,
  but needs a hand-authored preset shadowing `tool-fs`.
- `dsh-hashline` (mouyase, ★0) — wraps a third-party hashline binary (not the
  official omp library); 6 separate tools.

## Dependencies

Tracked centrally in `DEPENDENCIES.md` (row `dsh-better-edit`). Requires
Node `^22.19.0 || >=24.0.0` (dsh's own requirement) and a dsh profile.

## Install

```sh
dsh plugin --profile web add dsh-better-edit
# no global dsh: npx @deepseek-ai/dsh plugin --profile web add dsh-better-edit
```

This pnpm-installs the package into `$DSH_HOME/profiles/web/` AND adds it to
`dsh.profile.bundles` in the profile's `package.json` — no manual composition
editing. Confirm the layer: `dsh --profile web --dump-config` shows a
`# == dsh-better-edit` layer.

When restoring the whole kit, this add joins the single batched command in
`../README.md` (never run installs concurrently against the profile) and
`../../setup/verify.sh` checks the dependency, the bundle entry, and the composed
layer in one pass.

## Activation

Composition is fixed per session: **only new sessions** get the hashline
tools; already-running sessions keep the stock tools until restarted.

## Verify (in a new session)

1. `read` any text file — output lines are `HASH│content`.
2. Make an edit — the `edit` call uses hash ranges and the result shows a
   diff with fresh anchors.
3. Send a stale hash — expect `[E_RANGE_STALE]`/`[E_RANGE_UNSERVED]`
   rejection with fresh anchors echoed (no file corruption).

## Remove

`dsh plugin --profile web remove dsh-better-edit` (or delete the dependency
and the bundle entry from the profile's `package.json`).
