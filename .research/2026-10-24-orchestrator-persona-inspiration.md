# Orchestrator personas — how existing frameworks prompt an agent that delegates instead of doing

**Date:** 2026-10-24
**Scope:** How agent frameworks and coding tools write the *system prompt / persona* of an
orchestrator whose defining trait is delegation — the lead agent, coordinator, supervisor,
manager, triage agent — with emphasis on the ones that delegate because their own inference
is the expensive resource. Collected for DSH persona/agent-preset design.
**Method:** Primary sources only where obtainable: vendor docs (Claude Code, Cursor, Amp,
Devin, OpenAI, CrewAI, LangGraph), the official Anthropic cookbook and SDK-demo prompt files
(raw markdown, not summaries), the Piebald-AI dump of shipped Claude Code system-prompt
components (each file carries a `ccVersion`), and a local oh-my-pi checkout
(`/home/vrbkam/repos/oh-my-pi`, HEAD `39477ba39`, 2026-08-07) read directly from
`packages/coding-agent/src/prompts/`. Two secondary/argumentative sources (Cognition,
12-Factor Agents) are included only for the counter-position. Nothing was installed or run.
**Constraint:** research only — no other file touched, nothing committed.

---

## Synthesis — eight patterns that recur

The single biggest surprise: **almost nobody writes "delegate because you are expensive."**
The dominant framing is *context* ("keep your window clean", "the subagent returns only the
summary"), with cost appearing as a **brake** ("subagents multiply cost and time") far more
often than as an **accelerator**. The two places that do invert it into a cost mandate are a
shipped npm agent (`docdex`) and OpenRouter's cookbook — both explicitly model-tier-aware.
So if the DSH orchestrator persona wants "your inference is the expensive part", it is
adopting a stance the mainstream products deliberately avoid, and it should say so with the
same precision they use for the opposite stance.

### 1. Identity inversion: name the job as *not doing the work*

Every real orchestrator prompt opens by redefining the role away from execution, in the
prefix, before any rule. Anthropic's lead agent: "your primary role is to coordinate, guide,
and synthesize — NOT to conduct primary research yourself." Claude Code's coordinator mode:
"You are a **coordinator**." Cursor's Projects: "The coordinator doesn't write code itself."
Oh-my-pi is the bluntest: "You decompose, dispatch, verify, and iterate."

This is stated as *identity*, not as a preference — which is what makes it survive a hard
task, where a preference would collapse into "I'll just do it myself".

> **So we could phrase it as:** *"You are an orchestrator. Your output is not code — it is
> dispatched work that comes back verified. You read, plan, delegate, verify, and synthesize;
> the edits belong to your teammates."*

### 2. Cost framing — used as a brake, and rarely as a mandate

The honest pattern is a **two-sided ledger**: name the overhead, then name the payoff.
Claude Code ships a whole component dedicated to restraint — "Subagents multiply cost and
time: each one re-establishes context, re-explores, and reports back, and you then re-read
its report" — followed by *"If you delegate, commit to the delegation: do not redo the
subagent's work while waiting."* Anthropic's own blog posts the numbers (multi-agent ≈15×
the tokens of chat) and concludes multi-agent only pays when task value is high.

The inverted stance exists but is rarer, and it always carries a **self-diagnosis step**:
`docdex` tells the model *"Determine if you are expensive: load `docs/expensive_models.json`
and match your agent_id, agent_slug, model, or adapter type… If unsure, default to
expensive"*, and then "Delegation is mandatory for eligible tasks." OpenRouter's recipe does
the same economically: "For each piece that doesn't need its full capability, it calls
`openrouter:subagent`."

Note what is *never* said: no vendor tells the orchestrator its tokens are precious in a
vacuum. The claim is always relative — cheaper *than this alternative*, or *not worth it for
that alternative*. Devin is the one vendor that puts the ledger net-positive for its own
product: "In our measurements, subagents both improve overall coding performance and reduce
cost" — and then still ships a "Use subagents deliberately" caution.

> **So we could phrase it as:** *"Your own turns are the expensive ones — a turn spent
> grepping is a turn not spent thinking. Delegation costs more in total tokens and less in
> your attention: it is worth it when a teammate can finish the chunk from a good brief, and
> not worth it for anything you could finish in three tool calls."*

### 3. An effort ladder that scales subagent count to task size

Nobody leaves "how many agents?" to judgment; the good prompts hard-code tiers.
Anthropic: "Simple fact-finding requires just 1 agent with 3-10 tool calls, direct
comparisons might need 2-4 subagents with 10-15 calls each, and complex research might use
more than 10 subagents" — plus a hard ceiling ("Never create more than 20 subagents… Prefer
fewer, more capable subagents over many overly narrow ones"). Their cookbook defaults to 3
subagents and requires *at least one* even for trivial queries. oh-my-pi runs the ladder the
other direction — it lists what is *too small* to delegate: "A single-file edit under
approximately 30 lines / A direct answer requiring no code changes / The user explicitly
asked you to run a command yourself", and then "Everything else… MUST be decomposed and
delegated."

The secondary quote here is 12-Factor Agents: agents stay good up to "3-10, maybe 20 steps
max", so a slice that would exceed that is a slice worth splitting.

> **So we could phrase it as:** *"Scale the fan-out to the job. One lookup or one file: do
> it yourself. Two to four independent slices: parallel teammates. Ten or more: still not
> — restructure until it's a handful of well-briefed teammates, and never more than ~20."*

### 4. The brief as a formal contract, not a sentence

This is the most consistently detailed advice in the entire corpus, and the one with the
clearest failure story behind it. Anthropic found short briefs ("research the semiconductor
shortage") caused subagents to "perform the exact same searches as other agents" — one agent
did the 2021 chip crisis while two others duplicated 2025 supply chains. Their fix: "Each
subagent needs an objective, an output format, guidance on the tools and sources to use, and
clear task boundaries."

Claude Code states the premise as a flat fact — **"Workers can't see your conversation"** —
and ships a formatting contract; oh-my-pi encodes one literally:

```
# Target       ← exact files and symbols; explicit non-goals
# Change       ← step-by-step add/remove/rename; APIs and patterns
# Acceptance   ← observable result; no project-wide commands
```

Two refinements worth stealing: **non-goals are part of the brief** (oh-my-pi's "explicit
non-goals"), and the *degree* of briefing is calibrated — Claude Code says agents are "often
the same model as you, just missing some context… treating the subagent respectfully and as
an intellectual peer", while oh-my-pi says "One-liners or missing acceptance criteria are
PROHIBITED."

> **So we could phrase it as:** *"Write every brief as if the teammate has never seen this
> repo. Name the files and symbols, the change, the non-goals, and the observable result. If
> you cannot state the acceptance criterion, you are not ready to delegate."*

### 5. Anti-duplication lives in scope boundaries, not in "don't overlap"

Nobody solves overlapping work by asking agents to coordinate mid-flight. They partition
*before* dispatch: Anthropic demands "extremely clear, crisp, and understandable boundaries
between sub-topics to prevent overlap" and "Avoid overlap between subagents — every subagent
should have distinct, clearly separate tasks"; oh-my-pi partitions by file ("Every set of
edits with **disjoint file scope** MUST ship as parallel `task` calls") and by explicit
ownership ("before you edit a file or start work a sibling may already own, message that peer
first — overlapping edits collide"); Claude Code's parallel-review recipe gives each teammate
"a distinct lens so they don't overlap".

Cognition's counter-post is the theoretical statement of why: two subagents that cannot see
each other make *conflicting implicit decisions* (their Flappy Bird came back with a bird and
a background in different visual styles). The fix it argues for is either shared context or a
decomposition with contracts fixed up front — which is exactly what oh-my-pi's "decide
cross-task contracts up front… and state them in the batch context, not left for agents to
negotiate" implements.

> **So we could phrase it as:** *"Partition before you dispatch, never after. Every teammate
> gets a distinct slice, disjoint files, and the shared contracts already decided by you.
> Overlap you discover later is a briefing defect, not a coordination problem."*

### 6. Decomposition and synthesis stay with the orchestrator — permanently

The sharpest single rule in the corpus is oh-my-pi's: **"NEVER outsource the top-level
plan — a generic 'plan'/'design' subagent starts blank, knows less than you, and adds a
round-trip for zero parallelism."** Anthropic says the same from the other end: the lead's
job is "to coordinate, guide, and synthesize", and synthesis is the lead's "most important
job" per Claude Code — which bans the lazy hand-off *by name*: never write "based on your
findings" or "the worker found an issue, please fix it", because those phrases "hand off
understanding to the worker instead of doing it yourself."

The corollary: reading the reports is *work*, and it cannot be delegated. Subagents return
summaries; the orchestrator is the only place those summaries ever meet.

> **So we could phrase it as:** *"You are the only agent that holds the whole picture, so you
> are the only agent that can decide what happens next. Never delegate the plan, and never
> write 'based on your findings' — do the reading, then write the specific instruction."*

### 7. Trust-but-verify: subagents report intent, not fact

Three independent vendors converge on the same warning, almost verbatim. Claude Code:
"**Trust but verify** — an agent's summary describes what it intended to do, not necessarily
what it did… check the actual changes before reporting the work as done." oh-my-pi: "`completed`
means successful yield/job exit, not artifact acceptance. Verify claimed changes." Claude
Code's coordinator section adds the reason it matters: "a worker's summary describes what it
intended to do… a verifier that rubber-stamps weak work undermines everything."

The verification *division of labour* is the design decision: oh-my-pi forbids subagents from
running gates at all ("Subagents do not verify, lint, or format… Their job is the edit only.
You — the orchestrator — run verification and formatting **once** at the end of the phase"),
so that N teammates don't each run the suite against each other's half-applied edits.

And the failure-handling rule is a persona trait, not a procedure: **"Respawn, do not
absorb."** If a teammate returns bad work, spawn a corrective teammate with the specific gap
— never silently fix it yourself. Claude Code says the same operationally: continue the same
worker with `SendMessage` because "it has the full error context".

> **So we could phrase it as:** *"A report is a claim, not a result — read the diff before you
> believe it. Verification is yours and happens once, at the end. When a teammate returns the
> wrong thing, send a corrective brief; do not quietly do the work yourself."*

### 8. A separate peer channel, and a lead who refuses to be a router

Once there is more than one worker, the interesting design question is *who talks to whom*.
The two mature answers differ:

- **Star with a shared board** (Claude Code agent teams): the lead spawns named teammates,
  "teammates share a task list, claim work, and communicate directly with each other", the
  lead is told "Do not use one worker to check on another. Workers will notify you when they
  are done", and the docs are explicit that the extra channel costs tokens: agent teams "use
  significantly more tokens than a single session… For sequential tasks, same-file edits, or
  work with many dependencies, a single session or subagents are more effective."
- **Mesh over an IRC bus plus typed artifacts** (oh-my-pi): every subagent gets a peer roster
  and `hub` messaging — "Use `hub` messaging only for quick coordination, never long-form
  content" — and, importantly, a rule against *indirect* discovery: "NEVER use shell tools,
  grep, or read other sessions' files to figure out what a peer is doing. Message them
  directly." Results are then addressable as artifacts (`agent://<id>/findings.0.path`),
  so the orchestrator can pull one field instead of a whole report.

Amp states the transport constraint that bites everyone: "Threads have separate workspaces.
A message does not transfer files or commits by itself" — "It does not share uncommitted
files automatically, so tell Amp to send any files or findings the other agent needs."

> **So we could phrase it as:** *"Teammates talk to each other, not through you: use the task
> board for what is claimed and messages for what is quick. Never ask one teammate to check
> on another — completion arrives on its own. Teammates share no files by default, so say
> which paths and findings to pass along."*

### Bonus pattern: prohibitions in the imperative, collected in an anti-pattern list

The prompts that actually change behaviour are written as `NEVER`/`MUST` statements in a
dedicated block, not as prose advice. oh-my-pi's orchestrate contract ends with an
`<anti-patterns>` list that names the exact failures ("Doing substantial or parallelizable
work yourself"; "Wrapping a single trivial edit… in a `task` with full Goal/Constraints
scaffolding"; "Yielding after phase 1 with 'ready to continue?'"; "Dispatching one subagent at
a time when five could run in parallel"). Claude Code's coordinator prompt does the same with
a bad/good pair shown side by side. If the DSH orchestrator persona adopts a stance that runs
against the model's default instinct (and "you are too expensive to grep" does), the negative
list is where it will actually land.

> **So we could phrase it as:** *"Give the orchestrator a named anti-pattern list — 'doing it
> yourself', 'one teammate when three would fit', 'a brief with no acceptance criterion',
> 'believing a report'. Prohibitions in the imperative, next to the role, beat description."*

---

## Sources

| URL | What it contributes |
| --- | --- |
| [anthropic.com/engineering/multi-agent-research-system](https://www.anthropic.com/engineering/multi-agent-research-system) — published 2025-06-13 (metadata; page updated 2026-10-09) | The canonical orchestrator-worker write-up. Token economics: agents ≈4× chat tokens, multi-agent ≈15×; token usage alone explains 80% of BrowseComp variance. Prompt lessons: "Teach the orchestrator how to delegate" (objective + format + tools + boundaries), the duplicated-2025-supply-chain failure story, embedded effort-scaling rules (1 agent/3-10 calls → 10+ agents), lead spins 3-5 subagents in parallel, synchronous execution "creates bottlenecks… the lead agent can't steer subagents, subagents can't coordinate". |
| [anthropic.com/engineering/building-effective-agents](https://www.anthropic.com/engineering/building-effective-agents) — 2024-12-19 | Names the "Workflow: Orchestrator-workers" pattern: "a central LLM dynamically breaks down tasks, delegates them to worker LLMs, and synthesizes their results"; subtasks "aren't pre-defined, but determined by the orchestrator". |
| [anthropic-cookbook … prompts/research_lead_agent.md](https://github.com/anthropics/anthropic-cookbook/blob/main/patterns/agents/prompts/research_lead_agent.md) (main, fetched 2026-10-24) | A complete, real lead-agent system prompt. "`<subagent_count_guidelines>`" tiers (1 / 2-3 / 3-5 / 5-10, max 20, "More subagents = more overhead"), "`<delegation_instructions>`" ("All substantial information gathering should be delegated to subagents"; "Synthesis responsibility… NOT to conduct primary research yourself"; "Avoid overlap between subagents"), and a model brief-example for a subagent. |
| [anthropic-cookbook … prompts/research_subagent.md](https://github.com/anthropics/anthropic-cookbook/blob/main/patterns/agents/prompts/research_subagent.md) | The worker side of the same contract: "You are a research subagent working as part of a team… You have been given a clear `<task>` provided by a lead agent", plus a self-assigned "research budget" in tool calls. |
| [claude-agent-sdk-demos … research_agent/prompts/lead_agent.txt](https://github.com/anthropics/claude-agent-sdk-demos/blob/main/research-agent/research_agent/prompts/lead_agent.txt) | Vendor-maintained SDK demo of the same lead-agent pattern (shorter variant of the cookbook prompt). |
| [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents) — current docs, fetched 2026-10-24 | Explicit "Choose between subagents and main conversation" decision list on both sides (main: frequent back-and-forth, shared context, quick targeted change, latency; subagent: verbose output you don't need, tool restrictions, self-contained work). "Use proactively" in the description field to encourage delegation; 15,000-token combined-description warning; nesting capped at 3 layers with the Agent tool withheld at the cap. |
| [code.claude.com/docs/en/agent-teams](https://code.claude.com/docs/en/agent-teams) | The peer-channel model: lead coordinates, "teammates share a task list, claim work, and communicate directly with each other"; compare table Subagents vs Agent teams (coordination: "Main agent manages all work" vs "Self-coordination through messages, plus a shared task list"); explicit token-cost warning and "for sequential tasks, same-file edits, or work with many dependencies, a single session or subagents are more effective"; parallel-review recipe assigns each teammate "a distinct lens so they don't overlap". |
| [code.claude.com/docs/en/cross-session-messaging](https://code.claude.com/docs/en/cross-session-messaging) | Message-passing between sessions without a team — the lightest-weight peer channel. |
| [github.com/Piebald-AI/claude-code-system-prompts](https://github.com/Piebald-AI/claude-code-system-prompts) (updated 2026-10-24; components carry `ccVersion`, e.g. 2.1.299-2.1.305) | Dump of shipped Claude Code prompt components. Most important: `system-prompt-coordinator-mode-orchestration.md` (full coordinator persona: role, phases table, "Workers can't see your conversation", worker-prompt anti-patterns, "Trust but verify", "Do not use one worker to check on another"), `system-prompt-subagent-delegation-restraint.md` ("Subagents multiply cost and time…"), `tool-description-agent-delegation-tradeoffs`, `system-prompt-fresh-subagent-delegation-example.md`, `system-reminder-team-coordination.md`, `tool-description-tasklist-teammate-workflow.md`, `agent-prompt-coordinator-worker-instructions.md` (worker-side counterpart). |
| [openai.github.io/openai-agents-python/handoffs](https://openai.github.io/openai-agents-python/handoffs/) + [developers.openai.com … agents/orchestration](https://developers.openai.com/api/docs/guides/agents/orchestration) | The other axis: **ownership transfer vs manager-stays-in-control**. "Handoffs: a specialist should take over the conversation for that branch" vs "Agents as tools: a manager should stay in control and call specialists as bounded capabilities". Practical rules: "Give each specialist a narrow job", "Keep `handoff_description` short and concrete", "Add specialists only when the contract changes — splitting too early creates more prompts, more traces, and more approval surfaces". |
| [openai.github.io/openai-agents-python/agents](https://openai.github.io/openai-agents-python/agents) | `handoff_description` as the model-facing routing text attached to each specialist — the triage-agent mechanism. |
| [LangGraph multi-agent concepts](https://github.com/langchain-ai/langgraphjs/blob/86389fa3/docs/docs/concepts/multi_agent.md) | Taxonomy worth reusing in any orchestrator prompt: Network / **Supervisor** ("each agent communicates with a single supervisor agent. Supervisor agent makes decisions on which agent should be called next") / **Hierarchical** ("a supervisor of supervisors") / custom; handoffs carry destination + payload. |
| [langgraph-supervisor-py README](https://github.com/langchain-ai/langgraph-supervisor-py/blob/main/README.md) | Minimal supervisor persona in the wild: `"You are a team supervisor managing a research expert and a math expert. For current events, use research_agent. For math problems, use math_agent."` Also the upstream retreat: "We now recommend using the supervisor pattern directly via tools rather than this library" — i.e. the prompt does the routing, not the framework. |
| [docs.crewai.com — Hierarchical Process](https://docs.crewai.com/edge/en/learn/hierarchical-process) | Manager-agent variant: "a 'manager' agent coordinates the workflow, delegates tasks, and **validates outcomes**"; `manager_llm` is a separate (usually stronger) model from the workers; "Delegation is now disabled by default to give users explicit control". |
| [docs.crewai.com — Agents](https://docs.crewai.com/concepts/agents) | Agent attributes that make an agent delegable: role / goal / backstory, "Delegate tasks when allowed", `allow_delegation`. |
| [cursor.com/docs/agent/projects](https://cursor.com/docs/agent/projects) | Purest orchestrator persona in production: "The coordinator doesn't write code itself. It plans the work, delegates it to agents that write the code, and brings the finished work back to you to check." Also the justification for the design: "Because it delegates rather than executes, it stays responsive to your direction." |
| [cursor.com/docs/subagents](https://cursor.com/docs/subagents) | Same baseline as everyone: own context window, "Subagents start with a clean context. The parent agent includes relevant information in the prompt since subagents don't have access to prior conversation history"; built-in Explore subagent exists specifically to contain context-heavy searching. |
| [ampcode.com/docs/orbs/agent-to-agent](https://ampcode.com/docs/orbs/agent-to-agent) | Agent-to-agent as a user-facing primitive: "Amp agents can start other agents, send them instructions, exchange files, and bring their results back into the current thread." Concrete instruction shapes ("Start an orb thread with what you know about this unrelated bug… report back when it finishes, then keep working on the current task here"; "Run four low-mode threads in parallel… Ask each one to report its result with a screenshot, then summarize all four results here"). The transport caveat: separate workspaces, a message transfers no files by default. |
| [docs.devin.ai/cli/subagents](https://docs.devin.ai/cli/subagents) | The rare vendor claim that the ledger is net-positive: "In our measurements, subagents both improve overall coding performance and reduce cost." Costs nonetheless spelled out ("each with its own context window and inference calls… every subagent it spawns adds its own usage on top of that", "Use subagents deliberately when the parallelism or focused context is worth it"), plus foreground/background semantics. |
| [cognition.ai/blog/dont-build-multi-agents](https://cognition.ai/blog/dont-build-multi-agents) — 2025-06-12 | The strongest published counter-position, and the source of the best articulation of *why* briefs must fix contracts: "Share context" / "Actions carry implicit decisions, and conflicting decisions carry bad results" — subagents that cannot see each other produce inconsistent work. |
| [12-factor agents, factor 10](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-10-small-focused-agents.md) | The sizing heuristic behind the effort ladder: "keeping agents focused on specific domains with 3-10, maybe 20 steps max… As context grows, LLMs are more likely to get lost or lose focus." |
| [openrouter.ai/docs/cookbook/building-agents/subagent-server-tool](https://openrouter.ai/docs/cookbook/building-agents/subagent-server-tool) | Explicit **cost-mandate** delegation prompt for a model-tier split: "Use an orchestrator for planning and a cheap subagent worker for each subtask"; "For each piece that doesn't need its full capability, it calls `openrouter:subagent`"; the split rationale ("the orchestrator handles planning and integration (small token budget), while the worker handles bulk generation") with a worked "80%+ cut" claim, plus a warning that every delegation "adds cost and latency". |
| [cdn.jsdelivr.net/npm/docdex@0.2.98/assets/agents.md](https://cdn.jsdelivr.net/npm/docdex@0.2.98/assets/agents.md) | A shipped npm agent prompt that spells out "you are the expensive model" delegation, including a self-diagnosis step: "Determine if you are expensive: load `docs/expensive_models.json` and match your agent_id… If unsure, default to expensive", "Delegation is mandatory for eligible tasks", a enumerated trigger list (GENERATE_TESTS / WRITE_DOCSTRING / REFACTOR_SIMPLE…), and a required "Delegation Handoff Package" (task capsule, context payload, dependency notes, boundaries, guardrails) for workers that cannot call tools. |
| [oh-my-pi, local checkout `/home/vrbkam/repos/oh-my-pi` @ `39477ba39` (2026-08-07)](https://github.com/can1357/oh-my-pi) | The richest real orchestrator prompt found in the wild. `prompts/system/orchestrate-notice.md` — triggered by typing `orchestrate` in prose (a hidden system notice appended to the user message, see `modes/orchestrate.ts`) — carries a full contract: role, 10 numbered rules, a 7-step workflow, and an `<anti-patterns>` block. `prompts/system/system-prompt.md` carries the "Delegation gates" (own the decomposition / use real concurrency / carry the user's intent / sequence dependencies only) and the eager-vs-restrained delegation switch. `prompts/system/subagent-system-prompt.md` carries the COOP section (peer roster, "message that peer first — overlapping edits collide"). `prompts/tools/task.md` has the Target/Change/Acceptance brief format and "Overlap is safe… NEVER shrink or serialize a batch to avoid file overlap" plus the two prerequisites. `prompts/tools/hub.md` defines peer messaging discipline. `prompts/system/subagent-system-prompt.md` + `prompts/agents/task.md` define the worker's own persona ("worker agent for delegated tasks… You NEVER include filler… The user cannot see you"). |

---

## Verbatim snippets worth stealing

**1. The identity inversion, stated flat (Anthropic cookbook, `research_lead_agent.md`)**

> As the lead research agent, your primary role is to coordinate, guide, and synthesize -
> NOT to conduct primary research yourself.

**2. The cost brake (Claude Code, `system-prompt-subagent-delegation-restraint.md`, ccVersion 2.1.215)**

> Subagents multiply cost and time: each one re-establishes context, re-explores, and reports
> back, and you then re-read its report. Delegate only when the payoff clearly exceeds that
> overhead.

**3. The cost mandate, with self-diagnosis (docdex npm agent, `agents.md` §5)**

> When you are an expensive/paid model, delegate eligible low-complexity code-writing tasks
> and lightweight general questions first unless the user opts out. … Delegation is mandatory
> for eligible tasks.

**4. The decomposition non-delegation rule (oh-my-pi, `prompts/system/system-prompt.md`)**

> NEVER outsource the top-level plan — a generic "plan"/"design" subagent starts blank, knows
> less than you, and adds a round-trip for zero parallelism.

**5. Verification and failure handling in two lines (oh-my-pi, `orchestrate-notice.md`)**

> **Respawn, do not absorb.** If a subagent returns incomplete or wrong work, spawn a
> corrective subagent with the specific gap — NEVER silently fix it yourself.

…paired with Claude Code's (`tool-description-agent-usage-notes.md`):

> Trust but verify: an agent's summary describes what it intended to do, not necessarily what
> it did.

**6. The peer channel, and the ban on indirect snooping (oh-my-pi, `prompts/tools/hub.md`)**

> NEVER use shell tools, grep, or read other sessions' files to figure out what a peer is
> doing. Message them directly.

---

## Where this lands for a DSH orchestrator preset (inference, not sourced)

- The stance the lead is considering — *"your inference is the expensive resource, so delegate"*
  — is **not** the mainstream stance. It is defensible (docdex, OpenRouter) but it needs the
  same rigour the mainstream applies to the opposite claim: name what delegation costs
  (total tokens, round-trips, briefing effort), name when it does *not* pay (three tool calls,
  one file, a question you can answer from context), and give the model a way to tell which
  regime it is in — a tier/manifest check rather than a vibe.
- DSH's existing vocabulary lines up almost one-for-one with the best material: `subagent` /
  `subagent_fork` ↔ Claude Code's fork-vs-fresh distinction (fork inherits context, so the
  brief can be short; fresh starts blank, so it cannot); `team_task_create`/`team_task_list`
  ↔ agent-team shared board (claim-by-revision is a stronger anti-duplication primitive than
  any prompt rule); `send_message` ↔ the peer channel; `outputSchema` / structured results ↔
  oh-my-pi's `yield`/`result.data` contract. The persona should name these, because they are
  the levers the rules act on.
- The cheapest high-value transplant, if only one thing is taken: **the brief format**
  (Target / Change / Non-goals / Acceptance) plus **"Workers can't see your conversation"** as
  its stated premise — with the sibling rule that verification is the orchestrator's and
  happens once, at the end.
