# m2-dsh-plugins — DeepSeek Harness reproduction kit

A self-contained kit that records one customized [DeepSeek Harness](https://github.com/deepseek-ai)
(DSH) setup — plugins, composition rows, presets, settings and ground rules —
so that any reasonable LLM agent, starting from a baseline DSH install, can
reconstruct it from this repository alone. No access to the original machine
is required.

The authoritative procedure is [`RESTORE.md`](RESTORE.md); the rules that
govern the setup are [`AGENTS.md`](AGENTS.md). Everything below is a summary.

## Prerequisites

- A stock DSH install (Web GUI, shipped presets, default policies). Node.js
  `^22.19.0 || >=24.0.0` with npm.
- A few machine-level dependencies (varies per system — distro, package
  manager, privileges). The full manifest with per-dependency install and
  verify commands is [`DEPENDENCIES.md`](DEPENDENCIES.md): `uv`, the
  `agent-browser` CLI, a reachable Hindsight memory server, pnpm build-script
  approval for the two native MCP binaries, and optional per-language
  debugger/LSP backends.

## Install — let `dsh` do it

This kit is designed to be installed *by* a DSH agent, not by hand:

1. Clone this repository anywhere (referred to as `$KIT`):

   ```sh
   git clone https://github.com/Marcuss2/m2-dsh-plugins.git
   ```

2. Open a DSH session with this directory as the workspace and tell the agent:
   **"Restore this setup following RESTORE.md."** It will read `AGENTS.md`
   (auto-loaded as workspace instructions), work through `DEPENDENCIES.md`
   first, install the user-global system prompt, then apply every entry under
   `plugins/` in index order and verify.

The same prompt works for any other capable coding-agent harness pointed at
this checkout.

### The core step, if you prefer the CLI

The eleven custom bundles land in **one** batched command (one resolution pass,
one atomic write — never run concurrent `dsh plugin` calls against the same
profile; prefix `PATH=/usr/bin:$PATH` so pnpm's major matches the profile
store). `dshmarket` is another entry installed **dependency-only** — never
via `dsh plugin add`, which would register it as a bundle and make the
desktop (≥0.3.8) boot die on `duplicate loader entry id: dsh-market`. Its
Backup & Restore export, stripped of private paths, is the kit's canonical
record of the whole profile state (`profile-backup.stripped.json`).

```sh
dsh plugin --profile web add \
  '@vectorize-io/hindsight-coding-agents' dsh-checkpoint-rewind \
  dsh-debugger-dap dsh-llm-fallbacks dsh-lsp-actions dsh-search-failover \
  dsh-better-reasoning-effort@0.2.3 better-dsh@0.2.2-b \
  dsh-better-sidebar@0.18.0 @leetoners/dsh-ui-subagent-monitor@0.2.0
```

Or skip the hand work once dshmarket is up: its **Backup & Restore** import
of `profile-backup.stripped.json` (placeholders re-pointed first) restores the
entire recorded profile in one pass — see `plugins/dshmarket/README.md`.

Then run `setup/verify.sh` and restart `dsh --profile web` — bundle layers
compose at boot, so nothing is active in running sessions until then. Per-entry
install steps, sources and verification live in each `plugins/*/README.md`.

## What you get

| Entry | What it adds |
|---|---|
| `dshmarket` | Plugin-market UI inside Settings (browse/upgrade from the GUI) + Backup & Restore (the kit's canonical profile-state record); dependency-only on desktop ≥0.3.8 — the AppImage mounts it via its own overlay |
| `agent-browser-skill` | Browser automation skill driving Chromium via the `agent-browser` CLI |
| `hindsight-coding-agents` | Long-term repository memory (needs a Hindsight server) |
| `tier1-plugins` | Capability pack: DAP debugger, LSP actions, checkpoint/rewind, LLM fallback chains, web-search failover, and four MCP servers (ast-grep, DuckDuckGo, fetch, markitdown) |
| `dsh-better-reasoning-effort` | Reasoning-effort + modality declarations for custom provider models |
| `machine-wide-ptc` | Builtin Code Mode (PTC) as the machine-wide default via `$DSH_HOME/cordis.patch.yml`: `run_code` + generated TypeScript SDK on every profile |
| `better-dsh` (Dashr) | Persistent IPython-kernel REPL (`eval`, model-settable per-call timeout + full budget config), native hashline read/write/edit/undo replacing the stock tools, URL-scheme reads, LLM failover — replaces the former `dsh-ptc-plus` + `dsh-better-edit` entries |
| `dsh-better-sidebar` | Web GUI sidebar workbench: explorer/editor/terminal/Git tabs + a `registerTab` face other plugins mount into |
| `dsh-ui-subagent-monitor` | Subagent monitoring mounted on that sidebar: live per-child run cards (running/elapsed/outcome), jump-to-child and back |
Plus the user-global system prompt (`setup/user-global-AGENTS.md`), an
advisory settings excerpt (`setup/settings.yaml.excerpt`), and a verification
suite (`setup/verify.sh`, `--full` also probes the MCP servers over stdio).

## Desktop client — recommended

For a native window instead of a browser tab, we use
[**DeepSeek Harness Desktop**](https://github.com/dsh-tauri-desk/deepseek-harness-desktop)
("DeepSeek Harness 桌面版", MIT): a Tauri 2 (non-Electron) shell that serves
the *same* surface — `dsh --profile web --host 127.0.0.1 --port 3080` with
`DSH_HOME=~/.dsh` — in a native window with tray, menus, a plugin management
panel and app self-update.

Why it pairs with this kit:

- **It wraps, does not replace.** It prefers an already-installed global
  `dsh` core and reuses `~/.dsh`, so the `web` profile and every bundle here
  keep working inside the window unchanged — adopting it never touches the
  profile's composition.
- It downloads its own Node + core runtime only when no global `dsh` exists,
  so it can also bootstrap a fresh machine.

**Install:** grab the latest Linux release — the `.deb` is preferred on
Wayland; the AppImage works too (Arch: run the AppImage, `dpkg-deb -x` the
deb, or convert with `debtap`). If the window renders black under Wayland,
launch with `WEBKIT_DISABLE_COMPOSITING_MODE=1 WEBKIT_DISABLE_DMABUF_RENDERER=1
GDK_BACKEND=x11`. Run one `dsh` server per profile: stop a plain
`dsh --profile web` first if it holds port 3080.

## Repository layout

```
AGENTS.md            ground rules; auto-loaded when this dir is the workspace
RESTORE.md           ordered reconstruction procedure (the install contract)
DEPENDENCIES.md      machine-level dependency manifest + per-dep install/verify
plugins/             one directory per customization (source, install, verify)
setup/               user-global prompt, settings excerpt, verify.sh, versions
.research/*.md       research notes referenced by plugin READMEs
profile-backup.stripped.json
                     canonical profile-state record (dshmarket export, stripped)
```

Raw `dsh-dshmarket-backup-*.json` exports are gitignored — commit only the
stripped canonical copy.

## Maintenance

The kit is a living contract: whenever the live setup changes (plugin, preset,
setting, ground rule), the corresponding entry is updated **in the same task**,
and `setup/verify.sh --record` refreshes `setup/versions.txt`. Profile-wide
state changes additionally re-export + strip a fresh
dshmarket Backup & Restore JSON over `profile-backup.stripped.json`. See
`RESTORE.md` → Maintenance contract.
