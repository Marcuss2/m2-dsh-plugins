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
  '@vectorize-io/hindsight-coding-agents'
  dsh-checkpoint-rewind
  dsh-debugger-dap
  dsh-llm-fallbacks
  dsh-lsp-actions
  dsh-search-failover
  dsh-better-reasoning-effort
  dsh-better-sidebar
  '@leetoners/dsh-ui-subagent-monitor'
  better-dsh
)
# dshmarket is DEPENDENCY-ONLY since DeepSeek Harness desktop 0.3.8: the
# desktop launcher always appends its own `--patch` overlay inserting
# `id: dsh-market` (config/plugin-market.patch.yml in the AppImage). A bundle
# layer would insert a second row with the same id and boot dies on
# "duplicate loader entry id: dsh-market" — see plugins/dshmarket/README.md.


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
# dshmarket: dependency-only (see the block comment above BUNDLES). The row
# itself is NOT checked in the section-4 dump: the desktop overlay that mounts
# it is passed only by the AppImage launcher, not by this script's `dsh` call.
dmv=$(jsonget "$PROFILE/package.json" "dependencies.dshmarket")
dmb=$(node -e "try{const j=require(process.argv[1]);process.stdout.write(String((j.dsh.profile.bundles||[]).includes('dshmarket')))}catch(e){}" "$PROFILE/package.json")
if [ -z "$dmv" ]; then
  bad dshmarket "not a dependency — desktop ≥0.3.8 resolves its market overlay against the profile"
elif [ "$dmb" = "true" ]; then
  bad dshmarket "$dmv — IN dsh.profile.bundles: its layer inserts a 2nd 'id: dsh-market' and the desktop boot dies on 'duplicate loader entry id'"
elif [ -d "$NM/dshmarket" ]; then
  ok dshmarket "$dmv (dependency-only; mounted by the desktop's own overlay)"
else
  bad dshmarket "declared $dmv but not in node_modules"
fi
# The kit's canonical profile-state record: a stripped dshmarket Backup &
# Restore export. If it exists, its recorded dshmarket spec should match the
# live profile (drift = re-export + strip per plugins/dshmarket/README.md).
if [ -f "$KIT/profile-backup.stripped.json" ]; then
  bkdm=$(jsonget "$KIT/profile-backup.stripped.json" "files")
  bkdm=$(node -e "try{const b=require(process.argv[1]);const m=b.files.find(f=>f.path==='package.json');process.stdout.write(String(m?.json?.dependencies?.dshmarket??''))}catch(e){}" "$KIT/profile-backup.stripped.json")
  if [ "$bkdm" = "$dmv" ]; then
    ok "profile-backup.stripped.json" "dshmarket spec matches live ($bkdm)"
  else
    warn "profile-backup.stripped.json" "records dshmarket $bkdm, live is $dmv — re-export + strip"
  fi
else
  note "profile-backup.stripped.json" "absent — see plugins/dshmarket/README.md (Backup & Restore standard)"
fi

# better-dsh (Dashr) — replaces the old dsh-ptc-plus qwencloud patch check. The
# qwencloud provider rejects ROOT-level oneOf/anyOf in tool parameter schemas;
# Dashr's edit.path uses a NESTED oneOf, which is accepted (probed 2026-09-05).
# What must hold: the bundle installed, zeromq build-approved, and NO leftover
# ptc-plus patch registration (it breaks every later `dsh plugin` run with
# ERR_PNPM_UNUSED_PATCH). See plugins/better-dsh/README.md.
if [ ! -f "$NM/better-dsh/package.json" ]; then
  bad "better-dsh bundle" "missing from node_modules — dsh plugin --profile web add --config.auto-install-peers=false better-dsh"
elif grep -q 'dsh-ptc-plus@' "$PROFILE/pnpm-workspace.yaml" 2>/dev/null; then
  bad "better-dsh workspace hygiene" "stale dsh-ptc-plus entries in pnpm-workspace.yaml (patchedDependencies / minimumReleaseAgeExclude) — remove them or pnpm removals fail"
else
  ok "better-dsh bundle" "installed $(jsonget "$NM/better-dsh/package.json" version)"
  grep -qE '^\s*zeromq:\s*true' "$PROFILE/pnpm-workspace.yaml" 2>/dev/null \
    && ok "zeromq build approval" "allowBuilds zeromq: true" \
    || bad "zeromq build approval" "not in allowBuilds — kernel bridge cannot load its native addon"
