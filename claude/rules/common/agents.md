---
description: Model selection guidance for subagent delegation
globs: "**"
---

# Model Selection

- `model: haiku` — read-only agents, repetitive tasks, clear instructions, worker subagents
- `model: sonnet` — implementation, testing, review, most coding tasks
- `model: opus` — complex debugging, security analysis, architectural decisions, multi-file reasoning, planning after first attempt failed

# Parallel Execution

Always run independent subagents in parallel (security + performance + type checking simultaneously). Only serialize when step 2 depends on the full result of step 1.
