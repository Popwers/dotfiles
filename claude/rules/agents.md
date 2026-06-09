---
description: Model selection guidance and sub-agent swarming rules
globs: "**"
---

# Model Selection

- `model: haiku` — read-only agents, repetitive tasks, clear instructions, worker subagents
- `model: sonnet` — implementation, testing, review, most coding tasks
- `model: opus` — complex debugging, multi-file reasoning, planning after first attempt failed
- `model: fable` — top tier: security analysis, architectural decisions, hardest debugging, high-stakes planning (2× opus cost — reserve for work where correctness matters most)

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
