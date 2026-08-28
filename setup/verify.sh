#!/usr/bin/env bash
# verify.sh — verify (or restore-verify) this kit's setup on the current machine.
#
#   ./setup/verify.sh            full check, no network-heavy probes
#   ./setup/verify.sh --quick    skip functional probes (offline / fast)
#   ./setup/verify.sh --full     add MCP stdio initialize probes + browser check
#   ./setup/verify.sh --record   rewrite setup/versions.txt from the live profile
#
# Exit 0 = every FAIL-free row. WARNs are reported but do not fail.
# Machine-independent: everything under $DSH_HOME; the kit path is derived.
#
# Expected state below is DATA, kept in one place: if the setup changes, change
# it here and in the entry READMEs (RESTORE.md, Maintenance contract).

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
PROFILE="$DSH_HOME/profiles/web"
NM="$PROFILE/node_modules"
PATCH="$PROFILE/cordis.patch.yml"
HINDSIGHT_CFG="$HOME/.hindsight/coding-agent.json"
QUICK=0; FULL=0; RECORD=0
for a in "$@"; do case "$a" in
  --quick) QUICK=1;; --full) FULL=1;; --record) RECORD=1;;
  *) echo "unknown option: $a" >&2; exit 2;;
esac; done

PASS=0; FAILED=0; WARNED=0; NOTED=0
ok()   { printf '  \033[32mPASS\033[0m  %-46s %s\n' "$1" "${2-}"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31mFAIL\033[0m  %-46s %s\n' "$1" "${2-}"; FAILED=$((FAILED+1)); }
warn() { printf '  \033[33mWARN\033[0m  %-46s %s\n' "$1" "${2-}"; WARNED=$((WARNED+1)); }
head2() { printf '\n\033[1m%s\033[0m\n' "$1"; }
# note = background fact or a reminder for a human/agent; deliberately not a
# warning, so the WARN count stays "things you should decide about".
note() { printf '  \033[90mnote\033[0m  %-46s %s\n' "$1" "${2-}"; NOTED=$((NOTED+1)); }

jsonget() { node -e "try{const j=require(process.argv[1]);const v=process.argv[2].split('.').reduce((o,k)=>o&&o[k],j);process.stdout.write(v==null?'':String(v))}catch(e){}" "$1" "$2"; }

# Bundles the kit installs (shipped baseline excluded).
BUNDLES=(
  dshmarket
  dsh-better-edit
  '@vectorize-io/hindsight-coding-agents'
  dsh-checkpoint-rewind
  dsh-debugger-dap
  dsh-llm-fallbacks
  dsh-lsp-actions
  dsh-search-failover
  dsh-better-reasoning-effort
)
# MCP rows the kit adds to cordis.patch.yml.
MCP_ROWS=(mcp-ast-grep mcp-ddg-search mcp-web-fetch mcp-markitdown)
# Profile-installed npm MCP servers and the binaries their postinstall builds.
NPM_MCP=(ast-grep-mcp mcp-duckduckgo)
BUILT_BINS=("@ast-grep/cli/ast-grep" "mcp-duckduckgo/bin/duckduckgo-mcp")
# Core modules whose duplicate instance breaks tool dispatch (see RESTORE.md,
# dependency hygiene). A hoisted copy of ANY of these in the profile is fatal.
CORE_MODULES=(dsh-tools dsh-agent dsh-agent-loop dsh-session dsh-llm dsh-fs
  dsh-sandbox dsh-subprocess dsh-settings dsh-commands dsh-storage-domain
  dsh-system-prompt dsh-client-runtime dsh-client-connection cordis)

[ "$RECORD" = 1 ] && {
  head2 "Recording installed versions"
  ( cd "$PROFILE" && pnpm ls --depth 0 --json 2>/dev/null ) \
    | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
        const j=JSON.parse(s.replace(/^[^{[]*/, ""));
        const m=j[0]&&j[0].dependencies||{};
        for (const k of Object.keys(m).sort()) console.log(k+"@"+m[k].version);
      })' > "$KIT/setup/versions.txt"
  wc -l < "$KIT/setup/versions.txt" | xargs echo "  wrote" "$KIT/setup/versions.txt  (" deps ")"
  exit 0
}

head2 "1. Machine dependencies (DEPENDENCIES.md)"
nv="$(node --version 2>/dev/null)"; case "${nv#v}" in
  2[2-9].*|[3-9][0-9].*) ok node "installed $nv";;
  *) [ -n "$nv" ] && bad node "installed $nv (need ^22.19.0 || >=24)" || bad node "missing";;
