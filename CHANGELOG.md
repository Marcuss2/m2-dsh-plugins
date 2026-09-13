# Changelog

Dated record of changes to the live DeepSeek Harness setup on this machine.
The other directories hold the *current* state; this file holds how it got
there.

Keep the two in step: a change recorded in only one of them is a bug in the
record. Each entry states what changed, why, and the evidence — including
what was found to be *unchanged*, so a later reader can tell "verified
identical" from "not checked".

## 2026-09-13 — record refreshed against the live setup

Diffed the live machine against the 2026-09-11 capture (`50d8262`). Two
changes; everything else byte-identical.

### Fixed: `ui-git-graph` disabled in the profile patch layer

`$DSH_HOME/profiles/web/cordis.patch.yml` gained:

```yaml
- id: ui-git-graph
  disabled: true
```

The plugin `@linxin666/dsh-client-ui-git-graph@0.3.20` stays in both
`dependencies` and `dsh.profile.bundles` — only its loader row is switched
off, so the code stays installed but is never mounted.

Reason, from the comment written into the file itself and dated 2026-09-11:
the plugin polls every 30 s — several git spawns per tick, even for workspaces
that are not git repositories, each through a `systemd-run` scope — and a
`git status` round can stall up to `STATUS_TIMEOUT_MS` (15 s). Its
auto-isolation hook is already disabled by the current `dsh`
workspaces-service shape, so it was adding poll churn without its main
feature. It was switched off while investigating a slow workspace list at
boot. **Re-enable by deleting the entry** — the file says so in place.

### Changed: default model

`$DSH_HOME/settings.yaml` → `agent-default-model.model` moved from
`deepseek/deepseek-v4.1-flash` to **`z-ai/glm-5.3-flash`**. Provider
(`openrouter-custom`) and `reasoningEffort` (`high`) are unchanged, and all
three models remain declared in the `llm-pi-ai` provider block, so this is a
default switch rather than a provider change.

`settings.yaml` is not reproduced in this repository — it holds API keys — so
only the fact is recorded, in the root README's setup table.

### Verified unchanged

- Harness `@deepseek-ai/dsh` **0.1.5-rc.1**.
- **11 dependencies, 13 ordered bundles**; every installed plugin version
  identical to the 2026-09-11 record.
- Both agent presets (`custom`, `coding`) byte-identical to `agent-presets/`
  (`diff -q` clean), and the `prompts/` extraction still round-trips against
  the live YAML.
- `$DSH_HOME/AGENTS.md` and `$DSH_HOME/cordis.patch.yml` still absent.
- `dsh-market/profile-backup.json` regenerated: the only `files[]` entry that
  differs from the 2026-09-11 copy is `cordis.patch.yml`.

## 2026-09-13 — version currency sweep

`npm view <name> version` against every installed profile plugin. **Seven have
newer releases; none are installed.**

| Plugin | Installed | npm latest |
| --- | --- | --- |
| `@hytime/dsh-thinking-effort` | 0.2.4 | 0.2.4 |
| `@linxin666/dsh-client-ui-git-graph` | 0.3.20 | 0.3.22 |
| `@linxin666/dsh-client-ui-task-board` | 0.3.20 | 0.3.22 |
| `@vectorize-io/hindsight-coding-agents` | 0.5.4 | 0.6.0 |
| `dsh-better-edit` | 0.8.1 | 0.8.1 |
| `dsh-better-sidebar` | 0.19.1 | 0.19.1 |
| `dsh-context` | 0.49.4 | 0.51.1 |
| `dsh-lsp-actions` | 0.5.0 | 0.5.1 |
| `dsh-search-failover` | 0.3.9 | 0.3.9 |
| `dsh-subagent-workspace-ui` | 1.3.3 | 1.4.0 |
| `dshmarket` | 1.45.1 | 1.46.1 |

### Known blocker: `dsh-subagent-workspace-ui` upgrade

A market upgrade of this plugin on 2026-09-11T13:08Z failed and rolled itself
back:

```
info   update-rollback  dsh-subagent-workspace-ui: restored npm build v1.3.3
warn   update           dsh-subagent-workspace-ui: failed update command; previous build restored and verified
error  update           dsh-subagent-workspace-ui -> dsh-subagent-workspace-ui@1.3.4 exit=1
                        err=ERR_PNPM_UNUSED_PATCH: The following patches were not used: dsh-subagent-workspace-ui@1.3.3
```

The profile patches this plugin's client bundle to translate its hardcoded
Simplified-Chinese UI strings to English. The patch is pinned to 1.3.3, so pnpm
refuses to install any other version under it. **Upgrading means re-deriving
`patches/dsh-subagent-workspace-ui@<version>.patch` from the new
`lib/client.js` first** — the same instruction is in `pnpm-workspace.yaml`
beside the pin.

## 2026-09-11 — baseline

The repository replaced its former plugin-reproduction kit with this record, at
commit `50d8262` (pushed the same day). Captured: the `web` profile backup (11
dependencies, 13 bundles, profile config, and the pinned
`dsh-subagent-workspace-ui@1.3.3` patch), the `custom` and `coding` agent
presets verbatim, and the persona and plan-mode prompts extracted from them.
