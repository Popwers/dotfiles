# AGENTS.md

## Commands

```bash
# Search/Find (REQUIRED - never use grep/find)
rg "pattern" --type ts                    # Search file contents
rg "function.*fetch" -g "*.ts"            # Search with glob filter
fd "*.tsx" src/                           # Find files by pattern
fd -e ts -e tsx                           # Find by extensions

# Development
bun run dev                               # Start dev server
bun run build                             # Production build
bun run test                              # Run Bun tests
bun run lint                              # Biome lint
bun run format                            # Biome format

# Git
git status && git diff --staged           # Review before commit
git log --oneline -10                     # Recent commits
git commit -m "type: description"         # Commit format
```

## Stack

| Layer | Technologies |
|-------|-------------|
| **Frontend** | Astro, React, TypeScript |
| **UI** | Tailwind CSS, shadcn/ui, Base UI |
| **Animation** | Motion (motion.dev) |
| **Runtime** | Node.js, Bun |
| **Build** | Vite |
| **Test** | Bun test |
| **Format** | Biome |
| **Database** | SQL |

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
interface User {
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

interface ApiResponse<T> {
  data: T;
  status: number;
  message?: string;
}

// 2. Let TypeScript infer types - don't over-annotate
const fetchUser = async (id: string) => {
  if (!id) return null;

  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error(`Failed: ${res.status}`);

  return res.json();
};

// 3. Type only when necessary (params, exports, complex returns)
const users = await fetchApi<User[]>({ endpoint: 'users' });
const filteredUsers = users.filter(u => u.isActive);  // inferred

// 4. Maps over enums
const Status = {
  Active: 'active',
  Inactive: 'inactive',
} as const;

type Status = (typeof Status)[keyof typeof Status];

// 5. Functional patterns - no classes
const createService = (baseUrl: string) => ({
  get: (id: string) => fetch(`${baseUrl}/${id}`),
  create: (data: User) => fetch(baseUrl, {
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

// 7. Descriptive names with auxiliary verbs
const isLoading = true;
const hasPermission = false;
const canEdit = true;
const shouldRefetch = false;
```

### Astro

```astro
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

### React Components

```tsx
import { useState, useCallback } from 'react';
import { Button } from '@/components/ui/Button';
import type { User } from '@interfaces/user';

interface UserCardProps {
  user: User;
  onEdit?: (user: User) => void;
  isEditable?: boolean;
}

const UserCard = ({ user, onEdit, isEditable = false }: UserCardProps) => {
  const [isLoading, setIsLoading] = useState(false);

  const handleEdit = useCallback(async () => {
    if (!onEdit) return;

    setIsLoading(true);
    try {
      await onEdit(user);
    } finally {
      setIsLoading(false);
    }
  }, [user, onEdit]);

  return (
    <div className="p-4 rounded-lg border bg-card">
      <h3 className="text-lg font-semibold">{user.username}</h3>
      <p className="text-muted-foreground">{user.email}</p>

      {isEditable && (
        <Button onClick={handleEdit} disabled={isLoading} variant="outline" size="sm">
          {isLoading ? 'Saving...' : 'Edit'}
        </Button>
      )}
    </div>
  );
};

export default UserCard;
```

### Motion (Animation)

```tsx
import { motion, AnimatePresence } from 'motion/react';
import { useState } from 'react';

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
const ExpandableCard = () => {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <motion.div
      layout
      onClick={() => setIsExpanded(!isExpanded)}
      className="p-4 rounded-lg bg-card cursor-pointer"
    >
      <motion.h3 layout="position">Title</motion.h3>
      {isExpanded && (
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          Expanded content here
        </motion.p>
      )}
    </motion.div>
  );
};

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
bun run test                              # All tests
bun run test --watch                      # Watch mode
bun run test user.test.ts                 # Single file
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
git fetch origin main
git rebase origin/main
bun run lint
bun run test
bun run build

# Create PR
gh pr create --title "feat: description" --body "Description"
```

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
- Use `grep` or `find` commands (use `rg` and `fd`)
- Use classes in JavaScript (functional patterns only)
- Over-type when TypeScript can infer
- Use `I` prefix for interfaces (use `User` not `IUser`)
- Write obvious comments that repeat the code
- Over-abstract or over-engineer solutions
- Leave dead code or unused imports

**Testing:**
- Skip tests for critical business logic
- Test implementation details instead of behavior
- Leave `console.log` in production code

### ALWAYS

**Code Standards:**
- Write all code, comments, and commits in English
- Use interfaces over types in TypeScript (without `I` prefix)
- Let TypeScript infer types when possible
- Use `const` over `let`, never `var`
- Use early returns over nested conditionals
- Use descriptive names with auxiliary verbs (`isLoading`, `hasError`)
- Handle errors explicitly, fail fast

**Architecture:**
- Follow mobile-first responsive design
- Use semantic HTML with proper ARIA attributes
- Keep components small and focused
- Extract reusable logic into custom hooks/utilities

**Before Committing:**
- Run `bun run lint` and fix all issues
- Run `bun run test` and ensure all pass
- Run `bun run build` to verify production build
- Review diff with `git diff --staged`

**Performance:**
- Prefer static generation over client-side rendering
- Use proper Astro hydration directives (`server:defer`, `client:visible`)
- Lazy load images and non-critical components
