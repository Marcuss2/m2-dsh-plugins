# plugins/ — customization entries

One directory per non-shipped customization (plugin, agent preset, or
composition change). Shipped baseline behavior is *not* recorded here —
`RESTORE.md` assumes a stock install as the starting point.

## Entry format

Each entry is a directory containing:

- `README.md` — what it is, why it exists, dependencies, step-by-step install
  instructions for a baseline install, and how to verify it works.
- The **full** definition: complete plugin source, composition rows, or preset
  files. Never just names or pointers to files outside this repository.
- For inherently session-scoped pieces (e.g. dynamic Cordis plugins): the full
  host/client source plus the exact steps to re-define and re-activate them.

## Application index

Entries must be applied in the order listed here:

1. `dshmarket/` — plugin-market UI inside Settings, **installed first** so the
   rest can be browsed/upgraded from the GUI (nothing depends on it; a CLI
   install works identically). Also takes the first slot in
   `dsh.profile.bundles`, ahead of the other custom bundles.
2. `agent-browser-skill/` — browser automation for agents (requires the
   `agent-browser` CLI; see its README for the dependency install).
3. `dsh-better-edit/` — hashline editing tools replacing stock read/edit
   (profile-bundle plugin; new sessions only).
4. `hindsight-coding-agents/` — Hindsight long-term memory (official profile-
   bundle plugin; requires a reachable Hindsight server + a dsh restart).
5. `tier1-plugins/` — coding-agent capability pack: DAP debugger, LSP actions,
   checkpoint/rewind, LLM fallback chains, web-search failover, and four MCP
   servers (requires `uv`; dsh restart).
6. `dsh-better-reasoning-effort/` — reasoning-effort and input-modality
   declarations for custom (`llm-pi-ai`) provider models, edited inside the
   official Models page (profile-bundle plugin; dsh restart).

## How the npm bundles get installed

All profile bundles land in **one** batched command — one resolution pass, one
atomic `package.json` write, one restart:

```sh
dsh plugin --profile web add \
  dshmarket dsh-better-edit @vectorize-io/hindsight-coding-agents \
  dsh-checkpoint-rewind dsh-debugger-dap dsh-llm-fallbacks \
  dsh-lsp-actions dsh-search-failover \
  dsh-better-reasoning-effort@0.2.3
```

Measured on a warm pnpm store: 3 specs batched = 0.29s, 3 separate adds =
0.84s. Parallel installs are **not** an option: two concurrent `pnpm add` calls
in one project both exit 0 while the last writer wins, silently dropping the
other's dependency **and** its `dsh.profile.bundles` entry and leaving a dangling
`node_modules` symlink. Keep the profile quiescent — one install at a time, and
no other session running `dsh plugin` concurrently.

Afterwards, and after every later change, run `../setup/verify.sh` (one command
replaces the whole checklist below; `--full` also probes the MCP servers over
stdio).

## Recommended, not installed — desktop client

Researched 2026-08-28 (full comparison: `../.research/desktop-clients-research.md`,
trigger: the Web GUI works but is "a bit clunky"). If a native window is ever
wanted, the pick is
[dsh-tauri-desk/deepseek-harness-desktop](https://github.com/dsh-tauri-desk/deepseek-harness-desktop)
("DeepSeek Harness 桌面版", MIT, ★1,333, v0.9.2 released 2026-08-28): a Tauri 2
shell that runs the *same* harness surface —
`dsh --profile <profile> --host 127.0.0.1 --port 3080` with `DSH_HOME=~/.dsh` —
and **prefers an already-installed global `dsh` core**, so this kit's web
profile and every bundle here keep working inside the native window unchanged.
Linux ships AppImage + `.deb` (no AUR package; on Arch run the AppImage or
extract/convert the .deb); the note records the documented Wayland/WebKitGTK
workarounds (`WEBKIT_DISABLE_DMABUF_RENDERER=1 GDK_BACKEND=x11`) relevant to
Hyprland. Runner-up: [s3yf1337/dsh-desktop](https://github.com/s3yf1337/dsh-desktop)
— genuinely "desktop as a plugin, not a fork", but ★2 and its `desktop` profile
needs all bundles reinstalled as a second batch.
[hust-open-atom-club/oh-dsh](https://github.com/hust-open-atom-club/oh-dsh)
(★288) was rejected for this kit: it pins its own DSH + Node runtimes and
would re-platform the stack the kit reproduces. The Electron clients
(dataelement/dsh-desktop, anywhere-labs) ship no Linux artifact at all.
Nothing is installed for this yet; adoption is a user-level .deb/AppImage
plus a new entry dir here — no changes to the profile's bundle list.
