# hindsight-coding-agents

## What it is

Long-term, cross-session **memory** for DSH agents, backed by the
**Hindsight** memory system (vectorize.io). This is the *official* Hindsight
"Coding Agents" integration — npm package `@vectorize-io/hindsight-coding-agents`
(v0.4.2 at record time; **0.4.3 installed** on the 2026-08-28 restore) — which ships a native DeepSeek Harness target.

Installed as a DSH **profile bundle** (the same mechanism as
`dsh-better-edit`). The package declares `dsh.bundle.patch`, so `dsh plugin
add` both pnpm-installs it and appends its shipped `cordis.patch.yml` to the
profile's bundle list. That layer mounts one Cordis plugin row on the **host
plane**, which every session (including the Web GUI's per-session agent
presets) composes:

```yaml
- insert:
    - id: hindsight
      name: "@vectorize-io/hindsight-coding-agents/dsh"
```

What the mounted plugin gives each agent:

- Native model tools: `hindsight_retain` (store a memory), `hindsight_recall`
  (search by meaning), `hindsight_reflect` (consolidate/derive insight). No MCP.
- **Automatic recall injection** before each agent step (relevant memories are
  surfaced into context), plus session-start seeding and turn-stopping
  write-back of the transcript.
- Per-repo **memory banks**: one dsh process serves many repositories, so the
  bank is resolved per session workspace (dynamic bank id
  `coding-agent::{gitProject}`), not once per process.

Memory itself lives **outside** dsh, in a Hindsight server. Where it lives and
how to authenticate are configured in `~/.hindsight/coding-agent.json` — the
same file every other Hindsight coding-agent harness reads (see **Config**).

## Why this plugin (checked per ground rule 1)

The requirement is specifically "integration of the **Hindsight** memory
system". Searched npm + the GitHub `dsh-plugin` ecosystem before choosing:

- **`@vectorize-io/hindsight-coding-agents`** — chosen. The vendor-official
  Hindsight integration; has an explicit DeepSeek Harness target; ships the
  profile patch layer so install is `dsh plugin add` with no manual
  composition edit; native tools + auto-recall; maintained by the Hindsight
  vendor (vectorize.io).
- `With-With/dsh-hindsight-plugins` — a community **GUI "butler"** that wraps
  this official adapter (settings-page for editing/switching server URLs,
  auto-install of the adapter). Useful only if you want a UI to juggle
  multiple servers; for a single fixed server it is extra moving parts around
  the same official runtime.
- `dsh-mnemosyne-memory`, `dsh-plugin-memory`, `dsh-mnemon` — other DSH memory
  plugins, but they are *independent* memory stores (Ollama/markdown/local
  vector), **not** Hindsight; they don't satisfy "integrate Hindsight".

Because an official plugin already exists, no new/dynamic plugin is written —
this entry records the existing one.

## Dependencies

Tracked centrally in `DEPENDENCIES.md` (row `hindsight-server`). Two machine
requirements:

- `nodejs-npm` — baseline (already required by everything else).
- `hindsight-server` — a **reachable Hindsight server** for memory to live in.
  This setup uses a **self-hosted** server (URL + API token, machine-specific;
  see Config). Alternatives supported by the same plugin: Hindsight Cloud
  (`serverMode: cloud`) or a local embedded daemon (`serverMode: daemon`).

## Install

```sh
dsh plugin --profile web add @vectorize-io/hindsight-coding-agents
# no global dsh: npx @deepseek-ai/dsh plugin --profile web add @vectorize-io/hindsight-coding-agents
```

This pnpm-installs the package into `$DSH_HOME/profiles/web/` **and** adds it
to `dsh.profile.bundles` in the profile's `package.json` — the shipped
`cordis.patch.yml` (the `hindsight` row above) is appended to the bundle list
automatically. **No manual composition editing.** Then write the server config
(see **Config**) and **restart the dsh web server** so the new bundle layer
loads.

## Config — where memory lives (machine-specific)

Create `~/.hindsight/coding-agent.json`. This install points at a **self-hosted**
server. Copy `coding-agent.json.example` from this directory and fill in the
real values:

```json
{
  "serverMode": "self-hosted",
  "apiUrl": "<your Hindsight server URL>",
  "apiToken": "<your API token, if the server requires auth>"
}
```

- `apiUrl` — the Hindsight API base URL. **Do not commit real values to this
  repo**; they are machine-specific.
- `apiToken` — bearer token. This is a secret. Prefer supplying it via the
  environment variable `HINDSIGHT_API_TOKEN` (the plugin reads env as a
  fallback) rather than writing it into the file; if you do write it to the
  file, keep that file out of version control. Related env fallbacks:
  `HINDSIGHT_API_URL`, `HINDSIGHT_SERVER_MODE`.
- Everything else is optional and takes sane defaults: per-repo dynamic bank
  (`coding-agent::{gitProject}`), transcript write-back on, observations on.
  See the package README / `src/core/config.ts` for the full schema
  (`bankId`, `mapPathToBank`, `optInOnly`, `harnesses.<name>`, …).

The same file can also be produced by the official installer instead of
`dsh plugin add`:
`npx @vectorize-io/hindsight-coding-agents install dsh --server self-hosted --api-url <URL> --api-token <TOKEN>`
(equivalent end state; it writes the `~/.dsh/cordis.patch.yml` row plus this
config). The published-package route above is preferred here because it keeps
the plugin as a profile bundle, consistent with the other entries.

> Restore note (2026-08-28): `~/.hindsight/coding-agent.json` already exists on
> this machine (`serverMode: self-hosted` plus its own URL/token — real values
> deliberately not recorded here) and `GET <apiUrl>/version` answered
> `api_version 0.9.2`, so no config work was needed; only the bundle install.

## Activation

The `hindsight` row mounts on the host plane at dsh startup, so a **restart of
the dsh web server** is required after install/config. After the restart, every
new session (any workspace) gets the memory tools and auto-recall.

## Verify

1. `dsh --profile web --dump-config` shows a `# == @vectorize-io/hindsight-coding-agents`
   layer containing the `hindsight` row. `../../setup/verify.sh` checks this and
   item 4 automatically; when restoring the whole kit this add joins the single
   batched command in `../README.md` (never run installs concurrently).
2. In a session, the tool list includes `hindsight_retain` / `hindsight_recall`
   / `hindsight_reflect`.
3. Round-trip: ask the agent to remember a distinctive fact (`hindsight_retain`),
   then in a **new session in the same repo** ask about it — auto-recall or
   `hindsight_recall` should surface it.
4. Server reachability: `curl -s <apiUrl>/version` returns the Hindsight
   server version (the plugin treats an unreachable server as a soft failure and
   logs diagnostics rather than blocking the session).

## Remove

```sh
dsh plugin --profile web remove @vectorize-io/hindsight-coding-agents
```

(or delete the dependency and the bundle entry from the profile's
`package.json`). Optionally remove `~/.hindsight/coding-agent.json`. Stored
memories remain in the Hindsight server.
