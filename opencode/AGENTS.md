# AGENTS.md

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

Here is the stack used by Lionel, but you can make recommendations if you think you have better choices.

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

```typescript
// 1. Interfaces over types - NO "I" prefix, simple names
// Rule: do NOT define interfaces inside implementation files.
// Put them in dedicated type modules (e.g. src/interfaces/*) and import.

// src/interfaces/user.ts
export interface User {
  id: number;
  documentId: string;
  email: string;
  username: string;
  isActive: boolean;
  hasError?: boolean;
  createdAt: Date;
  avatar?: {
    url: string;
  };
}

export interface ApiResponse<T> {
  data: T;
  status: number;
  message?: string;
}

// src/lib/api.ts
import type { User } from '@interfaces/user';

// 2. Let TypeScript infer types - don't over-annotate
const fetchUser = async (id: string) => {
  if (!id) return null;

  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error(`Failed: ${res.status}`);

  return res.json();
};

// 3. Type only when necessary (params, exports, complex returns)
const users = await fetchApi<User[]>({ endpoint: 'users' });
const filteredUsers = users.filter(u => u.isActive); // inferred

// 4. Maps over enums
const Status = {
  Active: 'active',
  Inactive: 'inactive',
} as const;

type Status = (typeof Status)[keyof typeof Status];

// 5. Functional patterns - no classes
const createService = (baseUrl: string) => ({
  get: (id: string) => fetch(`${baseUrl}/${id}`),
  create: (data: User) =>
    fetch(baseUrl, {
      method: 'POST',
      body: JSON.stringify(data),
    }),
});

// 6. Guard clauses - early returns
const processOrder = (order: Order) => {
  if (!order) throw new Error('Order required');
  if (!order.items.length) throw new Error('Order must have items');
  if (order.total <= 0) throw new Error('Invalid order total');

  return submitOrder(order);
};

// 6b. Prefer inline guards when it's a single statement
const ensureEnabled = (isEnabled: boolean) => {
  if (isEnabled === true) return;
  throw new Error('Feature must be enabled');
};

// 6c. Prefer returning boolean expressions directly (avoid if/else)
const isUnderLimit = (count: number) => count < 7;

// 7. Descriptive names with auxiliary verbs
const isLoading = true;
const hasPermission = false;
const canEdit = true;
const shouldRefetch = false;
```

### Formatting (Biome)

These projects are typically formatted by **Biome** (replacing ESLint + Prettier).

- **Indentation:** tabs (width: 4)
- **Quotes:** single quotes (JS/TS/JSX)
- **Semicolons:** always
- **Line width:** 110

Prefer running:
```bash
bunx biome check --write .
```

### State Management (Legend State)

**Default:** use Legend State instead of `useState`.

