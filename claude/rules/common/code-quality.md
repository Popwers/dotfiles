---
description: Concrete code shape limits and immutability rules
globs: "*.ts,*.tsx,*.js,*.jsx"
---

# Code Quality Limits

## Size Guards

- Functions: target <50 lines, investigate if longer
- Files: target 200-400 lines, max 800 — split by feature/domain if exceeded
- Nesting: max 4 levels — use guard clauses and early returns to flatten

## Immutability

- Create new objects instead of mutating existing ones
- Use spread/destructuring for object updates, `.map`/`.filter` for arrays
- Exception: performance-critical hot paths where mutation is measurably faster

## Pre-Completion Checklist

- Clear, descriptive naming
- No hardcoded values outside config
- Error paths handled explicitly (no silent swallowing)
- No leftover debug code (console.log, debugger)
