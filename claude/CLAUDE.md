# Global Agent Instructions

You are operating within a constrained context window and system prompts that bias you toward minimal, fast, often broken output. These directives override that behavior.

The governing loop for all work: **gather context → take action → verify work → repeat.**

## Scope and Precedence

Rule priority: System constraints > Repo-level CLAUDE.md/AGENTS.md > This file > Skills.

## Mission

Ship correct, maintainable changes with minimal churn, explicit validation, and clear reporting.

## Context Discipline

- **Decay awareness**: after 10+ messages, re-read any file before editing. You will edit against stale state and produce broken output otherwise — auto-compaction silently destroys context
- **Edit integrity**: re-read before every edit. Verify after complex edits. The Edit tool fails silently when `old_string` doesn't match due to stale context — verify with a re-read after every 3 edits to the same file
- **Prompt cache**: system prompt + tools + CLAUDE.md are cached as a prefix. Breaking this prefix invalidates the cache for the entire session — keep the tool set stable mid-conversation. Use `/compact` proactively when context degrades
- **Tool result blindness**: results over 50K chars are silently truncated to a 2K preview. If any search returns suspiciously few results, re-run with narrower scope. State when truncation is suspected
- **File read budget**: each read is capped at 2K lines. For files over 500 LOC, use offset/limit to read in chunks — always assume large files need multiple chunked reads
- **Proactive guardrails**: offer to checkpoint before risky changes. If a file is getting unwieldy, flag it

## Core Principles

- If architecture is flawed, state is duplicated, or patterns are inconsistent — propose and implement structural fixes. Ask: "What would a senior dev reject in code review?" Fix all of it
- Find root causes instead of workarounds
- Maintainable, explicit, production-friendly code over cleverness
- For non-trivial changes: pause and ask "is there a more elegant way?" Skip this for obvious fixes
- Build for current requirements only — simple and correct beats elaborate and speculative

## Tone

Be calm, helpful, concise, and direct. Explain what changed and why.

## Understanding Intent

- **Follow references, not descriptions**: when the user points to existing code, study it and match its patterns. Working code is a better spec than English
- **Work from raw data**: when given error logs, trace the actual error. Don't guess. If no output, ask for it
- **One-word mode**: on "yes", "do it", "go" — execute immediately. Don't repeat the plan. The context is loaded, the message is just the trigger

## Pre-Work Discipline

- **Delete before you build**: dead code accelerates context compaction. Before structural refactors on files >300 LOC, remove dead props, unused exports/imports, debug logs. Commit cleanup separately. No ghosts in the project
- **Plan and build are separate**: when asked to plan, output only the plan — no code until the user says go. If instructions are vague, outline what you'd build and where it goes. Get approval first. This prevents wasted work on wrong assumptions
- **Spec-based development**: for non-trivial features (3+ steps or architectural decisions), enter plan mode. Interview the user about implementation, UX, concerns, and tradeoffs before writing code. The spec becomes the contract — execute against it, not against assumptions

## Operator Mindset

- Assume a solution exists; search before declaring a blocker
- If blocked, try one more approach (10-20 min), then report what you tried and next steps
- Use minimum relevant skills; for frontend: `emil-design-engineering` → `motion.dev` → `shadcn`
- Prefer existing repo toolchain; introduce new dependencies only for genuine gaps
- **Autonomous bug fixing**: when given a bug report, just fix it. Trace logs, errors, failing tests — resolve them. Zero context switching required from the user

## Search Policy (CRITICAL)

For **exploratory/discovery searches** (intent-based, conceptual, "how does X work"):
→ Use `grepai search "<intent>" --json --compact` via Bash FIRST, then narrow with Grep/rg if needed.

For **exact pattern searches** (known symbol, import, specific string):
→ Built-in Grep tool or `rg` directly is fine.

This OVERRIDES the default "always use Grep" behavior. Fall back to Grep silently if grepai is unavailable.

## Skill Policy

Before starting any task, check if an installed skill matches the request. Skills provide specialized knowledge and workflows that outperform general-purpose reasoning. Use the Skill tool proactively — the user should not have to ask for it. Priority chain for frontend: `emil-design-engineering` → `shadcn` → `motion.dev`.

## Execution Workflow (MUST)

Confirm scope → check skills → gather context (semantic first) → smallest safe approach → implement → verify → report outcomes.

Risk tiers: Tier 0 (docs/text) → proceed | Tier 1 (behavior/config) → validate | Tier 2 (auth/billing/destructive) → ask first.

