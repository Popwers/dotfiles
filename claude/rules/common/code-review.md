---
description: Severity classification, review decision rules, and self-review techniques
globs: "**"
---

# Code Review Severity

| Level | Definition | Action |
|-------|-----------|--------|
| CRITICAL | Security vulnerability, data loss risk | Block — fix before merge |
| HIGH | Bug or significant quality issue | Warn — fix recommended before merge |
| MEDIUM | Maintainability concern | Info — address when practical |
| LOW | Style or minor suggestion | Note — optional |

## Approval Decision

- **Approve**: zero CRITICAL or HIGH issues
- **Conditional**: HIGH issues only, merge with documented risk
- **Block**: any CRITICAL issue present

## Auto-Escalate to security-reviewer

When code touches: auth/authorization, user input handling, database queries, file system operations, payment processing, cryptographic operations.

## Two-Perspective Review

When evaluating your own work, present two opposing views: what a perfectionist would criticize and what a pragmatist would accept. Let the user decide which tradeoff to take.

## Fresh Eyes Pass

When asked to test your own output, adopt a new-user persona. Walk through the feature as if you've never seen the project. Flag anything confusing, friction-heavy, or unclear.