esac
command -v npm >/dev/null && ok npm "$(npm --version 2>/dev/null)" || bad npm "missing"
command -v pnpm >/dev/null || warn pnpm "not on PATH (dsh bundles its own; used only by --record)"
if command -v agent-browser >/dev/null; then
  ok agent-browser "$(agent-browser --version 2>&1 | tail -1)"
  [ "$QUICK" = 1 ] || {
    export AGENT_BROWSER_SESSION=dsh-verify
    t=$(timeout 90 agent-browser open https://example.com >/dev/null 2>&1; timeout 40 agent-browser get title 2>/dev/null)
    timeout 30 agent-browser close >/dev/null 2>&1
    [ "$t" = "Example Domain" ] && ok "agent-browser (functional)" "title: $t" || bad "agent-browser (functional)" "no page title (Chromium or deps missing)"
  }
else bad agent-browser "missing (npm i -g agent-browser && agent-browser install --with-deps)"; fi
command -v uvx >/dev/null && ok uvx "$(uvx --version 2>&1 | head -1)" || bad uvx "missing (needed by 2 MCP rows)"
if command -v git >/dev/null; then ok git "$(git --version | awk '{print $3}')"; else warn git "missing"; fi

head2 "2. Hindsight server"
if [ -f "$HINDSIGHT_CFG" ]; then
  apiurl="$(jsonget "$HINDSIGHT_CFG" apiUrl)"; mode="$(jsonget "$HINDSIGHT_CFG" serverMode)"
  ok "coding-agent.json" "serverMode=$mode"
  if [ -n "$apiurl" ] && [ "$QUICK" != 1 ]; then
    v=$(timeout 20 curl -s "$apiurl/version" | head -c 200)
    case "$v" in *api_version*) ok "server reachable" "$(printf '%s' "$v" | sed -n 's/.*"api_version":"\([^"]*\)".*/\1/p')";;
                   *) bad "server reachable" "$apiurl/version did not answer";; esac
  elif [ "$QUICK" = 1 ]; then warn "server reachable" "skipped (--quick)"; else warn "server reachable" "no apiUrl in config"; fi
else bad "coding-agent.json" "missing — see plugins/hindsight-coding-agents/README.md"; fi

head2 "3. Profile bundles ($PROFILE)"
[ -f "$PROFILE/package.json" ] || { bad package.json "profile not initialised"; }
for b in "${BUNDLES[@]}"; do
  ind=$(jsonget "$PROFILE/package.json" "dependencies.$b")
  inb=$(node -e "try{const j=require(process.argv[1]);process.stdout.write(String((j.dsh.profile.bundles||[]).includes(process.argv[2])))}catch(e){}" "$PROFILE/package.json" "$b")
  if [ -z "$ind" ]; then bad "$b" "not a dependency"; continue; fi
  if [ "$inb" != "true" ]; then bad "$b" "dep $ind — MISSING from dsh.profile.bundles"; continue; fi
  if [ -d "$NM/$b" ]; then ok "$b" "$ind"; else bad "$b" "declared $ind but not in node_modules"; fi
done

head2 "4. Composition (dsh --profile web --dump-config)"
DUMP=$(timeout 120 dsh --profile web --dump-config 2>/dev/null)
if [ -z "$DUMP" ]; then bad dump-config "no output (dsh not on PATH?)"
else
  for b in "${BUNDLES[@]}"; do
    printf '%s' "$DUMP" | grep -qF "# == $b" && ok "layer $b" || bad "layer $b" "absent — bundle has no patch or failed to compose"
  done
  for r in "${MCP_ROWS[@]}"; do
    printf '%s' "$DUMP" | grep -qF "id: $r" && ok "row $r" || bad "row $r" "absent from $PATCH"
  done
  # Dependency hygiene: no hoisted copy of a core module may shadow the install.
  mapfile -t HOISTED < <(find "$NM/@deepseek-ai" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) 2>/dev/null)
  if [ "${#HOISTED[@]}" = 0 ]; then
    ok "core shadow" "nothing hoisted under $NM/@deepseek-ai"
  else
    DSH_BIN="$(readlink -f "$(command -v dsh 2>/dev/null)" 2>/dev/null)"
    INSTALL_NM=""
    [ -n "$DSH_BIN" ] && INSTALL_NM="$(dirname "$(dirname "$DSH_BIN")")/node_modules/@deepseek-ai"
    [ -d "$INSTALL_NM" ] || INSTALL_NM="$DSH_HOME/profiles/node_modules/@deepseek-ai"
    for d in "${HOISTED[@]}"; do
      name="$(basename "$d")"; hit=0
      for c in "${CORE_MODULES[@]}"; do [ "$name" = "$c" ] && hit=1; done
      pv=$(jsonget "$d/package.json" version); iv=$(jsonget "$INSTALL_NM/$name/package.json" version)
      if [ "$hit" = 1 ]; then bad "core shadow" "@deepseek-ai/$name hoisted — a 2nd instance of a runtime module breaks tool dispatch"
      elif [ -z "$iv" ]; then warn "core shadow" "@deepseek-ai/$name hoisted ($pv) — not provided by the installation; confirm no composition row resolves it"
      elif [ "$pv" = "$iv" ]; then warn "core shadow" "@deepseek-ai/$name hoisted at the installed version ($pv) — 2 instances, harmless while nothing crosses the boundary"
      else bad "core shadow" "@deepseek-ai/$name VERSION SKEW: profile $pv vs installation $iv — the two instances disagree"
      fi
    done
  fi
