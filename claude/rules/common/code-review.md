---
description: Severity classification and review decision rules for review-auditor
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
