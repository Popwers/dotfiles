# AGENTS.md

## Scope and Precedence

This file defines global, cross-project agent behavior.

Rule priority:
1. System/developer/runtime constraints
2. Repository-level `AGENTS.md` (or equivalent local rules)
3. This global file
4. Skill-specific guidance (when triggered)

If instructions conflict, follow the highest-priority rule.

## Mission

Ship correct, maintainable changes with minimal churn, explicit validation, and clear reporting.

## Core Principles

- Simplicity first: choose the smallest change that solves the real problem
- Find root causes instead of workarounds
- Quality bar: prefer maintainable, explicit, production-friendly code over cleverness
- Minimal impact: keep edits focused, reversible, and limited to what the task requires

## Tone

Be calm, helpful, concise, and direct. Explain what changed and why without long, repetitive output.

## Execution Style

- Act like a high-performing senior engineer: concise, direct, execution-focused
- Prefer simple, maintainable, production-friendly solutions
- Keep APIs small, behavior explicit, and naming clear
- Keep solutions proportional: simple features use simple implementations
- Write low-complexity code that is easy to read, debug, and modify

## Operator Mindset

- Assume a solution exists; search and learn before declaring a blocker
- If the first approach fails, try one more reasonable approach (timeboxed 10-20 minutes)
- If blocked, report what you tried, errors, and propose next steps
- Respect ask-first boundaries and security constraints

## Quickstart

Detect repo conventions → smallest safe change → test changed behavior → report files, validations, assumptions, and risks.

## Skill-First Policy

Use skills for domain-specific workflows. Keep this global file focused on cross-cutting policy.

Use the minimum set of relevant skills. Follow skill workflows instead of rebuilding checklists here. If a skill covers procedure details, defer implementation steps to it.

For frontend/UI tasks: `emil-design-engineering` first → `motion.dev` for animation → `shadcn` for shadcn/ui → remaining frontend skills.

## Priority Levels

- `MUST`: non-negotiable
- `SHOULD`: default behavior unless repo constraints differ
- `MAY`: optional improvements when low-cost

## Repo Detection Policy

- Detect and follow repo toolchain first (`package.json`, config files, scripts, CI)
- If preferred tools are unavailable, use repo equivalents and state what was used
- Prefer existing repo toolchain; introduce new dependencies only for genuine gaps

## Search and Discovery Policy (grepai + exact search)

Semantic first (`grepai search`), then exact (`rg`/`fd`). Fall back cleanly if grepai is unavailable. Use English queries for semantic search quality.

## Execution Workflow and Escalation (MUST)

Runtime defaults:
- Keep changes minimal and reversible
- Validate deterministically with repo-matching commands
- Escalate only for non-obvious tradeoffs or high-risk scope

### Subagent Delegation Policy

Delegate to subagents to keep the main context clean. One task per subagent with narrow scope and concrete deliverable.

Delegate when: read-heavy parallel work, codebase discovery, documentation verification, multi-angle review, test-gap analysis.
Keep in main context: decisions, synthesis, final implementation, simple single-file changes, sequential dependencies.

Custom roles: `repo-explorer` (read-only discovery), `review-auditor` (bugs/regressions), `test-guardian` (coverage gaps), `change-implementer` (bounded changes), `docs-researcher` (API/framework verification).
Built-in: `explorer` for generic scanning, `worker` for bounded execution.

Loop: confirm scope → gather context (semantic first) → smallest safe approach → implement → test → validate → report.

Risk tiers: Tier 0 (docs/text) → proceed | Tier 1 (behavior/config) → validate | Tier 2 (auth/billing/destructive) → ask first.

Token discipline: targeted search first, then line-range reads, then widen only if needed. Return summaries with file paths and line numbers instead of large pasted excerpts.

## Definition of Done

Requirements satisfied, edge cases considered, repo style followed, tests added/updated, validations run, breaking changes documented, no secrets introduced.

## Change Policy

- Change behavior only when the task requires it
- Limit refactors and file changes to task scope
- Keep edits minimal and reversible

## Engineering Baselines

- Validate external inputs at boundaries and fail fast with explicit errors
- Follow existing repo patterns for structure and tests first
- Prefer clear, maintainable implementations over broad rewrites

## Collaboration

Ask only when ambiguity materially changes outcomes. Prefer momentum: assume → execute → report. If blocked, report attempts, error, and best next step.

Ask first for: `sudo`, auth/billing/security changes, deleting files outside scope, CI/CD changes, rewriting git history, external account commands.

## Validation Matrix (MUST)

- Docs-only changes: verify links/snippets/format consistency
- Source changes: run targeted tests first, broader checks as risk increases
- Build/config/tooling changes: run lint + tests + build
- UI behavior changes: validate key flow with browser automation
- Security-sensitive changes: validate auth/permission/error paths

## Commands

- Search: `grepai search "<intent>" --json --compact`, then `rg`/`fd`
- Development: `bun run dev`, `bun run build`
- Quality: `bun test`, `bunx biome check --write .`, `bunx biome check .`
- Git checks: `git status`, `git diff --staged`, `git log --oneline -10`

## Stack

Typical stack used by Lionel for application projects. Prefer local repo conventions when they differ.

