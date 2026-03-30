---
description: Security checks for code that handles user input, auth, or sensitive data
globs: "*.ts,*.tsx,*.js,*.jsx"
---

# Security Rules

## Before Commit

- No hardcoded secrets (API keys, passwords, tokens) in source code
- All user inputs validated and sanitized
- SQL queries use parameterized statements, never string concatenation
- HTML output sanitized to prevent XSS
- Auth/authorization verified on protected routes
- Error messages do not leak sensitive data (stack traces, internal paths)

## Secret Management

- Use environment variables or a secret manager
- Validate required secrets are present at startup
- Rotate any secrets that may have been exposed

## If Security Issue Found

1. Stop and use the **security-reviewer** agent
2. Fix CRITICAL issues before continuing
3. Rotate any exposed secrets
