---
description: Token and context performance optimization rules
globs: "**"
---

# Performance Rules

## Context Management

- Prefer CLI tools over MCPs when both achieve the same result (lower token overhead)
- Use `/compact` at phase transitions: after exploration before execution, after milestone before next task
- Run long-running processes in background when Claude does not need to process full output
- Read only the files and line ranges needed; widen only if targeted reads are insufficient

## Search Efficiency

- Semantic search first (`grepai search`), exact search second (`rg`/`fd`)
- Use `rtk` proxy for all shell commands (automatic via hook)

## Subagent Token Discipline

- Return summaries with file paths and line numbers, not large pasted excerpts
- One task per subagent with narrow scope and concrete deliverable
- Use haiku-model subagents for read-only exploration and search