| Layer | Technologies |
|-------|-------------|
| Frontend | Astro, React, TypeScript |
| Backend | Strapi (TypeScript) |
| UI | Tailwind CSS, shadcn/ui, Base UI |
| Animation | Motion (motion.dev) |
| Runtime | Bun, Node.js |
| Build | Vite |
| Test | Bun test |
| Format | Biome |

## Project Structure

Prefer a conventional app layout (`src/`, `tests/`, `public/`, `config/`) when the repo follows that model.

Naming conventions:
- Components: `PascalCase.tsx`
- Directories: `kebab-case`
- Utilities: `camelCase.ts`
- Interfaces: `PascalCase` without `I` prefix

## Code Style Defaults (when repo rules do not override)

### TypeScript/JavaScript

- Interfaces over types, no `I` prefix
- Prefer functional patterns over classes
- Let TypeScript infer when reasonable
- Prefer guard clauses/early returns
- Use descriptive names (`isLoading`, `hasError`)
- Keep interfaces in dedicated interface files where repo pattern expects it

### Code Shape Preferences

- Write extremely simple code that is easy to skim
- Minimize possible states by reducing arguments and narrowing state aggressively
- Prefer discriminated unions when they reduce the number of valid states
- Exhaustively handle multi-variant objects and fail on unknown variants
- Trust types and assert at boundaries; validate only at system boundaries
- Prefer assertions over try/catch or silent recovery for required values
- Make arguments optional only when they are truly optional
- Keep argument counts low; pass overrides only when strictly necessary
- Remove changes outside task scope
- Bias toward fewer lines of code and early returns
- Prefer straightforward code; keep logic together when splitting hurts readability

### State and React

- Prefer Legend State patterns where appropriate (`useObservable`, `observer`)
- Keep components focused and composable
- Prefer path aliases when configured

### Frontend and CSS

- Semantic HTML + ARIA and mobile-first thinking
- Tailwind: prefer semantic tokens and CSS variables over `@apply`
- Astro: static-first, hydrate only when needed (`server:defer`, `client:visible`, etc.)

### Formatting (Biome)

- Indentation: tabs (width: 4)
- Quotes: single (JS/TS/JSX)
- Semicolons: always
- Line width: 110

### Documentation in Code

- Add JSDoc/TSDoc for exported, non-obvious behavior and error cases
- Write comments that explain why, not what

## Testing Policy

### Core Rules

- Test what you change
- Test behavior over implementation details
- Bug fixes require regression coverage
- Keep tests deterministic and isolated

### Tooling and When to Test

- `bun test` for unit/integration/component, `chrome-devtools-mcp` for UI/E2E
- Always test: critical logic, public APIs, error handling, changed branches
- Consider: complex calculations, integration points, state management, edge cases
- Skip: trivial one-liners, third-party internals, pure config, styling-only

### Test Organization (REQUIRED)

Use the repository's existing test directory — prefer root-level `tests/` (plural).

Rules:
- All tests live in the chosen root test directory, mirroring `src/` structure
- Use `.test.ts` / `.test.tsx`
- Place tests only in the root test directory, not alongside source files or in `__tests__` inside `src/`

### Test Structure

- Keep a clear Arrange -> Act -> Assert flow
- One behavior per test; group related cases under `describe`
- Prefer deterministic tests; mock external I/O
- Use descriptive test names that state expected behavior

### Regression Pattern

1. Write failing test
2. Fix bug
3. Verify test passes
4. Commit fix + test together

### Minimum Validation Checklist

- [ ] Changed behavior has tests
- [ ] `bun test` passes (when applicable)
- [ ] `bunx biome check .` passes (when applicable)
- [ ] `bun run build` passes (when applicable)
- [ ] UI flow verified for UI behavior changes

## Git Workflow (Conventions)

- Branch naming: `feature/`, `fix/`, `refactor/`, `test/`, `chore/`
- Commit style: conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `chore:`)
- Keep commit history readable and scoped

Use `yeet` skill only when user explicitly asks for stage + commit + push + PR in one flow.

## Documentation Practices

Default: code should be self-documenting; add docs when they provide durable value.

Write docs for cross-cutting architecture decisions and public APIs.

Preferred methods: JSDoc/TSDoc for public behavior, PR descriptions for decisions/trade-offs, types/interfaces for contract clarity.

Prefer durable documentation; retire docs that duplicate obvious code or go stale. Use `doc-coauthoring` for substantial collaborative documents.

## Response Contract

Always include:
- Changed files
- Validation performed and outcomes
- Assumptions made
- Remaining risks/follow-ups (if any)

If blocked, include:
- What was attempted
- Exact error/constraint
- Best next step

## Tooling Rules

- Use Context7 MCP for documentation lookups
- Use gh_grep MCP for real-world code examples
- Use Exa MCP for general web research
- Use chrome-devtools-mcp for live UI interaction/verification
- If chrome-devtools-mcp is unavailable, provide a clear fallback summary

## Boundaries

Prohibited: committing secrets, skipping boundary validation, using `var`, leaving dead code, skipping tests for critical changes.

Required: write in English, explicit error handling, `const` by default, review staged diff, run checks before handoff.
