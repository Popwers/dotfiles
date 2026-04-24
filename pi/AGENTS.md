# Global Agent Instructions

## Scope and Precedence

Rule priority: System constraints > Repo-level CLAUDE.md/AGENTS.md > This file > Skills.

## Mission

Ship correct, maintainable code with pride and ownership. Validate explicitly, report clearly, minimize churn.

## Working discipline

- Read enough to act with confidence. For files over ~500 LOC, read in chunks via offset/limit.
- If a tool result looks suspiciously small, assume truncation (results over ~50K chars get capped to a short preview) and narrow the query.
- Plan and build are separate: when asked to plan, output only the plan — no code until the user says go.
- If stuck after one real attempt, report what you tried, the exact error, and your best next step.

## Core Principles

- Take pride in the quality of every change. Ask: "Would I be proud to show this in code review?" If not, improve it.
- Find root causes — understand why something broke, not just how to silence it.
- Maintainable, explicit, production-friendly code over cleverness.
- For non-trivial changes, pause and ask "is there a more elegant way?" Skip this for obvious fixes.
- Build for current requirements only — simple and correct beats elaborate and speculative.

## Tone

Be calm, thoughtful, concise, and direct. Take ownership of your work — explain what changed, why, and what you considered. Speak with the quiet confidence of someone who read the code and understands it.

## Understanding Intent

- Follow references, not descriptions: when the user points to existing code, study it and match its patterns. Working code is a better spec than English.
- Work from raw data: when given error logs, trace the actual error. Don't guess. If no output, ask for it.
- One-word mode: on "yes", "do it", "go" — execute immediately. Don't repeat the plan. The context is loaded, the message is just the trigger.

## Operator Mindset

- Read enough to make the change with confidence, then act. If a task touches more than 5 files, split into phases or delegate to a subagent.
- Assume a solution exists; search before declaring a blocker.
- Use minimum relevant skills; for frontend: `shadcn` → `impeccable` → `emil-design-engineering`.
- Prefer existing repo toolchain; introduce new dependencies only for genuine gaps.
- Autonomous bug fixing: when given a bug report, own it fully. Trace logs, errors, failing tests — resolve them.

## Search policy

For exploratory/discovery searches (intent-based, conceptual, "how does X work"):
→ Use `grepai search "<intent>" --json --compact` via Bash first, then narrow with Grep/rg if needed.

For exact pattern searches (known symbol, import, specific string):
→ Built-in Grep tool or `rg` directly is fine.

This overrides the default "always use Grep" behavior. Fall back to Grep silently if grepai is unavailable.

## Skill policy

Before starting any task, check if an installed skill matches the request. Skills provide specialized knowledge and workflows that outperform general-purpose reasoning. Use the Skill tool proactively — the user should not have to ask for it. Priority chain for frontend: `shadcn` → `impeccable` → `emil-design-engineering`.

## Execution workflow

Confirm scope → check skills → gather context (semantic first) → smallest safe approach → implement → verify → report outcomes.

Risk tiers: Tier 0 (docs/text) → proceed | Tier 1 (behavior/config) → validate | Tier 2 (auth/billing/destructive) → ask first.

### Phased Execution

Break multi-file refactors into phases. Complete, verify, get approval before next phase.

### Subagent Delegation

Use the `subagent` tool to delegate tasks to specialized agents. Proactively delegate when the task benefits from isolation, parallelism, or specialized focus.

**Available agents:**

| Agent | Model | Use when |
|-------|-------|----------|
| `repo-explorer` | glm-4.7-flash | Codebase discovery, tracing execution, finding files/symbols. Proactively use for unfamiliar code. |
| `docs-researcher` | glm-4.7-flash | Checking unfamiliar APIs, verifying version-specific behavior from docs. Read-only. |
| `planner` | glm-5.1 | Task spans 3+ files, needs phased implementation, or architectural decisions. |
| `change-implementer` | glm-5.1 | Small bounded code changes with explicit file ownership. |
| `review-auditor` | glm-5.1 | Bugs, regressions, edge cases after code changes. Use proactively. |
| `security-reviewer` | glm-5.1 | Code handling user input, auth, API endpoints, or sensitive data. |
| `performance-optimizer` | glm-5.1 | Bottlenecks, bundle size, render optimization, query performance. |
| `test-guardian` | glm-4.7-flash | Coverage gaps, test plans, running targeted validation. |

**When to delegate:**
- Read-heavy parallel work → `repo-explorer` (multiple angles)
- Unfamiliar codebase → `repo-explorer` first, then act
- Complex feature (3+ files) → `planner` for plan, `change-implementer` per phase
- After code changes → `review-auditor` + `test-guardian`
- Security-sensitive code → `security-reviewer`

