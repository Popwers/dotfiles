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

When renaming, verify call sites, type references, string literals, dynamic imports, re-exports, and test fixtures — a single grep rarely catches everything.

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

## Comments

Comments exist for the next reader. Write them when the code, the types, and the function name don't already convey what the reader needs to know — and skip them when they do. Always in **English**, regardless of the surrounding human-language strings.

### When a comment helps

- **Exported functions, hooks, and React/Astro components** — write a JSDoc block above the symbol with a one-line description of what it does, plus `@param` for each prop/argument and `@returns` for the return value. Multi-sentence JSDoc is fine when the explanation needs it.
- **Non-obvious logic inside a function** — write a short `//` line above the statement explaining a business rule, security constraint, edge case, ordering requirement, or workaround. The reader can see *what* the line does; your comment explains *why*.
- **Short navigational labels above logical blocks** — a one-line `//` label above an event handler, an animation step, a conditional branch, or a group of related statements is a useful scanning aid, even when slightly redundant with the code (e.g. `// On click, accept all cookies` above `acceptAllBtn.addEventListener('click', ...)`).
- **Section dividers** — multi-line ASCII-decorated `/** --- CONTROLLERS --- */` style dividers separating distinct sections in a file (controllers / policies / routes / helpers, or input / state / handlers / effects in a component) are fine in any file. The decoration is intentional — it makes the divider scannable when skimming a long file.

### On cleanup, preserve the author's original formatting

Cleanup is **not** a re-formatting pass. Do not collapse multi-line `/** */` blocks into single-line `//`, do not strip ASCII decoration around labeled section dividers, do not rewrite multi-sentence JSDoc into a one-liner. The author chose the format deliberately; that style call is theirs, not the cleanup pass's.

The only structural rewrite cleanup performs is **3+ stacked `//` lines covering one continuous explanation → single `/** */` block** (because stacked `//` for one explanation is a real anti-pattern, not a stylistic choice).

Cleanup deletes a comment only when it matches the "Never write" list below — name restatement, ticket IDs, caller lists, pure unlabeled decoration, top-of-single-purpose-file banners. Everything else stays in place, with French translated to English in its original block format.

### Acceptable JSDoc

```ts
/**
 * Header component shows information about the current step of the user.
 * @param {string} props.mode - The mode of the header, either 'qcm' or 'results'
 * @param {string} props.redirection - The redirection of the header
 * @returns {React.FC} - The Header component
 */
export default ({ mode, redirection }: HeaderProps) => { /* ... */ };
```

### Acceptable inline comment

```ts
// If the user must update their profile and is not on the profile page,
// and tries to access a protected route, redirect them to the profile page.
if (mustUpdateProfile && !isOnProfilePage && isProtectedRoute) {
    return redirect('/profile');
}
```

### Never write

- **Comments that restate the name** — `/** The consent store */` above `consentStore`, `// Get user CA` above `getUserCA()`. The name already says it. Delete.
- **Ticket IDs** — `NIID-294`, `JIRA-123`. They rot the moment the ticket closes; that context belongs in the commit message and PR description.
- **Caller lists** — `// called by getAllUsers, getManagedMembers`, `cf. functionName`, `(voir ...)`. The IDE call graph does this better and the list goes stale.
- **Decorative dividers used as gratuitous decoration** — `/** ===== ===== */` ASCII art on every export, or banners at the top of a single-purpose file with no internal sections (the filename already says it). Genuine section dividers (e.g. `/** --- CONTROLLERS --- */` separating controllers / policies / routes / helpers in a Strapi extension, or `/** --- ANIMATE --- */` separating animation calls from event listeners in a component) are fine in any file with multiple distinct sections — don't strip them.
- **Stacked `//` faking a multi-line block** — three or more `//` lines in a row covering one continuous explanation. Use `/** */` once instead.
- **Non-English comments** — French, Spanish, etc. in code committed to the repo. Translate to English.
- **Step-by-step narration of the next 5 lines** — if the code needs that much explanation, simplify the code itself.

### Anti-pattern (do not write)

```ts
/**
 * Get CA and CA to come of a user.
 * NIID-294 : une seule findMany sur les 4 statuts puis agrégation en JS, au
 * lieu de deux queries séquentielles. Réduit le coût quand l'endpoint
 * appelle getUserCA dans une boucle (cf. getAllUsers / getManagedMembers).
 */
```

Issues: French, ticket ID, caller list, narrative description of the implementation.

### Acceptable rewrite

```ts
/**
 * Compute realized and pending CA for a user, aggregated over the four statuses.
 * @param userId - The user whose CA we are computing.
 * @returns Aggregated `{ realized, pending }` totals.
 */
export async function getUserCA(userId: string) {
    // Single findMany over the four statuses; two sequential queries were the bottleneck on hot paths.
    // ...
}
```

### Section divider example

Both forms are acceptable — preserve whichever the author wrote:

```ts
/**
 * -----------------------------------------------
 * --------------- CONTROLLERS -------------------
 * -----------------------------------------------
 */
```

```ts
/** --- CONTROLLERS --- */
```

The ASCII decoration is intentional scanning weight, not noise to be stripped on cleanup.

## Pre-Completion Checklist

- Clear, descriptive naming
- No hardcoded values outside config
- Error paths handled explicitly (no silent swallowing)
- No leftover debug code (console.log, debugger)
- Zero `as any` in new code
- Validation produces visible feedback, never silent skips