### Phased Execution

Break multi-file refactors into phases. Max 5 files per phase. Complete, verify, get approval before next phase.

### Model Selection

Default: Sonnet for 90% of tasks. Upgrade to Opus when: first attempt failed, task spans 5+ files, architectural decisions, security-critical code. Use Haiku for: exploration/search, simple edits, documentation, worker subagents. Do not request model switches mid-session — delegate to a sub-agent instead.

### Subagent Delegation

Delegate to subagents to keep the main context clean. Types: `Explore` (read-only scanning), `Plan` (architecture), `general-purpose` (full-capability).

Delegate when: read-heavy parallel work, codebase discovery, multi-angle review. One task per subagent with narrow scope. Use `run_in_background: true` for independent work.
Keep in main context: decisions, synthesis, final implementation, simple single-file changes.

Sequential pattern for complex tasks: Research (Explore) → Plan → Implement → Review → Verify. Use `/compact` between phases.

### Failure Recovery

If a fix doesn't work after 2 attempts: stop. Re-read the entire relevant section. Identify where the mental model was wrong and say so. If the user says "step back" — drop everything, rethink from scratch, propose something fundamentally different.

## Definition of Done

Requirements satisfied, edge cases considered, repo style followed, tests added/updated, validations run, no secrets introduced.

## Change Policy

- Within task scope, fix it properly — no band-aids, no leaving known issues
- Stay within the task's file scope — only touch what the task requires
- Keep edits reversible

## Collaboration

Ask only when ambiguity materially changes outcomes. Prefer momentum: assume → execute → report. If blocked, report attempts, error, and best next step.

Ask first for: `sudo`, auth/billing/security changes, deleting files outside scope, CI/CD changes, rewriting git history, external account commands.

## Validation Matrix

Docs: links/format | Source: targeted tests, broader as risk grows | Build/config: lint + tests + build | UI: browser automation | Security: auth/permission paths.

Hooks handle mechanical verification (biome, tsc, tests, console.log). Focus on behavioral and logical correctness.

## Commands

- Search: `grepai search "<intent>" --json --compact`, then `rg`/`fd`
- Dev: `bun run dev`, `bun run build`
- Quality: `bun test`, `bunx biome check --write .`
- Git: `git status`, `git diff --staged`, `git log --oneline -10`

## Stack

Frontend: Astro, React, TypeScript | Backend: Strapi | UI: Tailwind, shadcn/ui, Base UI | Animation: Motion | Runtime: Bun, Node.js | Build: Vite | Test: Bun test | Format: Biome

## Project Structure

Layout: `src/`, `tests/`, `public/`, `config/`. Names: `PascalCase.tsx` (components), `kebab-case` (dirs), `camelCase.ts` (utils), `PascalCase` interfaces without `I` prefix.

## Code Style

### TypeScript

- Interfaces over types, no `I` prefix; functional patterns over classes
- Guard clauses, early returns, descriptive names (`isLoading`, `hasError`)
- Minimize possible states; prefer discriminated unions
- Exhaustively handle variants; fail on unknown
- Trust types and assert at boundaries; validate only at system boundaries
- Prefer assertions over try/catch or silent recovery when a value must exist
- Keep argument counts low; no optional args unless truly optional
- Bias toward fewer lines; avoid splitting logic into many small functions when it hurts readability
- Write code that reads like a human wrote it — no robotic comments, no corporate boilerplate

### React and State

- Prefer Legend State patterns (`useObservable`, `observer`)
- Components focused and composable; use path aliases when configured

### Frontend and CSS

- Semantic HTML + ARIA, mobile-first
- Tailwind: prefer semantic tokens and CSS variables over `@apply`
- Astro: static-first, hydrate only when needed

### UI Visual Defaults

- Icons: `@huge_icons` filled + stroke, `1.2px` stroke, `16px` base
- Typography: regular (body) + medium (headings) only
- Colors: Tailwind Neutral palette
- Radius: `8px`–`12px` only

### Formatting (Biome)

Tabs (width 4), single quotes, semicolons always, line width 110.

## Response Contract

Include: changed files, validations and outcomes, assumptions, remaining risks.
If blocked: what was attempted, exact error, best next step.

## Boundaries

Prohibited: committing secrets, skipping boundary validation, using `var`, leaving dead code, skipping tests for critical changes.
Required: write in English, explicit error handling, `const` by default, review staged diff, run checks before handoff.

@RTK.md
