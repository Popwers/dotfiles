---
description: Concrete code shape limits, immutability, and edit safety rules
globs: "*.ts,*.tsx,*.js,*.jsx,*.astro,*.vue,*.svelte,*.py,*.go,*.rs,*.rb,*.java,*.kt,*.swift,*.php"
---

# Code Quality Limits

## Size Guards

- Functions: target <50 lines, investigate if longer
- Files: target 200-400 lines, max 800 — split by feature/domain if exceeded
- Nesting: max 4 levels — flatten with guard clauses and early returns
- When a file gets hard to reason about, suggest splitting into smaller focused files

## Immutability

- Create new objects instead of mutating; spread/destructuring for objects, `.map`/`.filter` for arrays
- Exception: performance-critical hot paths where mutation is measurably faster

## One Source of Truth

One source of truth, everything else reads from it. If you're tempted to copy state to fix a rendering bug, the real fix is upstream.

## Rename Safety

When renaming, verify call sites, type references, string literals, dynamic imports, re-exports, and test fixtures — a single grep rarely catches everything.

## Type Safety

- Never use `as any` to silence the compiler — create a narrow typed helper or type guard instead
- Extract data from untyped API responses via an extraction function with an explicit return type
- `as never` only for framework-imposed loose typing (e.g. Strapi document APIs)

## Naming

- In files over 200 lines, full descriptive names; single-letter variables only in trivial lambdas and loop indices
- Boolean prefixes: `is`, `has`, `should`, `can` — no exceptions
- Name things for what they represent, not their type: `contactPayload` not `obj`

## Server-Side Robustness

- Never silently skip invalid input — every validation branch produces observable feedback: thrown error, logged warning, or user-visible message
- Ownership validation belongs in the database query (filter by user), not post-hoc JS checks
- Auth check (`ctx.state.user`) + ownership check on every mutating endpoint, not just reads
- Multi-step mutations must be transactional: if step 2 fails, rollback step 1
- Guard external input parsing: wrap `JSON.parse` in try/catch, never trust client payloads

## Data Preparation in Components

- Pre-compute data structures above the JSX return — no IIFEs or complex logic inline in the render
- JSX contains only mapping, conditional rendering, and event handlers

## React Hooks Discipline

- Don't remove `useCallback`/`useMemo` just for brevity — if removing creates a lint warning, keep them
- Wrap functions used as hook dependencies in `useCallback`; prefer stable references

## Comments

Always in **English**. Write them when code, types, and names don't already convey what the reader needs; skip them when they do.

### Write

- **Exported functions, hooks, components** — JSDoc block: one-line description, `@param` per prop/argument, `@returns`. Multi-sentence is fine when needed.

```ts
/**
 * Header component shows information about the current step of the user.
 * @param {string} props.mode - The mode of the header, either 'qcm' or 'results'
 * @returns {React.FC} - The Header component
 */
```

- **Non-obvious logic** — short `//` above the statement explaining the *why*: business rule, security constraint, edge case, ordering requirement, workaround.
- **Navigational labels** — a one-line `//` above an event handler, animation step, or logical block is a useful scanning aid even if slightly redundant.
- **Section dividers** — `/** --- CONTROLLERS --- */` or the multi-line ASCII-decorated form, separating distinct sections (controllers/policies/routes, input/state/handlers). The decoration is intentional scanning weight — both forms are fine in any multi-section file.

### Never write

- Name restatements (`// Get user CA` above `getUserCA()`)
- Ticket IDs (`NIID-294`) — that context belongs in the commit message
- Caller lists (`// called by getAllUsers`, `cf.`, `voir`) — the IDE call graph does it better and it goes stale
- Gratuitous decoration: ASCII banners on every export, or atop a single-purpose file with no internal sections
- 3+ stacked `//` lines covering one continuous explanation — use one `/** */` block
- Non-English comments — translate to English
- Step-by-step narration of the next 5 lines — simplify the code instead

### On cleanup, preserve the author's formatting

Cleanup is **not** a re-formatting pass: don't collapse `/** */` blocks into `//`, don't strip ASCII decoration from labeled dividers, don't rewrite multi-sentence JSDoc into one-liners — that style call is the author's. The only structural rewrite allowed is 3+ stacked `//` → one `/** */` block. Delete a comment only when it matches the "Never write" list; everything else stays in its original block format, with non-English translated in place.

## Pre-Completion Checklist

- Clear, descriptive naming; no hardcoded values outside config
- Error paths handled explicitly (no silent swallowing)
- No leftover debug code (console.log, debugger)
- Zero `as any` in new code
- Validation produces visible feedback, never silent skips
