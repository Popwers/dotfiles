---
description: Model selection guidance and sub-agent swarming rules
globs: "**"
---

# Model Selection

- `model: haiku` — read-only agents, repetitive tasks, clear instructions, worker subagents
- `model: sonnet` — implementation, testing, review, most coding tasks
- `model: opus` — complex debugging, security analysis, architectural decisions, multi-file reasoning, planning after first attempt failed

# Parallel Execution

Always run independent subagents in parallel (security + performance + type checking simultaneously). Only serialize when step 2 depends on the full result of step 1.

# Sub-Agent Swarming

For tasks touching >5 independent files, you MUST launch parallel sub-agents (5-8 files per agent). One agent processing 20 files sequentially guarantees context decay. Use `isolation: "worktree"` for independent parallel work across the same repo. One task per sub-agent for focused execution.

Use `run_in_background: true` for long-running tasks so the main agent can continue. Do NOT poll a background agent's output file mid-run — this pulls internal tool noise into context. Wait for the completion notification.
