# AGENTS.md

## Scope and Precedence

This file captures general agent guidance for application projects. When a repository provides its own `AGENTS.md` (or other higher-priority rules), follow those first. If guidance conflicts, the repo-level rules win.

## Mission

Ship correct, maintainable changes that fit the repo's conventions, with minimal churn and clear verification.

## Tone

Be a calm, helpful teammate. Keep responses short, direct, and friendly. Explain what you did and why, but avoid long walls of text or token-heavy dumps. Prefer crisp bullets and small code snippets.

## Operator Mindset

- Assume a solution exists; search and learn before declaring a blocker
- If the first approach fails, try one more reasonable approach (timeboxed 10–20 minutes)
- If blocked, report what you tried, errors, and propose next steps
- Respect ask-first boundaries and security constraints

## How to Use This File

Skim the top sections first (Mission, Definition of Done, Ask-First). Use the rest as a reference when you need specific conventions or examples.

## Definition of Done

- Requirements satisfied and edge cases considered
- Code matches repo style and patterns
- Tests added/updated where behavior changed
- `bun test` passes (when tests exist)
- `bunx biome check --write .` passes (when applicable)
- `bun run build` passes (when applicable)
- Public API or breaking changes documented when relevant
- Docs updated only when they add durable value
- No secrets or sensitive data introduced

## Change Policy

- Do not change behavior unless required by the task
- If behavior changes, add or update tests
- Avoid refactors not requested; if needed, explain briefly
- Avoid touching unrelated files; if formatting changes spill over, revert them

## Engineering Baselines

- Validate external inputs at boundaries and fail fast with explicit errors
- Follow existing test style and patterns in the repo first

## Clarifications

- If requirements are ambiguous, ask 1–2 targeted questions before proceeding

## Ask-First Boundaries

- Anything requiring `sudo` or system-wide configuration changes
- Modifying authentication, billing, or security posture
- Deleting files/data outside the explicit task scope
- Changing CI/CD, release, or deployment configurations
- Rewriting git history (amend, rebase, force push)
- Running commands that interact with external accounts or credentials


## Commands

```bash
# Search/Find (REQUIRED)
grepai search "user authentication flow" --json --compact # Semantic search (primary)
rg "pattern" --type ts                    # Exact text search
rg "function.*fetch" -g "*.ts"            # Exact regex search
fd "*.tsx" src/                           # Find files by pattern
fd -e ts -e tsx                           # Find by extensions

# Development
bun run dev                               # Start dev server
bun run build                             # Production build

# Quality
bun test                                  # Run Bun tests
bunx biome check --write .                # Lint + format (recommended)
bunx biome check .                        # CI check (no writes)

# Git
git status && git diff --staged           # Review before commit
git log --oneline -10                     # Recent commits
git commit -m "type: description"         # Commit format
```

## Stack

Typical stack used by Lionel for application projects. For this repository, prefer the local conventions and tooling already in use.

You can recommend alternatives if there is a clear, measurable improvement.

| Layer | Technologies |
|-------|-------------|
| **Frontend** | Astro, React, TypeScript |
| **Backend** | Strapi (TypeScript) |
| **UI** | Tailwind CSS, shadcn/ui, Base UI |
| **Animation** | Motion (motion.dev) |
| **Runtime** | Bun, Node.js |
| **Build** | Vite |
| **Test** | Bun test |
| **Format** | Biome |

## Project Structure

```
project/
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── ui/              # Base components (Button, Input, Modal)
│   │   └── features/        # Feature-specific components
│   ├── layouts/             # Page layouts (BaseLayout, AdminLayout)
│   ├── pages/               # Route pages (Astro file-based routing)
│   │   └── api/             # API endpoints
│   ├── lib/                 # Utilities and helpers
│   │   ├── utils.ts         # General utilities
│   │   └── api.ts           # API client functions
│   ├── interfaces/          # TypeScript interfaces
│   ├── hooks/               # Custom React hooks
│   ├── stores/              # State management
│   └── styles/              # Global CSS, Tailwind config
├── public/                  # Static assets
├── tests/                   # Test files
└── config/                  # App configuration
```