fi

head2 "5. npm MCP servers installed as profile deps (no npx cache)"
for p in "${NPM_MCP[@]}"; do
  pv=$(jsonget "$PROFILE/package.json" "dependencies.$p")
  [ -n "$pv" ] && ok "dep $p" "$pv" || bad "dep $p" "missing — pnpm add ${NPM_MCP[*]} in $PROFILE"
done
for b in "${BUILT_BINS[@]}"; do
  f="$NM/$b"
  if [ -x "$f" ]; then ok "built binary" "$b ($(stat -c%s "$f" 2>/dev/null) bytes)"
  else bad "built binary" "$b missing — pnpm blocked the postinstall (build approval) → see tier1 README 'allowBuilds'"; fi
done
if grep -qE '^\s*(onlyBuiltDependencies|allowBuilds)' "$PROFILE/pnpm-workspace.yaml" 2>/dev/null; then
  ok "build approval" "declared in pnpm-workspace.yaml"
else warn "build approval" "none in pnpm-workspace.yaml — fresh installs will skip postinstall builds"; fi
grep -q 'nodeLinker: hoisted' "$PROFILE/pnpm-workspace.yaml" 2>/dev/null && \
  note "nodeLinker" "hoisted (set by dsh) — plugin deps land in the profile; section 4 is the guard"

head2 "6. Plugin backends (mounted tool != usable capability)"
DAP=()
for c in codelldb lldb-dap dlv netcoredbg rdbg; do command -v "$c" >/dev/null 2>&1 && DAP+=("$c"); done
# Only DAP *servers* count: rust-gdb / plain gdb are not adapters dsh can spawn.
python3 -c 'import debugpy' >/dev/null 2>&1 && DAP+=("debugpy[python]")
if [ "${#DAP[@]}" -gt 0 ]; then ok "DAP adapters" "${DAP[*]}"
else warn "DAP adapters" "none found -> the \`debug\` tool mounts but launches nothing (pip install debugpy; go install github.com/go-delve/delve/cmd/dlv@latest)"; fi
LSP=()
for c in typescript-language-server pyright pylsp rust-analyzer gopls bash-language-server yaml-language-server vscode-langservers-extracted; do
  command -v "$c" >/dev/null 2>&1 && LSP+=("$c")
done
if [ "${#LSP[@]}" -gt 0 ]; then ok "language servers" "${LSP[*]}"
else warn "language servers" "none found -> lsp_* tools mount but report nothing"; fi
note "backend config" "both plugins also read explicit config.adapters / config.servers maps in the patch layer; PATH discovery is the default"

head2 "7. Kit files applied"
cmp -s "$KIT/plugins/agent-browser-skill/SKILL.md" "$DSH_HOME/skills/agent-browser/SKILL.md" \
  && ok "skills/agent-browser/SKILL.md" "matches kit" \
  || bad "skills/agent-browser/SKILL.md" "missing or differs from kit copy"
cmp -s "$KIT/plugins/machine-wide-ptc/cordis.patch.yml" "$DSH_HOME/cordis.patch.yml" \
  && ok "home cordis.patch.yml" "matches kit (Code Mode on every profile)" \
  || bad "home cordis.patch.yml" "missing or differs from kit copy — see plugins/machine-wide-ptc/"
