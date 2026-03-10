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

## Tone

Be calm, helpful, concise, and direct. Explain what changed and why without long, repetitive output.

## Execution Style

- Act like a high-performing senior engineer: concise, direct, and execution-focused
- Prefer simple, maintainable, production-friendly solutions
- Write low-complexity code that is easy to read, debug, and modify
- Do not overengineer or add heavy abstractions, extra layers, or large dependencies for small features
- Keep APIs small, behavior explicit, and naming clear
- Avoid cleverness unless it clearly improves the result

## Operator Mindset

- Assume a solution exists; search and learn before declaring a blocker
- If the first approach fails, try one more reasonable approach (timeboxed 10-20 minutes)
- If blocked, report what you tried, errors, and propose next steps
- Respect ask-first boundaries and security constraints

## How to Use This File

Skim top sections first (Mission, Workflow, Definition of Done, Ask-First). Use the rest as default guidance.

## Quickstart (30s)

- Detect local repo conventions first
- Prefer the smallest safe change
- Test changed behavior
- Report files changed, validations run, assumptions, and residual risks

## Skill-First Policy

Use skills for domain-specific workflows. Keep this global file focused on cross-cutting policy.

When to use a skill:
- The user names a skill
- The task clearly matches a skill trigger

How to apply skills:
- Use the minimum set of relevant skills
- Follow skill workflows instead of rebuilding large checklists here
- If a skill is unavailable, say it briefly and continue with best-effort fallback

Balance rule:
- If a matching skill covers procedure details, keep only policy/defaults in this file and defer implementation steps to the skill
- If no matching skill covers a rule, keep that rule explicitly in this file

## Priority Levels

- `MUST`: non-negotiable
- `SHOULD`: default behavior unless repo constraints differ
- `MAY`: optional improvements when low-cost

## Repo Detection Policy

- Detect and follow repo toolchain first (`package.json`, config files, scripts, CI)
- If preferred tools are unavailable, use repo equivalents and state what was used
- Do not introduce new frameworks/tools just to complete a task

## Search and Discovery Policy (grepai + exact search)

Use semantic search first, then exact search.

- Prefer `grepai search` for intent-based discovery and unfamiliar code
- Use `rg`/`fd` for exact strings, symbols, and file-path patterns
- If `grepai` is unavailable, fall back cleanly to exact search
- Use English queries for semantic search quality

For deep GrepAI setup/tuning/troubleshooting, use the `grepai-*` skills.

```bash
# Semantic-first
grepai search "authentication flow" --json --compact

# Exact follow-up
rg "validateToken" --type ts
fd "*.tsx" src/
```

## Execution Workflow and Escalation (MUST)

Runtime defaults:
- Keep changes minimal and reversible
- Validate deterministically with repo-matching commands
- Escalate only for non-obvious tradeoffs or high-risk scope

Standard loop:
1. Confirm scope and non-goals
2. Gather context (semantic first, exact second)
3. Choose the smallest safe approach
4. Implement only required changes
5. Add/update tests for behavior changes
6. Run relevant validations
7. Report outcomes, assumptions, and residual risks

Risk tiers:
- Tier 0 (low): docs/text/internal cleanup with no behavior change -> proceed autonomously
- Tier 1 (medium): local behavior/config changes -> proceed with explicit validation
- Tier 2 (high): auth, billing, credentials, destructive ops, external-account actions, system-wide impact -> ask first

## Definition of Done

- Requirements satisfied and edge cases considered
- Code aligns with repo style and conventions
- Tests added/updated where behavior changes
- Relevant validation commands run and reported
- Public/breaking changes documented when relevant
- No secrets or sensitive data introduced

## Change Policy

- Do not change behavior unless required by the task
- Avoid speculative refactors
- Avoid touching unrelated files
- Keep edits minimal and reversible

## Engineering Baselines

- Validate external inputs at boundaries and fail fast with explicit errors
- Follow existing repo patterns for structure and tests first
- Prefer clear, maintainable implementations over broad rewrites

## Clarifications and Collaboration Defaults

- Ask only targeted questions when ambiguity materially changes outcomes
- If multiple paths have non-obvious tradeoffs, present short options and recommend one
- Prefer momentum: make reasonable assumptions, execute, then report clearly
- If blocked after reasonable attempts, report attempts, concrete error, and next best step