**Naming Conventions:**
- Components: `PascalCase.tsx` (e.g., `UserProfile.tsx`)
- Directories: `kebab-case` (e.g., `user-settings/`)
- Utilities: `camelCase.ts` (e.g., `formatDate.ts`)
- Interfaces: `PascalCase` without prefix (e.g., `User`, `Dossier`)

## Code Style

### TypeScript/JavaScript

**Rules:**
- Interfaces over types, no `I` prefix
- Do not define interfaces in implementation files; keep them in `src/interfaces/*`
- Let TypeScript infer when possible; type params/exports/complex returns only
- Functional patterns only (no classes)
- Guard clauses over nested conditionals; prefer inline guards and direct boolean returns
- Descriptive names with auxiliary verbs (`isLoading`, `hasError`)

**Do/Don't:**
- Do: `const isReady = count > 0;` / Don't: `if (count > 0) return true; else return false;`
- Do: `interface User` in `src/interfaces/user.ts` / Don't: inline interfaces in implementation files

```ts
const ensureEnabled = (isEnabled: boolean) => {
  if (isEnabled === true) return;
  throw new Error('Feature must be enabled');
};
```

```typescript
// src/interfaces/user.ts
export interface User {
  id: number;
  documentId: string;
  email: string;
  username: string;
  isActive: boolean;
}

// src/lib/api.ts
import type { User } from '@interfaces/user';

const fetchUser = async (id: string) => {
  if (!id) return null;
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error(`Failed: ${res.status}`);
  return res.json() as Promise<User>;
};
```

### Formatting (Biome)

- Indentation: tabs (width: 4)
- Quotes: single (JS/TS/JSX)
- Semicolons: always
- Line width: 110

```bash
bunx biome check --write .
```

### State Management (Legend State)

- Default over `useState`
- Local: `useObservable` + `observer`
- Shared: `observable(...)` in `src/stores/`, consume with `useSelector` / `observer`
- No `$` suffix; prefer clear names
- Avoid React Context when a store fits
- Store callbacks outside observables

```ts
import { observable } from '@legendapp/state';

export const userStore = observable({
  currentUserId: null as string | null,
  isLoading: false,
});

const callbacks = {
  onConfirm: null as null | (() => void),
};

export const modalStore = observable({
  getCallbacks: () => callbacks,
});
```

### Comments & Documentation (JSDoc/TSDoc)

**Write doc comments for:** exported functions/hooks/components, public APIs, non-obvious behavior, side effects, error cases.

**Avoid:** restating code, commented-out code, TODOs without an issue/link.

```ts
/**
 * Parses a human-entered amount (e.g. "12.50") into cents.
 * @throws Error if the input is not a valid decimal number.
 */
export const parseAmountToCents = (value: string) => {
  // ...
};
```

### Astro

- Prefer static HTML by default
- Hydration directives: `server:defer`, `client:load`, `client:idle`, `client:visible`
- Use `server:defer` with a fallback slot for expensive server rendering

```astro
---
import DashboardLayout from '@layouts/dashboard.astro';
import UserCard from '@components/UserCard';

const title = 'Dashboard';
const description = 'User dashboard';
---

<DashboardLayout {title} {description}>
  <UserCard server:defer>
    <div slot="fallback" class="animate-pulse bg-grey h-56 rounded-lg"></div>
  </UserCard>

  <HeavyChart client:visible />
</DashboardLayout>
```

### Strapi (Backend)

- Prefer `strapi.documents()` for document operations
- Use `documentId` (not `id`) for lookups
- Gate protected endpoints with `ctx.state.user` and admin checks

```ts
export default factories.createCoreController('api::dossier.dossier', ({ strapi }) => ({
  async findMine(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();
    return await strapi.documents('api::dossier.dossier').findMany({
      filters: { repartition: { user: { documentId: user.documentId } } },
    });
  },
}));
```

### React Components

- Use `observer` + `useObservable`
- Keep components small and focused
- Prefer path aliases for imports

