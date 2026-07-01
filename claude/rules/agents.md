---
description: Model selection guidance and sub-agent swarming rules
globs: "**"
---

# Model Selection

Match three axes, not one: **model × effort × subtask**. A subagent's cost is not its per-token price — it's price × tokens burned. A lighter model set too high fails more often on the first pass, and in an agentic loop each failure is another turn that re-reads, retries, and burns tokens. Pick the model whose first-pass success on *this* subtask minimizes loops.

## Tiers

- **`haiku · medium`** — read-only scanning: repo discovery, doc lookup, mechanical search. The cheap fast worker that reads code so the reasoner doesn't have to (this is what Claude Code already does for repo exploration).
- **`sonnet · medium`** — the daily workhorse: applying an edit, running a test, implementation, routine review. Sonnet 5 clears the overwhelming majority of tasks in one pass at normal effort. This is where it's redoubtable.
- **`opus · high`** — genuinely hard reasoning: planning, security analysis, performance analysis, deep multi-file review, complex debugging. First-pass success here avoids the loop tax; the main loop (orchestrator) holds strategy on Opus and *delegates* the mechanical work rather than doing it inline.

## The `sonnet · high` anti-pattern

Never run Sonnet at high/max effort. That is the one setting where it approaches Opus quality but costs *more*: a lighter model cranked up loops more, so you get the lowest per-token price multiplied by far more tokens. If a task needs high effort, it's hard reasoning → use `opus · high`. If it doesn't → keep `sonnet · medium`. There is no useful middle.

## Aliases auto-upgrade

Agent frontmatter uses aliases (`sonnet`, `opus`, `haiku`), not pinned IDs — so `sonnet` already resolves to the latest Sonnet (Sonnet 5) with no edit. A newer model in the same class mainly buys *fewer loops to the goal*, not a reason to crank effort. Only the main loop pins an ID (`claude-opus-4-8`) on purpose, for the strategy seat.

# Subagent Delegation

Delegate to subagents to keep the main context clean. Types: `Explore` (read-only scanning), `Plan` (architecture), `general-purpose` (full-capability).

Delegate when: read-heavy parallel work, codebase discovery, multi-angle review. Keep in main context: decisions, synthesis, final implementation, simple single-file changes.

Sequential pattern for complex tasks: Research (Explore) → Plan → Implement → Review → Verify. Use `/compact` between phases.

# Subagent Token Discipline

- Return summaries with file paths and line numbers, not large pasted excerpts
- One task per subagent with narrow scope and concrete deliverable
- Use haiku-model subagents for read-only exploration and search

# Parallel Execution

Always run independent subagents in parallel (security + performance + type checking simultaneously). Only serialize when step 2 depends on the full result of step 1.

# Sub-Agent Swarming

When a task touches more than 5 independent files, prefer splitting across parallel sub-agents (5–8 files per agent) to avoid context decay on a single long pass. Use `isolation: "worktree"` when parallel work may touch overlapping files. One task per sub-agent for focused execution.

Use `run_in_background: true` for long-running tasks so the main agent can continue. Don't poll a background agent's output file mid-run — this pulls internal tool noise into context. Wait for the completion notification.