- **Local component state:** `useObservable` + `observer`
- **Shared/global state:** put an `observable(...)` store in `src/stores/` and consume it via `useSelector` / `observer`
- **Naming:** do not use the `$` suffix for observables/selectors (prefer `*State`, `*Obs`, or clear names like `isLoadingState`)
- Avoid React Context for app state when a store fits better
- Store callbacks outside observables (Legend State doesn't handle function references well)

```tsx
import { observable } from '@legendapp/state';

export const userStore = observable({
  currentUserId: null as string | null,
  isLoading: false,
});
```

```ts
import { observable } from '@legendapp/state';

const callbacks = {
  onConfirm: null as null | (() => void),
};

export const modalStore = observable({
  getCallbacks: () => callbacks,
});
```

### Comments & Documentation (JSDoc/TSDoc)

Comments are allowed when they add information that types and code don't capture.

**Write doc comments for:**
- exported functions/hooks/components
- public APIs (used outside the module)
- non-obvious behavior, invariants, or performance constraints
- side effects (I/O, cache, analytics) and error cases (`throw`)

**Avoid:**
- comments that restate the code
- commented-out code
- TODOs without an issue/link

```ts
/**
 * Parses a human-entered amount (e.g. "12.50") into cents.
 *
 * @throws Error if the input is not a valid decimal number.
 */
export const parseAmountToCents = (value: string) => {
  // ...
};
```

### Astro

```ts
---
import DashboardLayout from '@layouts/dashboard.astro';
import UserCard from '@components/UserCard';
import type { User, Member } from '@interfaces/user';
import fetchApi from '@lib/strapi';

// Let TypeScript infer when possible
const currentPage = Number(Astro.url.searchParams.get('page')) || 1;
const userName = Astro.locals.user?.username ?? '';

// Type only the API response
const users = await fetchApi<User[]>({
  endpoint: 'users',
  token: Astro.locals.userToken,
});

// Inference handles the rest
const activeUsers = users.filter(u => u.isActive);
const title = 'Dashboard';
const description = 'User dashboard';
---

<DashboardLayout {title} {description}>
  <!-- server:defer for deferred loading with fallback -->
  <UserCard server:defer>
    <div slot="fallback" class="animate-pulse bg-grey h-56 rounded-lg"></div>
  </UserCard>

  <!-- client:load for immediate hydration -->
  <InteractiveComponent client:load data={activeUsers} />

  <!-- client:visible for below-fold content -->
  <HeavyChart client:visible />

  <!-- Static by default - preferred -->
  <section class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
    {users.map((user) => (
      <article class="p-4 border rounded-lg">
        <h2>{user.username}</h2>
        <p>{user.email}</p>
      </article>
    ))}
  </section>
</DashboardLayout>

<style>
  /* Scoped styles */
  article:hover {
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  }
</style>
```

**Hydration Directives:**
- `server:defer` - Server-side deferred with fallback slot
- `client:load` - Hydrate immediately (critical interactivity)
- `client:idle` - Hydrate when browser is idle
- `client:visible` - Hydrate when visible (below fold)
- No directive - Static HTML (preferred)

### Strapi (Backend)

```ts
import { factories } from '@strapi/strapi';

export default factories.createCoreController('api::dossier.dossier', ({ strapi }) => ({
	async findMine(ctx) {
		const user = ctx.state.user;
		if (!user) return ctx.unauthorized();

		return await strapi.documents('api::dossier.dossier').findMany({
			filters: {
				repartition: { user: { documentId: user.documentId } },
			},
		});
	},
}));
```

**Strapi 5 patterns:**
- Prefer `strapi.documents()` for document operations.
- Use `documentId` (not `id`) for lookups.
- Always gate protected endpoints with `ctx.state.user` and admin checks.

### React Components

```tsx
import { observer, useObservable } from '@legendapp/state/react';
import { useCallback } from 'react';
import { Button } from '@/components/ui/Button';
import type { User } from '@interfaces/user';
import type { UserCardProps } from '@interfaces/user-card';

const UserCard = observer(({ user, onEdit, isEditable = false }: UserCardProps) => {
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

  return (
    <div className="p-4 rounded-lg border bg-card">
      <h3 className="text-lg font-semibold">{user.username}</h3>
      <p className="text-muted-foreground">{user.email}</p>

      {isEditable && (
        <Button onClick={handleEdit} disabled={isSavingState.get()} variant="outline" size="sm">
          {isSavingState.get() ? 'Saving...' : 'Edit'}
        </Button>
      )}
    </div>
  );
});

export default UserCard;
```

### Motion (Animation)

```tsx
import { observer, useObservable } from '@legendapp/state/react';
import { motion, AnimatePresence } from 'motion/react';

// Basic animation with motion component
const FadeIn = ({ children }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ duration: 0.3 }}
  >
    {children}
  </motion.div>
);

// Spring physics animation
const SpringCard = () => (
  <motion.div
    whileHover={{ scale: 1.05 }}
    whileTap={{ scale: 0.95 }}
    transition={{ type: 'spring', stiffness: 300, damping: 20 }}
    className="p-4 rounded-lg bg-card cursor-pointer"
  >
    Click me
  </motion.div>
);

// Exit animations with AnimatePresence
const Modal = ({ isOpen, onClose, children }) => (
  <AnimatePresence>
    {isOpen && (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 bg-black/50"
        onClick={onClose}
      >
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          transition={{ type: 'spring', damping: 25, stiffness: 300 }}
          onClick={(e) => e.stopPropagation()}
          className="bg-card p-6 rounded-lg"
        >
          {children}
        </motion.div>
      </motion.div>
    )}
  </AnimatePresence>
);

// Layout animations
const ExpandableCard = observer(() => {
  const isExpandedState = useObservable(false);

  return (
    <motion.div
      layout
      onClick={() => isExpandedState.set(!isExpandedState.get())}
      className="p-4 rounded-lg bg-card cursor-pointer"
    >
      <motion.h3 layout="position">Title</motion.h3>
      {isExpandedState.get() && (
        <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
          Expanded content here
        </motion.p>
      )}
    </motion.div>
  );
});

// Gesture animations
const DraggableItem = () => (
  <motion.div
    drag
    dragConstraints={{ left: 0, right: 300, top: 0, bottom: 300 }}
    whileDrag={{ scale: 1.1, cursor: 'grabbing' }}
    className="w-20 h-20 bg-primary rounded-lg cursor-grab"
  />
);

// Stagger children
const StaggerList = ({ items }) => (
  <motion.ul
    initial="hidden"
    animate="visible"
    variants={{
      visible: { transition: { staggerChildren: 0.1 } },
    }}
  >
    {items.map((item) => (
      <motion.li
        key={item.id}
        variants={{
          hidden: { opacity: 0, x: -20 },
          visible: { opacity: 1, x: 0 },
        }}
      >
        {item.name}
      </motion.li>
    ))}
  </motion.ul>
);
```

**Motion Patterns:**
- Use `motion.div` instead of `div` for animated elements
- `initial` → starting state, `animate` → end state, `exit` → unmount state
- `whileHover`, `whileTap`, `whileDrag` for gesture-based animations
- `AnimatePresence` wraps elements that need exit animations
- `layout` prop enables automatic layout animations
- `transition` with `type: 'spring'` for natural physics
- `variants` + `staggerChildren` for orchestrated animations
- Use motion skill if available

### Tailwind CSS

```html
<!-- Mobile-first responsive design -->
<div class="flex flex-col gap-4 p-4 md:flex-row md:gap-6 md:p-6 lg:gap-8 lg:p-8">
  <!-- Card component with states -->
  <div class="rounded-lg border bg-card p-4 shadow-sm transition-shadow hover:shadow-md dark:border-gray-800">
    <h2 class="text-lg font-semibold text-foreground">Title</h2>
    <p class="mt-2 text-sm text-muted-foreground">Description</p>
  </div>

  <!-- Button with variants -->
  <button class="inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium bg-primary text-primary-foreground hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 disabled:pointer-events-none disabled:opacity-50 transition-colors">
    Submit
  </button>
</div>

<!-- Grid layout -->
<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
  <!-- items -->
</div>

<!-- Skeleton loading -->
<div class="animate-pulse bg-grey rounded-(--radius-md) h-56 p-8"></div>
```

**Tailwind Rules:**
- Never use `@apply` directive
- Use shadcn/ui semantic colors (`bg-card`, `text-muted-foreground`)
- Mobile-first: base styles first, then `sm:`, `md:`, `lg:`
- Use CSS variables for theming (`rounded-(--radius-md)`)
- Use Front-end skill if available

## Testing

### Bun Test

```typescript
import { describe, it, expect, mock, beforeEach } from 'bun:test';
import { fetchUser, createUser } from '@/lib/api';
import type { User } from '@interfaces/user';

describe('User API', () => {
  const mockUser: User = {
    id: 123,
    documentId: 'abc123',
    email: 'test@example.com',
    username: 'Test User',
    isActive: true,
    createdAt: new Date(),
  };

  beforeEach(() => {
    mock.restore();
  });

  describe('fetchUser', () => {
    it('returns user when found', async () => {
      global.fetch = mock(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve(mockUser),
        })
      );

      const user = await fetchUser('123');

      expect(user).toBeDefined();
      expect(user?.id).toBe(123);
      expect(user?.email).toBe('test@example.com');
    });

    it('returns null for empty id', async () => {
      const user = await fetchUser('');
      expect(user).toBeNull();
    });

    it('throws on network error', async () => {
      global.fetch = mock(() => Promise.resolve({ ok: false, status: 500 }));

      expect(fetchUser('123')).rejects.toThrow('Failed');
    });
  });
});
```

**Test Commands:**
```bash
bun test                              # All tests
bun test --watch                      # Watch mode
bun test user.test.ts                 # Single file
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
# Format: type: concise description

git commit -m "feat: add user authentication flow"
git commit -m "fix: resolve login redirect loop"
git commit -m "refactor: extract API client to separate module"
git commit -m "test: add unit tests for payment service"
git commit -m "chore: upgrade Astro to v4.0"
```

### Workflow

```bash
# Start feature
git checkout -b feature/my-feature
git push -u origin feature/my-feature

# Before PR
git fetch origin master
git rebase origin/master
bunx biome check .
bun test
bun run build

# Create PR
gh pr create --title "feat: description" --body "Description"
```

## Tooling Rules

- When you need to search documentation, use the Context7 MCP.
- If you are unsure how to do something, use the gh_grep MCP to search real-world GitHub code examples or Context7 to search documentation.
- For general web research and source discovery, use the Exa MCP.
- Use agent-browser for tasks that require live browser interaction or UI verification.
- If agent-browser is unavailable, provide a clear fallback summary of what was done and what could not be verified.

## Boundaries

### NEVER

**Security:**
- Commit secrets, tokens, API keys, .env files, credentials
- Hardcode passwords or sensitive data
- Log sensitive user information (passwords, tokens, PII)
- Skip input validation or sanitization

**Code Quality:**
- Use `var` in JavaScript (use `const`, minimal `let`)
- Use `@apply` directive in Tailwind
- Use classes in JavaScript (functional patterns only)
- Over-type when TypeScript can infer
- Use `I` prefix for interfaces (use `User` not `IUser`)
- Write obvious comments that repeat the code
- Over-abstract or over-engineer solutions
- Leave dead code or unused imports
- Manually bump versions when semantic-release is configured (release automation owns versions)

**Testing:**
- Skip tests for critical business logic
- Test implementation details instead of behavior
- Leave `console.log` in production code

### ALWAYS

**Code Standards:**
- Write all code, comments, and commits in English
- Prefer Legend State for state management (`useObservable` for local state; `src/stores/` for shared/global)
- Use JSDoc/TSDoc on exported/public functions when behavior isn't obvious (don't write comments that restate the code)
- Use interfaces over types in TypeScript (without `I` prefix)
- Define interfaces in dedicated type modules (e.g. `src/interfaces/*`) and import them (no inline interfaces in implementation files)
- Let TypeScript infer types when possible
- Use `const` over `let`, never `var`
- Use early returns over nested conditionals
- Prefer inline guard clauses when there's a single statement (`if (isEnabled === true) return;`)
- Prefer returning boolean expressions directly (avoid `if (...) { return true } else { return false }`)
- Use descriptive names with auxiliary verbs (`isLoading`, `hasError`)
- Handle errors explicitly, fail fast
- Prefer path aliases over relative imports when available (e.g. `@lib/*`, `@components/*`)