```tsx
const UserCard = observer(({ user, onEdit }: UserCardProps) => {
  const isSavingState = useObservable(false);
  const handleEdit = useCallback(async () => {
    if (!onEdit) return;
    isSavingState.set(true);
    try {
      await onEdit(user);
    } finally {
      isSavingState.set(false);
    }
  }, [user, onEdit, isSavingState]);

  return <Button onClick={handleEdit} disabled={isSavingState.get()} />;
});
```

If a component needs local state, prefer `useObservable` over `useState`.

### Motion (Animation)

- Use `motion.div` for animated elements
- `initial`/`animate`/`exit` for entry/exit
- `whileHover`/`whileTap`/`whileDrag` for gestures
- `AnimatePresence` for exit animations
- `layout` for layout animations
- `transition` with `type: 'spring'` for natural motion
- Prefer `variants` + `staggerChildren` for orchestrated sequences

```tsx
const FadeIn = ({ children }) => (
  <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
    {children}
  </motion.div>
);
```

### Tailwind CSS

- Never use `@apply`
- Use semantic colors (`bg-card`, `text-muted-foreground`)
- Mobile-first (`sm:`, `md:`, `lg:`)
- Use CSS variables for theming (`rounded-(--radius-md)`)
- Use Front-end skill when available

```html
<button class="inline-flex items-center rounded-md bg-primary px-4 py-2 text-primary-foreground">
  Submit
</button>
```

## Testing

### Overview

Testing is required for code you change. You must create and maintain tests for new or modified behavior. This is non-optional and protects against regressions.

### Tools (REQUIRED)

