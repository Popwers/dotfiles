---
description: Token, context, and filesystem performance optimization rules
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

## File System as State

The file system is your most powerful general-purpose tool. Stop holding everything in context:

- Do not blindly dump large files into context. Use bash to grep, search, and selectively read what you need. Agentic search beats passive context loading
- Write intermediate results to files for multi-pass problems
- For large data operations, save to disk and use bash tools (`grep`, `jq`, `awk`) to process
- When debugging, save logs and outputs to files for reproducible verification
- Structure reduces context pressure — reference files can point to more files