fi

head2 "4. Composition (dsh --profile web --dump-config)"
DUMP_ERR=$(mktemp)
DUMP=$(timeout 120 dsh --profile web --dump-config 2>"$DUMP_ERR")
# Empty output is rarely a missing binary: the launcher relinks a symlink under $DSH_HOME
# at boot, which throws EROFS when the home tree is read-only — e.g. when this script runs
# inside an agent's workspace-write sandbox. Report the real cause instead of guessing.
REASON=$(grep -qiE 'erofs|read-only file system' "$DUMP_ERR" \
  && echo "read-only $DSH_HOME — dsh's boot self-heal needs write access to the home tree" \
  || { printf '%s ' "$(head -c 140 "$DUMP_ERR" | tr '\n' ' ')"; command -v dsh >/dev/null || echo "dsh not on PATH"; })
rm -f "$DUMP_ERR"
if [ -z "$DUMP" ]; then bad dump-config "no output — ${REASON:-stderr empty}"
else
  for b in "${BUNDLES[@]}"; do
    if printf '%s' "$DUMP" | grep -qF "# == $b"; then ok "layer $b"
    # Fallback for bundles that contribute only `insert:` rows: match the row's
    # `name:` instead. (Verified 2026-09-05: every bundle layer DOES get a
    # "# == better-dsh" provenance header, so the primary branch catches them.)
    elif printf '%s' "$DUMP" | grep -qF "name: '$b'"; then ok "layer $b" "matched via row name"
    else bad "layer $b" "absent — bundle has no patch or failed to compose"; fi
  done
  for r in "${MCP_ROWS[@]}"; do
    printf '%s' "$DUMP" | grep -qF "id: $r" && ok "row $r" || bad "row $r" "absent from $PATCH"
  done
  # The kit's own presentation row: `both` = native schemas AND run_code.
  TMODE=$(printf '%s' "$DUMP" | grep -A3 '^- id: tools$' | sed -n 's/^[[:space:]]*mode:[[:space:]]*\([a-z]*\).*/\1/p' | tail -1)
  if [ "$TMODE" = "both" ]; then ok "tools mode" "both — native schemas + run_code"
  elif [ -z "$TMODE" ]; then bad "tools mode" "no mode key on the composed '- id: tools' row (home patch not applied?)"
  else warn "tools mode" "$TMODE — kit default is both (native schemas + run_code)"; fi
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
  # Upstream drift: installed vs npm latest. WARN only — pinning an older version is
  # sometimes deliberate (market `install` specs are unpinned, so the index always
  # advertises latest; this kit pins, which is exactly how a version goes stale).
  if command -v npm >/dev/null 2>&1; then
    behind=0; checked=0
    while read -r pkg; do
      [ -z "$pkg" ] && continue
      nm="${pkg%@*}"; cur="${pkg##*@}"
      lat=$(npm view "$nm" version 2>/dev/null | tail -1)
      [ -z "$lat" ] && continue                       # unlisted/private: skip quietly
      checked=$((checked+1))
      [ "$cur" = "$lat" ] && continue
      if [ "$(printf '%s\n%s\n' "$cur" "$lat" | sort -V | tail -1)" = "$lat" ]; then
        warn "upstream $nm" "live $cur → npm latest $lat (--record after upgrading)"; behind=1
      else
        warn "upstream $nm" "live $cur is ahead of npm latest $lat"
      fi
    done < /tmp/verify-live.$$.txt
    [ "$behind" = 0 ] && [ "$checked" -gt 0 ] \
      && ok "upstream" "$checked npm packages checked, none behind latest"
  fi
  rm -f /tmp/verify-live.$$.txt
  [ "$drift" = 0 ] && ok "versions.txt" "in sync with the live profile"
fi

printf '\n\033[1m%s\033[0m\n' "Summary: $PASS pass, $WARNED warn, $FAILED fail ($NOTED notes)"
printf 'Note: bundle layers mount at boot — restart `dsh --profile web` after any\nadd/remove. After that restart existing sessions pick the bundle up on their next\nrequest; only a first-time mount needs the boot (a version bump of an already-mounted\nbundle lands on the next worker respawn, at the cost of the live in-memory scope).\n'
[ "$FAILED" = 0 ] || exit 1