**Architecture:**
- Follow mobile-first responsive design
- Use semantic HTML with proper ARIA attributes
- Keep components small and focused
- Extract reusable logic into custom hooks/utilities

**Before Committing:**
- Run `bunx biome check .` and fix all issues
- Run `bun test` and ensure all pass
- Run `bun run build` to verify production build
- Review diff with `git diff --staged`

**Performance:**
- Prefer static generation over client-side rendering
- Use proper Astro hydration directives (`server:defer`, `client:visible`)
- Lazy load images and non-critical components
- Use grepai for semantic search; use `rg`/`fd` for exact text or path patterns (never `grep`/`find`)

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
But first try to init and run it. use skills to understand how to use it.
If you need setup or troubleshooting help, use the `grepai-*` skills (e.g., `grepai-init`, `grepai-quickstart`, `grepai-troubleshooting`) before proceeding.

### Usage

```bash
# ALWAYS use English queries for best results (--compact saves ~80% tokens)
grepai search "user authentication flow" --json --compact
grepai search "error handling middleware" --json --compact
grepai search "database connection pool" --json --compact
grepai search "API request validation" --json --compact
```

### Query Tips

- **Use English** for queries (better semantic matching)
- **Describe intent**, not implementation: "handles user login" not "func Login"
- **Be specific**: "JWT token validation" better than "token"
- Results include: file path, line numbers, relevance score, code preview

