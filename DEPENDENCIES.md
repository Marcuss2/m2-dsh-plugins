# DEPENDENCIES.md — machine-level dependencies

Everything that must exist **on the machine** before kit entries can be
applied. Dependencies differ system to system (package manager, OS, existing
tooling), so restore **always starts here** (RESTORE.md, Step 2): detect each
dependency, install whatever is missing the way the target system requires,
and verify — only then apply kit entries.

## Manifest

| ID | Dependency | Detect | Required by |
|----|------------|--------|-------------|
| `nodejs-npm` | Node.js + npm (`^22.19.0 \|\| >=24.0.0` for current DSH plugins) | `node --version && npm --version` | everything (baseline for global npm tools) |
| `agent-browser` | agent-browser CLI + a Chromium it can drive | `agent-browser --version` | `plugins/agent-browser-skill/` |
| `dsh-better-edit` | hashline editing plugin installed as profile bundle | `grep dsh-better-edit "$DSH_HOME/profiles/web/package.json"` | `plugins/dsh-better-edit/` |
| `hindsight-server` | reachable Hindsight memory server (self-hosted here) | `curl -s <apiUrl>/version` | `plugins/hindsight-coding-agents/` |
| `uv` | `uv`/`uvx` Python package runner for MCP servers | `uvx --version` | `plugins/tier1-plugins/` |
| `pnpm-build-approval` | pnpm ≥10 blocks dependency build scripts unless approved | `grep -A4 'allowBuilds\|onlyBuiltDependencies' "$DSH_HOME/profiles/web/pnpm-workspace.yaml"` | `plugins/tier1-plugins/` (npm MCP servers) |
| `profile-hygiene` | no hoisted copy of a `@deepseek-ai/*` core module in the profile | `setup/verify.sh` (section 4) | every bundle entry |
| `dap-lsp-backends` | optional, per-language: DAP adapters (`debugpy`, `dlv`, `codelldb`, `netcoredbg`) and language servers (`typescript-language-server`, `pyright`, `rust-analyzer`, …) | `setup/verify.sh` (section 6) | `plugins/tier1-plugins/` (`dsh-debugger-dap`, `dsh-lsp-actions`) |

Rules:

- Work through the manifest top to bottom; later rows may depend on earlier
  ones.
- For each row: run **Detect**; if missing or failing, install using the
  per-dependency notes below (adapt to the target system — distro package
  manager, sudo availability, existing installs); then run **Verify**.
- Do not apply any kit entry whose dependencies did not verify. Report each
  installed/verified dependency to the user.
- Install npm packages into a profile **one batched command at a time**; never
  run two `pnpm add`/`dsh plugin add` processes against the same profile
  concurrently — both exit 0 and the last writer silently wins.
- After any bundle add/remove, run `setup/verify.sh`: section 4 is the
  `@deepseek-ai/*` shadowing guard that catches the failure mode which breaks
  every tool call (see RESTORE.md, Step 4).

## nodejs-npm

Baseline for global npm tooling. On most systems DSH itself implies Node is
present; if not, install via the distro's package manager or `nvm`.

- **Verify:** `node --version && npm --version` print versions.

## pnpm-build-approval

pnpm 10+ **does not run dependency build scripts (preinstall/postinstall) unless
the package is explicitly approved**; the install still succeeds, printing only
`[ERR_PNPM_IGNORED_BUILDS] Ignored build scripts: …`. Any dependency that
*downloads or builds a binary at install time* therefore lands incomplete with no
error. That is the real cause of `mcp-duckduckgo`'s
`Binary not found. Please reinstall the package.` — not an `npx` cache quirk, and
not specific to that package: `@ast-grep/cli` (pulled by `ast-grep-mcp`) is built
the same way.

- **Detect:** `grep -A4 'allowBuilds\|onlyBuiltDependencies' "$DSH_HOME/profiles/web/pnpm-workspace.yaml"`.
- **Install:** after pnpm's first blocked install it writes an `allowBuilds:`
  stub into the workspace file with `set this to true or false` placeholders —
  replace them with `true`, or add the list yourself:
  ```yaml
  allowBuilds:
    '@ast-grep/cli': true
    mcp-duckduckgo: true
  ```
  then `pnpm install` in `$DSH_HOME/profiles/web` to run the builds (first run
  downloads ~60 MB; allow ~30 s).
- **Verify:** the built binaries exist and are executable —
  `test -x $DSH_HOME/profiles/web/node_modules/@ast-grep/cli/ast-grep && test -x $DSH_HOME/profiles/web/node_modules/mcp-duckduckgo/bin/duckduckgo-mcp`
  (≈52 MB and ≈8.9 MB respectively). `setup/verify.sh` checks this as "built binary".

