---
description: Testing policy, TDD workflow, and coverage requirements
globs: "*.ts,*.tsx,*.js,*.jsx,*.astro,*.vue,*.svelte,*.py,*.go,*.rs,*.rb,*.java,*.kt,*.swift,*.php,*.test.ts,*.test.tsx,*.spec.ts,*.spec.tsx,*_test.go,*_test.py,*.test.js,*.spec.js"
---

# Testing Policy

## Coverage

Target 80% minimum on changed code. Prioritize behavior coverage over line coverage.

## TDD Workflow

1. Write test first (RED — test fails)
2. Implement minimal code (GREEN — test passes)
3. Refactor for quality (IMPROVE — tests still pass)
4. Verify coverage meets target

## What to Test

- Always: critical logic, public APIs, error handling, changed branches
- Consider: complex calculations, integration points, state management, edge cases
- Skip: trivial one-liners, third-party internals, pure config, styling-only

## Test Organization

- All tests in root `tests/` directory, mirroring `src/` structure
- Use `.test.ts` / `.test.tsx`
- Arrange → Act → Assert; one behavior per test; `describe` for related cases

## Regression Pattern

1. Write failing test that reproduces the bug
2. Fix the implementation
3. Verify test passes
4. Commit fix + test together

## Core Principle

When tests fail: **fix the implementation, not the tests** — unless the tests themselves are wrong. Investigate root cause before changing assertions.

## Validation

- `bun test` passes
- `bunx biome check .` passes
- `bun run build` passes (when applicable)
