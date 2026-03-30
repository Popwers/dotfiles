---
description: Git workflow, commit standards, and PR practices
globs: "**"
---

# Git Workflow

## Branches

`feature/`, `fix/`, `refactor/`, `test/`, `chore/`

## Commits

Conventional format: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `perf:`, `docs:`, `ci:`

Keep commits scoped and readable. Add a body when the "why" is not obvious from the subject line.

## Before Push

- Review staged diff (`git diff --staged`)
- Verify lint + tests pass
- Ensure branch is up to date with target branch

## Pull Requests

- Examine full commit history with `git diff base...HEAD`, not just the last commit
- Write a clear summary explaining the "why"
- Include a test plan

## Use `yeet` skill only when user explicitly asks for stage + commit + push + PR in one flow.