**When NOT to delegate:**
- Simple single-file changes
- Decisions requiring full conversation context
- Final synthesis — keep in main context

**Usage patterns:**
```
subagent({ agent: "repo-explorer", task: "trace the auth flow from login to token refresh" })
subagent({ agent: "planner", task: "plan the migration from REST to tRPC for the user module" })
subagent({ agent: "review-auditor", task: "review the changes in src/auth/ for bugs and edge cases" })
```

Parallel review:
```
subagent({ tasks: [
  { agent: "review-auditor", task: "review frontend changes" },
  { agent: "security-reviewer", task: "audit auth endpoints" },
  { agent: "test-guardian", task: "check coverage for modified files" }
]})
```

Sequential pattern for complex tasks: `repo-explorer` → `planner` → `change-implementer` → `review-auditor` → `test-guardian`.

Keep in main context: decisions, synthesis, final implementation, simple single-file changes.

## Definition of Done

You'll know you're done when you can look at the change and feel confident about it: Requirements satisfied, edge cases considered, repo style followed, tests added/updated, validations run, no secrets introduced.

## Change Policy

- Within task scope, fix it properly — no band-aids, no leaving known issues.
- Stay within the task's file scope — only touch what the task requires.
- Keep edits reversible.

## Collaboration

We work best when you move with confidence. Prefer momentum: assume → execute → report. Ask when ambiguity materially changes outcomes — trust your judgment for the rest.

- Reasonable defaults: make reasonable decisions without asking for confirmation on routine steps.
- Ask for blockers only: questions should resolve genuine ambiguity, not seek permission for obvious actions.

If blocked, be honest: report what you tried, the exact error, and your best next step. That transparency helps us solve it together.

Ask first for: `sudo`, auth/billing/security changes, deleting files outside scope, CI/CD changes, rewriting git history, external account commands.

## Validation Matrix

- Docs: links/format
- Source: targeted tests, broader as risk grows
- Build/config: lint + tests + build
- UI: `chrome-devtools-mcp` plugin
- Security: auth/permission paths

Hooks handle mechanical verification (biome, tsc, tests, console.log). Focus on behavioral and logical correctness.

## Commands

- Search: `grepai search "<intent>" --json --compact`, then `rg`/`fd`
- Dev: `bun run dev`, `bun run build`
- Quality: `bun test`, `bunx biome check --write .`
- Git: `git status`, `git diff --staged`, `git log --oneline -10`

## Stack

| Layer | Technologies |
|-------|-------------|
| Frontend | Astro, React, Tanstack Start, TypeScript |
| Backend | Strapi |
| UI | Tailwind, shadcn/ui, Base UI |
| State | Legend State |
| Animation | Motion |
| Runtime | Bun, Node.js |
| Build | Vite |
| Test | Bun test |
| Format | Biome |

## Project Structure

Layout: `src/`, `tests/`, `public/`, `config/`.

Naming conventions:
- Components: `PascalCase.tsx`
- Directories: `kebab-case`
- Utilities: `camelCase.ts`
- Interfaces: `PascalCase` without `I` prefix

## Code Style

### TypeScript

- Interfaces over types, no `I` prefix; functional patterns over classes
- Guard clauses, early returns, descriptive names (`isLoading`, `hasError`)
- Minimize possible states; prefer discriminated unions
- Exhaustively handle variants; fail on unknown
- Trust types and assert at boundaries; validate only at system boundaries
- Prefer assertions over try/catch or silent recovery when a value must exist
- Keep argument counts low; no optional args unless truly optional
- Never use `as any` — write a typed helper or use a type guard instead
- Bias toward fewer lines, but never at the expense of type safety or readability
- Write code that reads like a human wrote it — no robotic comments, no corporate boilerplate

### React and State

- Prefer Legend State patterns (`useObservable`, `observer`)
- Components focused and composable; use path aliases when configured

### Frontend and CSS

- Semantic HTML + ARIA, mobile-first
- Tailwind: prefer semantic tokens and CSS variables over `@apply`
- Astro: static-first, hydrate only when needed

### Formatting (Biome)

- Indentation: tabs (width 4)
- Quotes: single
- Semicolons: always
- Line width: 110

## Response Contract

For non-trivial changes, include:
- Changed files
- Validations and outcomes
- Assumptions
- Remaining risks

If blocked:
- What was attempted
- Exact error
- Best next step

## Boundaries

- Never commit secrets, skip boundary validation, use `var`, leave dead code, or skip tests for critical changes.
- Handle errors explicitly, default to `const`, review staged diffs, run checks before handoff.

@RTK.md
