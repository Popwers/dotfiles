---
description: Concrete code shape limits, immutability, and edit safety rules
globs: "*.ts,*.tsx,*.js,*.jsx,*.astro,*.vue,*.svelte,*.py,*.go,*.rs,*.rb,*.java,*.kt,*.swift,*.php"
---

# Code Quality Limits

## Size Guards

- Functions: target <50 lines, investigate if longer
- Files: target 200-400 lines, max 800 — split by feature/domain if exceeded
- Nesting: max 4 levels — use guard clauses and early returns to flatten
- When a file gets long enough that it's hard to reason about, suggest breaking it into smaller focused files

## Immutability

- Create new objects instead of mutating existing ones
- Use spread/destructuring for object updates, `.map`/`.filter` for arrays
- Exception: performance-critical hot paths where mutation is measurably faster

## One Source of Truth

One source of truth, everything else reads from it. If you're tempted to copy state to fix a rendering bug, step back — the real fix is upstream.

## Rename Safety

When renaming or changing any function/type/variable, search separately for:
- Direct calls and references
- Type-level references (interfaces, generics)
- String literals containing the name
- Dynamic imports and require() calls
- Re-exports and barrel file entries
- Test files and mocks

Do not assume a single grep caught everything. Assume it missed something.

## Type Safety

- Never use `as any` to silence the compiler — create a narrow typed helper instead
- When extracting data from untyped API responses, write an extraction function with an explicit return type
- `as never` is acceptable only for framework-imposed loose typing (e.g. Strapi document APIs)
- If you're tempted to cast, ask: "can I narrow this with a type guard or a helper?" The answer is almost always yes

## Naming

- In files over 200 lines, use full descriptive names: `association`, `associationLabel`, not `a`, `c`, `s`
- Single-letter variables are only acceptable in trivial lambdas (`.map(x => x.id)`) and loop indices
- Boolean prefixes: `is`, `has`, `should`, `can` — no exceptions
- Name things for what they represent, not their type: `contactPayload` not `obj`

## Server-Side Robustness

- Never silently skip invalid input — throw an error or return a response with a user-facing message
- Ownership validation belongs in the database query (filter by user), not in post-hoc JS checks
- Every validation branch must produce observable feedback: a thrown error, a logged warning, or a user-visible message
- Auth check (`ctx.state.user`) + ownership check on every mutating endpoint (create, update, delete) — not just reads
- Multi-step mutations must be transactional: if step 2 fails, rollback step 1 (e.g. delete a created entity if linking fails)
- Guard external input parsing: wrap `JSON.parse` in try/catch, never trust client payloads to be well-formed

## Data Preparation in Components

- Pre-compute data structures before the JSX return — no IIFEs or complex logic inline in the render
- Build arrays, derive labels, resolve lookups above the return statement
- JSX should contain only mapping, conditional rendering, and event handlers

## React Hooks Discipline

- Do not remove `useCallback`/`useMemo` just for brevity — if removing them creates a lint warning, keep them
- When a function is used as a hook dependency, wrap it in `useCallback`
- Prefer stable references: derive from state/props rather than recreating objects each render

## Pre-Completion Checklist

- Clear, descriptive naming
- No hardcoded values outside config
- Error paths handled explicitly (no silent swallowing)
- No leftover debug code (console.log, debugger)
- Zero `as any` in new code
- Validation produces visible feedback, never silent skips