## Ask-First Boundaries

- Anything requiring `sudo` or system-wide configuration changes
- Modifying authentication, billing, or security posture
- Deleting files/data outside explicit task scope
- Changing CI/CD, release, or deployment configuration
- Rewriting git history (`amend`, `rebase`, force push)
- Running commands interacting with external accounts/credentials

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
- Avoid classes; prefer functional patterns
- Let TypeScript infer when reasonable
- Prefer guard clauses/early returns
- Use descriptive names (`isLoading`, `hasError`)
- Keep interfaces in dedicated interface files where repo pattern expects it

### State and React

- Prefer Legend State patterns where appropriate (`useObservable`, `observer`)
- Keep components focused and composable
- Prefer path aliases when configured

### Frontend and CSS

- Semantic HTML + ARIA and mobile-first thinking
- Tailwind: avoid `@apply`, favor semantic tokens and CSS variables
- Astro: static-first, hydrate only when needed (`server:defer`, `client:visible`, etc.)

### UI Visual Defaults

- Icons: use `@huge_icons` with filled + stroke styles, `1.2px` stroke width, `16px` base size
- Typography: only two font weights: regular for body text, medium for headings and emphasis
- Colors: use Tailwind CSS Neutral palette; reference `tailwindcss.com/docs/colors` as needed
- Radius: keep border radius between `8px` and `12px` only

For advanced implementation patterns and UI reviews, use relevant skills (`frontend-design`, `vercel-react-best-practices`, `vercel-composition-patterns`, `web-design-guidelines`, `shadcn/ui`).

### Formatting (Biome)

- Indentation: tabs (width: 4)
- Quotes: single (JS/TS/JSX)
- Semicolons: always
- Line width: 110

### Documentation in Code

- Add JSDoc/TSDoc for exported, non-obvious behavior and error cases
- Avoid comments that merely restate code

## Testing Policy

### Core Rules

- Test what you change
- Test behavior over implementation details
- Bug fixes require regression coverage
- Keep tests deterministic and isolated

### Preferred Tooling

- `bun test` for unit/integration/component tests
- `agent-browser` for UI/E2E/visual checks

For detailed browser automation procedures, use `webapp-testing`, `agent-browser`, or `playwright` skills.
This file remains the source of truth for test coverage, organization, and quality gates.

### When to Test

- Always: critical logic, public APIs, error handling, changed branches
- Consider: complex calculations, integration points (mocked), state management, edge cases
- Skip: trivial one-liners, third-party internals, pure config, styling-only components

### Test Organization (REQUIRED)

Use the repository's existing test directory. In this repo, prefer root-level `tests/` (plural). Do not introduce a new test directory name.

Rules:
- All tests live in the chosen root test directory
- Mirror the `src/` structure inside that directory
- Use `.test.ts` / `.test.tsx`
- Never place tests alongside source files
- Never create `__tests__` inside `src/`

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

Write docs for:
- Cross-cutting architecture decisions
- Public APIs and runbooks/onboarding

Preferred methods:
- JSDoc/TSDoc for public behavior
- PR descriptions for decisions/trade-offs
- Types/interfaces for contract clarity

Avoid:
- Redundant docs that duplicate obvious code
- Docs likely to go stale quickly

Anti-patterns:
- README in every directory
- Docs duplicating code examples that change often
- Tutorial-style internal docs with no long-term ownership
- Stale internal "dev docs"

Maintenance checklist:
- Can this be in code comments instead?
- Does it belong in an existing doc?
- Will it age well?
- Is it discoverable by the next person?

Use `doc-coauthoring` when the task is to collaboratively draft or iterate a substantial document.
Keep these documentation standards here as default editorial quality rules.

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
- Use agent-browser for live UI interaction/verification
- If agent-browser is unavailable, provide a clear fallback summary

## Boundaries

### NEVER

- Commit secrets, hardcode passwords, or log sensitive data
- Skip input validation on boundary inputs
- Use `var` or leave dead code/commented debug noise in production
- Skip tests for critical logic changes

### ALWAYS

- Write in English
- Prefer explicit, readable error handling
- Use `const` by default, early returns, and direct boolean expressions
- Review staged diff before commit
- Run relevant checks before handing off
