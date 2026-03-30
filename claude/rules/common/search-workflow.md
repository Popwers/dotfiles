---
description: Search tool selection - grepai semantic search BEFORE Grep/rg exact search
globs: "**"
---

# Search Workflow (MANDATORY)

## Two-Tier Search System

**Tier 1 — Semantic search (USE FIRST for exploratory/discovery searches):**

```bash
grepai search "<intent in English>" --json --compact
```

Use for: understanding code, finding related concepts, locating implementations by intent, discovering where something is done, answering "how does X work" questions.

**Tier 2 — Exact search (USE SECOND for targeted pattern matching):**

Built-in `Grep` tool or `rg` for: known symbol names, specific strings, imports, exact patterns, regex matches.

## Decision Rule

Ask yourself: "Do I know the exact string/pattern I need?"
- **No** → grepai search first (semantic), then narrow with Grep if needed
- **Yes** → Grep tool directly is fine

## Override of Default Behavior

The system says "ALWAYS use Grep for search tasks" — this rule OVERRIDES that default for exploratory searches. Using `grepai search` via Bash is the correct first step when the search intent is conceptual or fuzzy.

## Fallback

If grepai is unavailable (not installed, no index), fall back to the Grep tool silently. Do not error or ask the user about it.