[ -f "$DSH_HOME/AGENTS.md" ] && ok "user-global AGENTS.md" "present" \
  || warn "user-global AGENTS.md" "missing (RESTORE.md step 3 is optional here)"

if [ "$FULL" = 1 ]; then
  head2 "8. MCP stdio initialize probes (raw JSON-RPC)"
  probe() { # name command args... 
    local name="$1" cmd="$2"; shift 2
    local out
    # Keep stdin open after the handshake: stdio servers exit on EOF, which would
    # otherwise look like "no answer" for the slower ones. Note `env` with an
    # empty var list would be passed a "" program name, so build the argv.
    local -a launch=(timeout 30 "$cmd" "$@")
    [ "${#ENVV[@]}" -gt 0 ] && launch=(env "${ENVV[@]}" "${launch[@]}")
    out=$( { printf '%s\n%s\n' \
        '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"verify","version":"1"}}}' \
        '{"jsonrpc":"2.0","method":"notifications/initialized"}'; sleep 4; } \
        | "${launch[@]}" 2>/dev/null | head -c 600 )
    case "$out" in *serverInfo*) ok "stdio $name" "$(printf '%s' "$out" | sed -n 's/.*"serverInfo":{\("name":"[^"]*"\).*/\1/p' | head -1)";;
                     *) bad "stdio $name" "no initialize answer";; esac
  }
  # Each probe mirrors how the row in cordis.patch.yml starts the server.
  ENVV=("AST_GREP_BIN=$NM/@ast-grep/cli/ast-grep"); probe ast-grep "$NM/.bin/ast-grep-mcp"
  ENVV=(); probe ddg-search "$NM/.bin/duckduckgo-mcp"
  ENVV=(); probe web-fetch uvx mcp-server-fetch
  ENVV=(); probe markitdown uvx --from markitdown-mcp markitdown-mcp
  head2 "9. Agent-side checks (a session must do these; not shell-verifiable)"
  note "hindsight tools" "call hindsight_recall / hindsight_retain in a session"
  note "mcp__* tools" "call mcp__ast-grep__ast_grep_version, mcp__ddg-search__search, mcp__web-fetch__fetch, mcp__markitdown__convert_to_markdown"
  note "hashline read/edit" "read any file in a NEW session: lines are HASH│content"
  note "code mode (PTC)" "new session post-restart: tool surface is run_code + the generated TypeScript SDK"
fi

if [ -f "$KIT/setup/versions.txt" ] && [ -n "${DUMP:-}" ]; then
  head2 "10. Version drift vs setup/versions.txt"
  ( cd "$PROFILE" && pnpm ls --depth 0 --json 2>/dev/null ) \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
      let j;try{j=JSON.parse(s.replace(/^[^{[]*/,""))}catch(e){console.log("UNREADABLE");process.exit(0)}
      const m=(j[0]&&j[0].dependencies)||{};const out=[];for(const k of Object.keys(m).sort())out.push(k+"@"+m[k].version);
      process.stdout.write(out.join("\n"))})' > /tmp/verify-live.$$.txt
  drift=0
  while read -r want; do
    [ -z "$want" ] && continue
    name="${want%@*}"
    have=$(grep -F "$name@" /tmp/verify-live.$$.txt || true)
    if [ "$have" = "$want" ]; then :
    elif [ -z "$have" ]; then bad "drift $name" "recorded $want — not installed"; drift=1
    else warn "drift $name" "recorded $want → live $have"; drift=1; fi
  done < "$KIT/setup/versions.txt"
  while read -r have; do
    [ -z "$have" ] && continue
    grep -qxF "$have" "$KIT/setup/versions.txt" || { warn "unrecorded" "$have (run setup/verify.sh --record)"; drift=1; }
  done < /tmp/verify-live.$$.txt
  rm -f /tmp/verify-live.$$.txt
  [ "$drift" = 0 ] && ok "versions.txt" "in sync with the live profile"
fi

printf '\n\033[1m%s\033[0m\n' "Summary: $PASS pass, $WARNED warn, $FAILED fail ($NOTED notes)"
printf 'Note: bundle layers mount at boot — a restart of `dsh --profile web` is\nrequired after any add/remove, and running sessions keep their tools.\n'
[ "$FAILED" = 0 ] || exit 1