### Call Graph Tracing

Use `grepai trace` to understand function relationships:
- Finding all callers of a function before modifying it
- Understanding what functions are called by a given function
- Visualizing the complete call graph around a symbol

#### Trace Commands

**IMPORTANT: Always use `--json` flag for optimal AI agent integration.**

```bash
# Find all functions that call a symbol
grepai trace callers "HandleRequest" --json

# Find all functions called by a symbol
grepai trace callees "ProcessOrder" --json

# Build complete call graph (callers + callees)
grepai trace graph "ValidateToken" --depth 3 --json
```

### Workflow

1. Start with `grepai search` to find relevant code
2. Use `grepai trace` to understand function relationships
3. Use `Read` tool to examine files from results
4. Only use Grep for exact string searches if needed

## Testing Guidelines for Agents

### Overview

As an autonomous agent, you MUST create and manage tests for the code you write or modify. Testing is not optional—it's a critical part of ensuring code quality, preventing regressions, and building maintainable systems.

### Core Testing Principles

**1. Test What You Touch**
- Create tests for every new feature, function, or component you implement
- Add regression tests when fixing bugs to prevent recurrence
- Update existing tests when modifying behavior
- Remove tests for deleted functionality

**2. Test Behavior, Not Implementation**
- Focus on what the code does (outputs, side effects, user experience)
- Avoid testing internal implementation details
- Write tests that remain valid when refactoring

