---
description: Model selection guidance and sub-agent swarming rules
globs: "**"
---

# Model Selection

Match three axes, not one: **model × effort × subtask**. A subagent's cost is not its per-token price — it's price × tokens burned. A lighter model set too high fails more often on the first pass, and in an agentic loop each failure is another turn that re-reads, retries, and burns tokens. Pick the model whose first-pass success on *this* subtask minimizes loops.

## Rankings

Higher = better. Cost is rate-limit burn on the subscription (higher = cheaper to run), not list price. Intelligence is how hard a problem you can hand the model unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model  | cost | intelligence | taste |
|--------|------|--------------|-------|
| haiku  | 9    | 4            | 4     |
| sonnet | 7    | 6            | 7     |
| opus   | 5    | 8            | 8     |

How to apply:

- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output doesn't meet the bar, rerun or redo the work with a smarter model without asking. Judge the output, not the price tag — escalating costs less than shipping mediocre work.
- Cost is a tie-breaker only; when axes conflict for anything that ships, intelligence > taste > cost.
- Anything user-facing (UI, copy, API design) needs taste ≥ 7 → `sonnet` minimum, `opus` when it ships.
- Reviews of plans and implementations: `opus · xhigh`. It's the top of the stack — when its output doesn't cut it, iterate with a sharper prompt or fresh context, not a bigger model.
- Opus holds the strategy seat: it orchestrates in the main loop and reviews the hardest work. Never spawn Opus subagents for mechanical subtasks a cheaper model clears in one pass — that's rate-limit burn with zero quality gain.

## Tiers

- **`haiku · medium`** — read-only scanning: repo discovery, doc lookup, mechanical search. The cheap fast worker that reads code so the reasoner doesn't have to; every file it reads is rate-limit budget the strategy seat keeps.
- **`sonnet · medium`** — the daily workhorse: applying an edit, running a test, clear-spec implementation, routine review, bulk/mechanical work (migrations, data shuffling). Sonnet 5 clears the overwhelming majority of tasks in one pass at normal effort — on subscription it's effectively free relative to Opus.
- **`opus · xhigh`** — the main loop (orchestrator) and genuinely hard reasoning: planning, security analysis, performance analysis, deep multi-file review, complex debugging. First-pass success here avoids the loop tax; Opus takes xhigh well — full reasoning depth without degrading. In the main loop it *delegates* the mechanical work rather than doing it inline.

## Effort discipline

- **Opus runs on `xhigh`, never `max`.** Opus takes xhigh well — full reasoning depth; max is a furnace with worse outputs than lower settings. The main loop pins `claude-opus-4-8` + `effortLevel: xhigh` in settings.json on purpose.
- **Opus subagents also run on `xhigh`.** The hard-reasoning seats get full depth: they're spawned precisely because the problem is hard, and a failed first pass costs more in loops than the extra effort does.
- **Never run Sonnet at high/max effort.** That is the one setting where it approaches Opus quality but costs *more*: a lighter model cranked up loops more, so you get the lowest per-token price multiplied by far more tokens. If a task needs high effort, it's hard reasoning → `opus · xhigh`. If it doesn't → keep `sonnet · medium`. There is no useful middle.

## Aliases auto-upgrade

Agent frontmatter uses aliases (`sonnet`, `opus`, `haiku`), not pinned IDs — so `sonnet` already resolves to the latest Sonnet (Sonnet 5) with no edit. A newer model in the same class mainly buys *fewer loops to the goal*, not a reason to crank effort. Only the main loop pins an ID (`claude-opus-4-8`) on purpose, for the strategy seat.

# Delegate by Default

The main loop's context and rate-limit budget are the scarcest resources in the system. Every file read inline, every test log paged through, every grep result dumped into the orchestrator's context is Opus-priced tokens spent on work a subagent does at a fraction of the cost — and context pollution that degrades the strategy seat's judgment later in the session.

Default posture: **orchestrate, don't execute.** Before doing read-heavy or mechanical work inline, ask "which agent tier clears this?" and delegate it. Keep in the main context only: decisions, synthesis, cross-agent arbitration, final review, and trivial single-file edits where delegation overhead exceeds the work itself.

Types: `Explore` (read-only scanning), `Plan` (architecture), `general-purpose` (full-capability), plus the specialized agents in `agents/` (repo-explorer, change-implementer, review-auditor, security-reviewer, test-guardian, planner, performance-optimizer, docs-researcher).

Sequential pattern for complex tasks: Research (Explore/repo-explorer) → Plan (planner) → Implement (change-implementer or swarm) → Review (review-auditor + security-reviewer in parallel) → Verify (test-guardian). Use `/compact` between phases.

# Subagent Token Discipline

- Return summaries with file paths and line numbers, not large pasted excerpts
- One task per subagent with narrow scope and concrete deliverable
- Use haiku-model subagents for read-only exploration and search

# Parallel Execution

Always run independent subagents in parallel (security + performance + type checking simultaneously). Only serialize when step 2 depends on the full result of step 1.

# Sub-Agent Swarming

When a task touches more than 5 independent files, prefer splitting across parallel sub-agents (5–8 files per agent) to avoid context decay on a single long pass. Use `isolation: "worktree"` when parallel work may touch overlapping files. One task per sub-agent for focused execution.

Use `run_in_background: true` for long-running tasks so the main agent can continue. Don't poll a background agent's output file mid-run — this pulls internal tool noise into context. Wait for the completion notification.
