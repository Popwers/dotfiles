# Global Agent Instructions

## Scope and Precedence

Rule priority: System constraints > Repo-level CLAUDE.md/AGENTS.md > This file > Skills.

## Mission

Ship correct, maintainable changes with minimal churn, explicit validation, and clear reporting.

## Core Principles

- Simplicity first: smallest change that solves the real problem
- No laziness: find root causes, not workarounds
- Quality bar: maintainable, explicit, production-friendly code over cleverness
- Minimal impact: focused, reversible edits limited to the task
- Act like a high-performing senior engineer: concise, direct, execution-focused
- Do not overengineer or add heavy abstractions, extra layers, or large dependencies for small features

## Tone

Be calm, helpful, concise, and direct. Explain what changed and why.

## Operator Mindset

- Assume a solution exists; search before declaring a blocker
- If the first approach fails, try one more reasonable approach (timeboxed 10-20 min)
- If blocked, report what you tried, errors, and next steps
- Respect ask-first boundaries and security constraints

## Skill-First Policy

- Use the minimum set of relevant skills for domain-specific workflows
- For frontend/UI tasks: `emil-design-engineering` first → `motion.dev` → `shadcn` → remaining frontend skills

## Repo Detection

- Detect and follow repo toolchain first (`package.json`, config files, scripts, CI)
- Do not introduce new frameworks/tools just to complete a task

## Search Policy

Semantic first (`grepai search`), then exact (`rg`/`fd`). Fall back cleanly if grepai is unavailable. Use English queries for semantic search quality. For deep GrepAI setup/tuning, use the `grepai-*` skills.

## Execution Workflow (MUST)

1. Confirm scope and non-goals
2. Gather context (semantic first, exact second)
3. Choose the smallest safe approach
4. Implement only required changes
5. Add/update tests for behavior changes
6. Run relevant validations
7. Report outcomes, assumptions, and residual risks

Risk tiers:
- Tier 0 (low): docs/text/cleanup with no behavior change → proceed autonomously
- Tier 1 (medium): local behavior/config changes → proceed with explicit validation
- Tier 2 (high): auth, billing, credentials, destructive ops → ask first

### Subagent Delegation

Use the Agent tool to delegate work and keep the main context clean. Available `subagent_type` values: `Explore` (fast read-only scanning), `Plan` (architecture planning), `general-purpose` (full-capability).

When to delegate:
- Offload read-heavy work to subagents in parallel
- One task per subagent with narrow scope and concrete deliverable
- Keep the main agent on the critical path for decisions and final implementation
- Prefer `Explore` subagents first when the codebase is unfamiliar
- Use `run_in_background: true` for independent work that doesn't block next steps

Custom agents (`~/.claude/agents/`): `repo-explorer`, `review-auditor`, `test-guardian`, `change-implementer`, `docs-researcher`.

Avoid subagents for: simple single-file changes, sequential dependencies, parallel writes to same files.

## Definition of Done

Requirements satisfied, edge cases considered, repo style followed, tests added/updated, validations run, no secrets introduced.

## Change Policy

- Do not change behavior unless the task requires it
- Avoid speculative refactors and unrelated file changes
- Keep edits minimal and reversible

## Collaboration Defaults

- Ask only when ambiguity materially changes outcomes
- Prefer momentum: reasonable assumptions → execute → report clearly
- If blocked, report attempts, error, and best next step

## Ask-First Boundaries

`sudo`, auth/billing/security changes, deleting files outside scope, CI/CD changes, rewriting git history, external account commands.

## Validation Matrix (MUST)

- Docs-only: verify links/format
- Source: targeted tests first, broader as risk increases
- Build/config: lint + tests + build
- UI: validate key flow with browser automation
- Security: validate auth/permission/error paths

## Commands

- Search: `grepai search "<intent>" --json --compact`, then `rg`/`fd`
- Dev: `bun run dev`, `bun run build`
- Quality: `bun test`, `bunx biome check --write .`
- Git: `git status`, `git diff --staged`, `git log --oneline -10`

## Stack

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

Layout: `src/`, `tests/`, `public/`, `config/`. Names: `PascalCase.tsx` (components), `kebab-case` (dirs), `camelCase.ts` (utils), `PascalCase` interfaces without `I` prefix.

## Code Style

### TypeScript

- Interfaces over types, no `I` prefix; functional patterns over classes
- Guard clauses, early returns, descriptive names (`isLoading`, `hasError`)
- Minimize possible states; prefer discriminated unions
- Exhaustively handle variants; fail on unknown
- Trust types and assert at boundaries — no defensive code for impossible states
- Assertions over try/catch or silent recovery when a value must exist
- Keep argument counts low; no optional args unless truly optional
- Bias toward fewer lines; avoid splitting logic into many small functions when it hurts readability

### React and State

- Prefer Legend State patterns (`useObservable`, `observer`)
- Components focused and composable; use path aliases when configured

### Frontend and CSS

- Semantic HTML + ARIA, mobile-first
- Tailwind: no `@apply`, favor semantic tokens and CSS variables
- Astro: static-first, hydrate only when needed

### UI Visual Defaults

- Icons: `@huge_icons` filled + stroke, `1.2px` stroke, `16px` base
- Typography: regular (body) + medium (headings) only
- Colors: Tailwind Neutral palette
- Radius: `8px`–`12px` only

For advanced patterns and UI reviews: `emil-design-engineering` → `motion.dev` → `shadcn` → `frontend-design` → `vercel-react-best-practices` → `vercel-composition-patterns` → `web-design-guidelines`.

### Formatting (Biome)

Tabs (width 4), single quotes, semicolons always, line width 110.

## Testing Policy

- Test what you change; behavior over implementation details
- Bug fixes require regression coverage; deterministic and isolated tests
- Always test: critical logic, public APIs, error handling, changed branches
- Consider: complex calculations, integration points, state management
- Skip: trivial one-liners, third-party internals, pure config
- All tests in root `tests/` directory, mirroring `src/` structure. Use `.test.ts`/`.test.tsx`. Never place tests alongside source files.
- Arrange → Act → Assert. One behavior per test, `describe` for related cases. Descriptive names stating expected behavior.
- Regression pattern: write failing test → fix bug → verify pass → commit together.

## Git Workflow

- Branches: `feature/`, `fix/`, `refactor/`, `test/`, `chore/`
- Commits: conventional (`feat:`, `fix:`, `refactor:`, `test:`, `chore:`)
- Use `yeet` skill only when user explicitly asks for stage + commit + push + PR

## Documentation Practices

Code should be self-documenting. Add docs for cross-cutting architecture and public APIs.

- JSDoc/TSDoc for exported, non-obvious behavior
- PR descriptions for decisions/trade-offs
- Types/interfaces for contract clarity
- Avoid redundant docs, stale internal docs, READMEs in every directory

## Response Contract

Include: changed files, validations and outcomes, assumptions, remaining risks.
If blocked: what was attempted, exact error, best next step.

## Tooling Rules

- Context7 MCP for docs, gh_grep for code examples, Exa for web research
- agent-browser for live UI verification (fallback: clear summary)

## Boundaries

NEVER: commit secrets, skip boundary validation, use `var`, leave dead code, skip tests for critical changes.
ALWAYS: write in English, explicit error handling, `const` by default, review staged diff, run checks before handoff.