## dap-lsp-backends

`dsh-debugger-dap` and `dsh-lsp-actions` register their tools either way, but each
tool needs a real backend: a **DAP server** to launch or attach, and a
**language server** for the language being edited. Nothing in this kit ships
them — install only what the target's languages need.

- **Detect:** `setup/verify.sh` section 6 probes `codelldb`, `lldb-dap`, `dlv`,
  `netcoredbg`, `rdbg`, python `debugpy`, and the common language servers.
- **Install (per language):**
  ```sh
  python3 -m pip install debugpy                        # Python
  go install github.com/go-delve/delve/cmd/dlv@latest    # Go
  npm i -g typescript-language-server typescript         # TS/JS
  ```
- **Verify:** in a session, `debug` → action `sessions` should answer without
  error, then launch a real target and confirm a breakpoint stops; for LSP, open
  a file in an installed language and call `lsp_diagnostics`.

A `PASS` here means *a* backend exists, not that the one you need does: a machine
with only `rust-analyzer` still cannot diagnose TypeScript.

## agent-browser

Browser-automation CLI for AI agents (Chromium/Chrome over CDP), backing the
`agent-browser` skill entry.

- **Detect:** `agent-browser --version`.
- **Install (Linux):** `npm i -g agent-browser && agent-browser install --with-deps`
  (`--with-deps` adds required Chromium libraries; needs privileges for the
  system package manager). If a system Chromium/Chrome already exists,
  `agent-browser install` alone usually suffices — the CLI can drive it.
- **Other systems:** follow `agent-browser install` output; the CLI's own
  quickstart (`agent-browser skills get core`) covers platform variants.
- **Verify (functional, not just version):**
  ```bash
  export AGENT_BROWSER_SESSION=dsh-depcheck && agent-browser open https://example.com && agent-browser get title && agent-browser close
  ```
  must print the page title (`Example Domain`).

## dsh-better-edit

Hashline editing plugin for DSH agents (see `plugins/dsh-better-edit/`).

- **Detect:** `grep dsh-better-edit "$DSH_HOME/profiles/web/package.json"`
  (must appear in both `dependencies` and `dsh.profile.bundles`).
- **Install:** `dsh plugin --profile web add dsh-better-edit` — use the
  deployment's own `dsh` binary if `dsh` is not on PATH (e.g.
  `<dsh-install>/bin/dsh`), else `npx @deepseek-ai/dsh plugin --profile web
  add dsh-better-edit`. The command installs the package AND registers the
  profile bundle; no manual composition edits.
- **Verify:** `dsh --profile web --dump-config` contains a
  `# == dsh-better-edit` layer; a NEW session's `read` tool returns
  `HASH│content` lines.

## hindsight-server

The Hindsight memory server that the `hindsight-coding-agents` plugin stores
memories in (see `plugins/hindsight-coding-agents/`). It is a service you
already run (self-hosted), use as Hindsight Cloud, or bring up as a local
daemon — not something this kit installs. This setup uses **self-hosted**.

- **Detect:** `GET <apiUrl>/version` returns the server version; `<apiUrl>` is
  the machine-specific URL you configure.
- **Provision:** point the plugin at the server by writing
  `~/.hindsight/coding-agent.json` (`serverMode: self-hosted`, `apiUrl`, and
  `apiToken` if the server requires auth) — see the entry README and its
  `coding-agent.json.example`. `apiToken` is a secret: prefer the environment
  variable `HINDSIGHT_API_TOKEN`. Nothing to install for self-hosted; for
  `daemon` mode instead you would need `uv` plus an LLM key (see the package
  README).
- **Verify:** `curl -s <apiUrl>/version` prints a version string, not an error.

## uv

`uv` provides `uvx`, which runs the two Python MCP servers in
`plugins/tier1-plugins/` (`mcp-server-fetch`, `markitdown-mcp`) without
polluting the system Python.

- **Detect:** `uvx --version`.
- **Install (Linux):** `curl -LsSf https://astral.sh/uv/install.sh | sh`
  (installs to `~/.local/bin`), or the distro package manager. No Python
  install is required — `uv` manages its own interpreters.
- **Verify:** `uvx --version` prints a version; optionally
  `timeout 60 uvx mcp-server-fetch --help` exits without error after
  downloading the package on first use.

## Maintenance

Any new kit entry that needs machine-level software MUST add a manifest row
and a section here in the same task (see RESTORE.md, Maintenance contract).