**Only two tools:**
1. **Bun Test** for unit/integration/component tests (`bun test`)
2. **agent-browser** for UI/E2E/visual validation (https://agent-browser.dev/)

**Do not use:** Jest, Vitest, Playwright, Puppeteer, Selenium, Cypress. Only allow `@testing-library/react` for component testing.

**Notes:**
- **Bun Test:** fast, TS-native, includes mocking and async helpers.
- **agent-browser:** CLI for UI/E2E; use `snapshot -i` then target refs like `@e1`.

**Official Testing Stack:**
- Bun Test for unit, integration, and component tests.
- agent-browser for UI flows, visual checks, and accessibility checks.

### Core Principles

- Test what you touch
- Test behavior, not implementation
- Fail fast with meaningful names and assertions
- Bug fixes require a regression test
- Update tests when behavior changes
- Remove tests for deleted behavior

### When to Test

**Always:** critical logic, public APIs, bug fixes, data transforms, error handling, conditional branches.

**Consider:** complex calculations, integration points (mocked), state management, edge cases.

**Skip:** trivial one-liners, third-party internals, pure config, styling-only components.

### Test Organization (REQUIRED)

Use the repository's existing test directory. In this repo, prefer root-level `tests/` (plural). Do not introduce a new test directory name.

```bash
src/lib/api.ts              → tests/lib/api.test.ts
src/components/UserCard.tsx → tests/components/UserCard.test.tsx
src/utils/format.ts         → tests/utils/format.test.ts
```

**Rules:**
- All tests live in the chosen root test directory
- Mirror the `src/` structure inside that directory
- Use `.test.ts` / `.test.tsx`
- Never place tests alongside source files
- Never create `__tests__` inside `src/`

### Minimal Test Template

```ts
import { describe, it, expect, mock, beforeEach } from 'bun:test';

describe('feature', () => {
  beforeEach(() => mock.restore());

  it('handles valid input', () => {
    expect(doThing('ok')).toBe('result');
  });

  it('throws on invalid input', () => {
    expect(() => doThing('bad')).toThrow('Invalid');
  });
});
```

### Test Structure

- Keep a clear Arrange → Act → Assert flow
- One behavior per test; group related cases under `describe`
- Prefer deterministic tests; mock external I/O
- Use descriptive test names that state expected behavior

### Mocking External Dependencies

```ts
import { describe, it, expect, mock } from 'bun:test';

describe('API calls', () => {
  it('fetches user data successfully', async () => {
    global.fetch = mock(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ id: 1, name: 'Test User' }),
      })
    );

    const user = await fetchUser('123');
    expect(user).toEqual({ id: 1, name: 'Test User' });
  });
});
```

### Testing Async Code

```ts
describe('Async operations', () => {
  it('resolves with correct data', async () => {
    const result = await asyncFunction();
    expect(result).toBeDefined();
  });

  it('rejects with error', async () => {
    await expect(failingAsyncFunction()).rejects.toThrow('Error message');
  });
});
```

### React Component Tests

```ts
import { render, screen } from '@testing-library/react';

render(<UserCard user={user} />);
expect(screen.getByText(user.username)).toBeInTheDocument();
```

### UI Testing with agent-browser

**Use for:** visual regression, E2E flows, interactive UI, accessibility, dynamic content.
Use agent-browser for: login flows, forms, modals, animations, responsive checks, and key accessibility paths.
Use refs from `agent-browser snapshot -i` output (e.g. `@e1`, `@e2`) for reliable targeting.

```bash
agent-browser open http://localhost:3000/login
agent-browser snapshot -i
agent-browser fill @e3 "test@example.com"
agent-browser click @e2
agent-browser get text @e1
agent-browser screenshot page.png
agent-browser close
```

### Workflow

1. Analyze changes and edge cases
2. Decide coverage (happy path, errors, branches)
3. Write tests
4. Run `bun test`
5. Validate build/format if needed

### Regression Pattern

1. Write failing test
2. Fix bug
3. Verify test passes
4. Commit fix + test together

```ts
describe('Regression: large number handling', () => {
  it('does not throw on large inputs', () => {
    const largeAmount = 9007199254740991;
    expect(() => formatCurrency(largeAmount)).not.toThrow();
  });
});
```

### Anti-Patterns and Best Practices

**Don't:** order-dependent tests, mixed concerns, real external services, flaky tests, framework internals, blind copy-paste, commented-out failures.

**Do:** keep tests isolated, name intent clearly, mock external deps, keep tests fast, focus on public behavior, refactor tests with code, delete obsolete tests.

### Agent Testing Checklist

- [ ] New/changed behavior has tests
- [ ] Bug fixes include regression tests
- [ ] Critical logic and error paths are covered
- [ ] Edge cases are covered where applicable
- [ ] `bun test` passes
- [ ] `bunx biome check .` passes
- [ ] `bun run build` passes (when applicable)
- [ ] UI changes validated with agent-browser when relevant
- [ ] No skipped/commented-out tests without reason

### Commands

```bash
bun test
bun test --watch
bun test file.test.ts
bun test --coverage
agent-browser open http://localhost:3000
agent-browser snapshot -i
agent-browser click @e2
agent-browser fill @e3 "test@example.com"
agent-browser get text @e1
agent-browser screenshot page.png
agent-browser close
bunx biome check --write .
bun run build
```

### Testing Philosophy

Focus on confidence, clarity, speed, and maintainability. If a test does not help catch bugs or clarify behavior, it is not pulling its weight.

### Test Before Committing

```bash
git status
git diff --staged
bunx biome check --write .
bun test
bun run build
```

### Husky Hooks (Pre-commit / Commit)

If Husky is configured in the repo, a normal `git commit` **does** run hooks by default
(unless `--no-verify` is used or `HUSKY=0` is set). Current hooks:

```bash
# pre-commit
bun test || exit 1
bunx @biomejs/biome check --write --staged --files-ignore-unknown=true --no-errors-on-unmatched
git update-index --again

# commit-msg
bunx --no -- commitlint --edit $1
```

## Git Workflow

### Branch Naming

```bash
feature/add-user-authentication
fix/login-redirect-loop
refactor/api-client-cleanup
test/add-payment-tests
chore/upgrade-dependencies
```

### Commit Messages

```bash
git commit -m "feat: add user authentication flow"
git commit -m "fix: resolve login redirect loop"
git commit -m "refactor: extract API client to separate module"
git commit -m "test: add unit tests for payment service"
git commit -m "chore: upgrade Astro to v4.0"
```

### Workflow

```bash
git checkout -b feature/my-feature
git push -u origin feature/my-feature
git fetch origin master
git rebase origin/master
bunx biome check .
bun test
bun run build
gh pr create --title "feat: description" --body "Description"
```

## Documentation Practices

**Default:** code should be self-documenting. Create docs only when they add durable, cross-cutting value.

**Docs usually NOT needed for:**
- Obvious code, standard patterns, small utilities
- Internal implementation details that change often
- Temporary or experimental work

**Docs appropriate for:**
- Complex architecture across modules
- Public APIs consumed by others
- Setup/onboarding and runbooks
- Project guidelines and conventions

**Preferred methods:** JSDoc/TSDoc for public behavior, PR descriptions for decisions/trade-offs, types for interfaces.

**Anti-patterns:** README in every directory, docs duplicating code, tutorial-style internal docs, stale "dev docs".

**Maintenance checklist:** can this be in code comments? does it belong in an existing doc? will it age well? is it discoverable?

```ts
/**
 * Formats currency with localization.
 * @throws TypeError for invalid amounts.
 */
export const formatCurrency = (amount: number, currency = 'USD') => {
  // ...
};
```

## Tooling Rules

- Use Context7 MCP for documentation lookups
- Use gh_grep MCP for real-world code examples
- Use Exa MCP for general web research
- Use agent-browser for live UI interaction/verification
- If agent-browser is unavailable, provide a clear fallback summary

## Boundaries

### NEVER

**Security:** commit secrets, hardcode passwords, log sensitive data, skip input validation.

**Code Quality:** use `var`, use `@apply`, use classes, over-type, use `I` prefix, write obvious comments, over-engineer, leave dead code, manually bump versions when semantic-release is configured.

**Testing:** skip tests for critical logic, test implementation details, leave `console.log` in production code.

### ALWAYS

**Code Standards:** write in English, prefer Legend State, use JSDoc/TSDoc for exported/public when behavior is non-obvious, interfaces over types, interfaces in `src/interfaces/*`, let TS infer, `const` over `let`, early returns, inline guards for single statements, return boolean expressions directly, descriptive names, handle errors explicitly, prefer path aliases.

**Architecture:** mobile-first, semantic HTML + ARIA, small components, extract reusable logic.

**Before Committing:** run `bunx biome check .`, `bun test`, `bun run build`, review `git diff --staged`.

**Performance:** prefer static generation, use Astro hydration directives appropriately, lazy load images, use grepai for semantic search and `rg`/`fd` for exact/path matching only.

## grepai - Semantic Code Search

**IMPORTANT: You MUST use grepai as your PRIMARY tool for code exploration and search.**

### When to Use grepai (REQUIRED)

Use `grepai search` INSTEAD OF rg/fd or grep/find for:
- Understanding what code does or where functionality lives
- Finding implementations by intent (e.g., "authentication logic", "error handling")
- Exploring unfamiliar parts of the codebase
- Any search where you describe WHAT the code does rather than exact text

### When to Use Standard Tools

Only use rg/fd (or Grep/Glob tools) when you need:
- Exact text matching (variable names, imports, specific strings)
- File path patterns (e.g., `**/*.go`)

### Fallback

If grepai fails (not running, index unavailable, or errors), fall back to standard Grep/Glob tools.
Try to init and run grepai first. Use the `grepai-*` skills for setup/troubleshooting.

### Usage

```bash
# Always use English queries for best results
grepai search "user authentication flow" --json --compact
grepai search "error handling middleware" --json --compact
grepai search "database connection pool" --json --compact
grepai search "API request validation" --json --compact
```

### Query Tips

- Use English for better semantic matching
- Describe intent, not implementation
- Be specific: "JWT token validation" beats "token"
- Results include: file path, line numbers, relevance, code preview

### Call Graph Tracing

Use `grepai trace` to understand function relationships:
- Finding all callers of a function before modifying it
- Understanding what functions are called by a given function
- Visualizing the complete call graph around a symbol

#### Trace Commands

**IMPORTANT: Always use `--json` for optimal AI agent integration.**

```bash
grepai trace callers "HandleRequest" --json
grepai trace callees "ProcessOrder" --json
grepai trace graph "ValidateToken" --depth 3 --json
```

### Workflow

1. Start with `grepai search` to find relevant code
2. Use `grepai trace` to understand function relationships
3. Use `Read` tool to examine files from results
4. Only use Grep/Glob tools for exact string or path searches if needed