**3. Fail Fast with Meaningful Messages**
- Write descriptive test names that explain the expected behavior
- Use clear assertion messages that help diagnose failures quickly
- Group related tests with `describe` blocks for better organization

### When to Test (Decision Criteria)

#### ALWAYS Test

- **Critical business logic**: authentication, payment processing, data validation
- **Public APIs and exported functions**: anything consumed by other modules
- **Bug fixes**: add a regression test that fails without the fix, passes with it
- **Data transformations**: parsing, formatting, mapping, filtering
- **Error handling**: ensure errors are thrown/caught correctly
- **Conditional logic**: test all branches (if/else, switch, ternary)

#### CONSIDER Testing

- **Complex calculations or algorithms**: when logic is non-trivial
- **Integration points**: API calls, database operations (use mocks)
- **State management**: stores, observables, shared state
- **Edge cases**: null/undefined, empty arrays, boundary values

#### SKIP Testing

- **Trivial code**: simple getters/setters, one-line utilities
- **Third-party library internals**: trust maintained libraries
- **Configuration files**: JSON, env files (unless you're validating them)
- **Styling-only components**: pure presentational components with no logic

### Unit Testing with Bun

#### File Naming Convention

```bash
# Place tests alongside source files or in __tests__ directory
src/lib/api.ts          → src/lib/api.test.ts
src/utils/format.ts     → src/utils/__tests__/format.test.ts
```

#### Test Structure Template

```typescript
import { describe, it, expect, mock, beforeEach, afterEach } from 'bun:test';
import type { User } from '@interfaces/user';
import { functionToTest } from './module';

describe('Module: functionToTest', () => {
  // Setup: run before each test
  beforeEach(() => {
    // Reset mocks, initialize test data
    mock.restore();
  });

  // Teardown: run after each test (if needed)
  afterEach(() => {
    // Clean up resources, reset state
  });

  describe('Happy Path', () => {
    it('should return expected result for valid input', () => {
      const result = functionToTest('valid input');
      expect(result).toBe('expected output');
    });

    it('should handle multiple valid scenarios', () => {
      expect(functionToTest('case1')).toBe('output1');
      expect(functionToTest('case2')).toBe('output2');
    });
  });

  describe('Edge Cases', () => {
    it('should return default value for empty input', () => {
      const result = functionToTest('');
      expect(result).toBeNull();
    });

    it('should handle undefined gracefully', () => {
      const result = functionToTest(undefined);
      expect(result).toBe(null);
    });
  });

  describe('Error Handling', () => {
    it('should throw error for invalid input', () => {
      expect(() => functionToTest('invalid')).toThrow('Invalid input');
    });

    it('should throw specific error type', () => {
      expect(() => functionToTest(null)).toThrow(TypeError);
    });
  });
});
```

#### Mocking External Dependencies

```typescript
import { describe, it, expect, mock } from 'bun:test';

describe('API calls', () => {
  it('should fetch user data successfully', async () => {
    // Mock fetch globally
    global.fetch = mock(() =>
      Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ id: 1, name: 'Test User' }),
      })
    );

    const user = await fetchUser('123');

    expect(fetch).toHaveBeenCalledWith('/api/users/123');
    expect(user).toEqual({ id: 1, name: 'Test User' });
  });

  it('should handle fetch errors', async () => {
    global.fetch = mock(() =>
      Promise.resolve({
        ok: false,
        status: 404,
      })
    );

    await expect(fetchUser('invalid')).rejects.toThrow('User not found');
  });
});
```

#### Testing Async Code

```typescript
describe('Async operations', () => {
  it('should resolve with correct data', async () => {
    const result = await asyncFunction();
    expect(result).toBeDefined();
  });

  it('should reject with error', async () => {
    await expect(failingAsyncFunction()).rejects.toThrow('Error message');
  });

  it('should timeout after delay', async () => {
    const promise = longRunningFunction();
    const timeout = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Timeout')), 1000)
    );

    await expect(Promise.race([promise, timeout])).rejects.toThrow('Timeout');
  });
});
```

### Testing React Components

#### Component Test Template

```typescript
import { describe, it, expect } from 'bun:test';
import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import UserCard from './UserCard';
import type { User } from '@interfaces/user';

describe('UserCard Component', () => {
  const mockUser: User = {
    id: 1,
    documentId: 'abc123',
    email: 'test@example.com',
    username: 'Test User',
    isActive: true,
    createdAt: new Date(),
  };

  it('should render user information', () => {
    render(<UserCard user={mockUser} />);

    expect(screen.getByText('Test User')).toBeInTheDocument();
    expect(screen.getByText('test@example.com')).toBeInTheDocument();
  });

  it('should call onEdit when edit button is clicked', async () => {
    const handleEdit = mock(() => Promise.resolve());
    render(<UserCard user={mockUser} onEdit={handleEdit} isEditable={true} />);

    const editButton = screen.getByRole('button', { name: /edit/i });
    await userEvent.click(editButton);

    expect(handleEdit).toHaveBeenCalledWith(mockUser);
  });

  it('should disable button while saving', async () => {
    const slowEdit = mock(() => new Promise(resolve => setTimeout(resolve, 100)));
    render(<UserCard user={mockUser} onEdit={slowEdit} isEditable={true} />);

    const editButton = screen.getByRole('button', { name: /edit/i });
    await userEvent.click(editButton);

    expect(editButton).toBeDisabled();
    expect(screen.getByText('Saving...')).toBeInTheDocument();
  });

  it('should not render edit button when not editable', () => {
    render(<UserCard user={mockUser} isEditable={false} />);

    expect(screen.queryByRole('button', { name: /edit/i })).not.toBeInTheDocument();
  });
});
```

### UI Testing with Browser Agent

#### When to Use Browser Agent

Use `agent-browser` for:
- **Visual regression testing**: ensuring UI looks correct
- **End-to-end user flows**: login, checkout, form submission
- **Interactive components**: modals, dropdowns, tooltips, animations
- **Cross-browser compatibility**: testing in different browsers
- **Accessibility validation**: screen reader compatibility, keyboard navigation
- **Dynamic content**: content loaded via JavaScript, AJAX

#### Browser Agent Testing Pattern

```typescript
import { describe, it, expect } from 'bun:test';
import { launchBrowser, navigateTo, clickElement, fillInput, assertVisible } from 'agent-browser';

describe('User Authentication Flow (Browser)', () => {
  it('should complete login flow successfully', async () => {
    const browser = await launchBrowser();
    const page = await navigateTo(browser, 'http://localhost:3000/login');

    // Fill login form
    await fillInput(page, '#email', 'test@example.com');
    await fillInput(page, '#password', 'password123');

    // Submit form
    await clickElement(page, 'button[type="submit"]');

    // Verify redirect to dashboard
    await page.waitForNavigation();
    await assertVisible(page, '.dashboard-header');

    // Verify user info displayed
    const username = await page.textContent('.user-name');
    expect(username).toBe('Test User');

    await browser.close();
  });

  it('should show error for invalid credentials', async () => {
    const browser = await launchBrowser();
    const page = await navigateTo(browser, 'http://localhost:3000/login');

    await fillInput(page, '#email', 'invalid@example.com');
    await fillInput(page, '#password', 'wrongpassword');
    await clickElement(page, 'button[type="submit"]');

    // Verify error message appears
    await assertVisible(page, '.error-message');
    const errorText = await page.textContent('.error-message');
    expect(errorText).toContain('Invalid credentials');

    await browser.close();
  });
});
```

#### Visual Regression Testing

```typescript
describe('Visual Regression Tests', () => {
  it('should match modal appearance snapshot', async () => {
    const browser = await launchBrowser();
    const page = await navigateTo(browser, 'http://localhost:3000/components/modal');

    await clickElement(page, '#open-modal-btn');
    await assertVisible(page, '.modal');

    // Take screenshot and compare with baseline
    const screenshot = await page.screenshot();
    expect(screenshot).toMatchSnapshot('modal-open.png');

    await browser.close();
  });

  it('should verify responsive layout on mobile', async () => {
    const browser = await launchBrowser({ viewport: { width: 375, height: 667 } });
    const page = await navigateTo(browser, 'http://localhost:3000');

    // Verify mobile menu is visible
    await assertVisible(page, '.mobile-menu-toggle');

    // Verify desktop menu is hidden
    const desktopMenu = await page.isVisible('.desktop-menu');
    expect(desktopMenu).toBe(false);

    await browser.close();
  });
});
```

### Smart Testing Workflow

#### Step 1: Analyze Changes

Before writing tests, ask yourself:
- What functionality did I add or modify?
- What are the possible inputs and outputs?
- What edge cases exist?
- What could break in the future?
- What behavior is critical for users?

#### Step 2: Determine Test Coverage

```typescript
// Example: You added a new formatCurrency function
const formatCurrency = (amount: number, currency: string = 'USD'): string => {
  if (typeof amount !== 'number' || isNaN(amount)) {
    throw new TypeError('Amount must be a valid number');
  }

  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
  }).format(amount);
};

// Required tests (identified by analysis):
// 1. Happy path: valid number formats correctly
// 2. Default currency: USD is used when not specified
// 3. Different currencies: EUR, GBP work correctly
// 4. Edge cases: zero, negative numbers, decimals
// 5. Error handling: invalid input throws TypeError
```

#### Step 3: Write Tests

```typescript
import { describe, it, expect } from 'bun:test';
import { formatCurrency } from './format';

describe('formatCurrency', () => {
  describe('Valid inputs', () => {
    it('should format positive numbers with USD by default', () => {
      expect(formatCurrency(1234.56)).toBe('$1,234.56');
    });

    it('should format with specified currency', () => {
      expect(formatCurrency(1234.56, 'EUR')).toBe('€1,234.56');
      expect(formatCurrency(1234.56, 'GBP')).toBe('£1,234.56');
    });

    it('should handle zero', () => {
      expect(formatCurrency(0)).toBe('$0.00');
    });

    it('should handle negative numbers', () => {
      expect(formatCurrency(-100.50)).toBe('-$100.50');
    });

    it('should round to 2 decimal places', () => {
      expect(formatCurrency(10.999)).toBe('$11.00');
    });
  });

  describe('Invalid inputs', () => {
    it('should throw TypeError for non-number input', () => {
      expect(() => formatCurrency('123' as any)).toThrow(TypeError);
      expect(() => formatCurrency(null as any)).toThrow(TypeError);
      expect(() => formatCurrency(undefined as any)).toThrow(TypeError);
    });

    it('should throw TypeError for NaN', () => {
      expect(() => formatCurrency(NaN)).toThrow(TypeError);
    });
  });
});
```

#### Step 4: Run Tests and Verify

```bash
# Run all tests
bun test

# Run specific test file
bun test src/utils/format.test.ts

# Run in watch mode during development
bun test --watch

# Generate coverage report (if configured)
bun test --coverage
```

#### Step 5: Test Before Committing

```bash
# Pre-commit checklist
git status                          # Review changed files
git diff --staged                   # Review changes
bunx biome check --write .          # Format and lint
bun test                            # Run all tests
bun run build                       # Verify production build
git commit -m "feat: add currency formatting utility"
```

### Preventing Regressions

#### Regression Test Pattern

When fixing a bug:
1. Write a test that reproduces the bug (test should fail)
2. Fix the bug
3. Verify the test now passes
4. Commit both the fix and the test together

```typescript
// Bug Report: formatCurrency crashes with very large numbers
describe('Regression: Large number handling', () => {
  it('should handle numbers larger than safe integer', () => {
    // This test would have failed before the fix
    const largeAmount = 9007199254740991; // Number.MAX_SAFE_INTEGER
    expect(() => formatCurrency(largeAmount)).not.toThrow();
  });
});
```

#### Continuous Validation

- Run tests in CI/CD pipeline on every commit
- Block merges if tests fail
- Monitor test execution time (keep tests fast)
- Review test coverage trends (aim for 80%+ on critical code)

### Testing Anti-Patterns to Avoid

**DON'T:**
- Write tests that depend on execution order
- Test multiple unrelated things in one test
- Use real external services (use mocks instead)
- Ignore flaky tests (fix or remove them)
- Test framework internals (trust React, Astro, etc.)
- Copy-paste tests without understanding them
- Leave failing tests commented out

**DO:**
- Keep tests independent and isolated
- Use descriptive test names that explain intent
- Mock external dependencies consistently
- Write tests that are fast and deterministic
- Focus on public interfaces and behavior
- Refactor tests along with production code
- Delete obsolete tests

### Agent Testing Checklist

Before marking a task complete, verify:

- [ ] All new functions have unit tests
- [ ] All modified functions have updated tests
- [ ] Bug fixes include regression tests
- [ ] Critical business logic has comprehensive coverage
- [ ] Edge cases and error handling are tested
- [ ] Tests run successfully (`bun test`)
- [ ] Code is formatted and linted (`bunx biome check --write .`)
- [ ] Production build succeeds (`bun run build`)
- [ ] If UI changes: consider browser agent testing for key flows
- [ ] Test names clearly describe expected behavior
- [ ] No commented-out or skipped tests without explanation

### Resources and Commands

```bash
# Unit testing
bun test                              # Run all tests
bun test --watch                      # Watch mode
bun test file.test.ts                 # Single file
bun test --coverage                   # Coverage report

# Browser testing (if agent-browser available)
agent-browser launch                  # Start browser instance
agent-browser test e2e.test.ts        # Run browser tests

# Quality checks
bunx biome check --write .            # Format + lint
bun run build                         # Verify build

# Git workflow
git diff --staged                     # Review before commit
git commit -m "test: add tests for X" # Commit tests
```

### Testing Philosophy

> "Write tests that give you confidence. If a test doesn't help you catch bugs or understand behavior, it's not pulling its weight."

Focus on:
- **Confidence**: Tests should catch real bugs
- **Clarity**: Tests should document expected behavior
- **Speed**: Tests should run quickly
- **Maintainability**: Tests should evolve with the code

Remember: **You are responsible for the quality of the code you write. Tests are your primary tool for ensuring quality and preventing regressions. Treat them as first-class citizens alongside your production code.**

