#!/usr/bin/env bash
# PreToolUse/Bash — warn before committing multi-file changes without Codex review.
# Does NOT block (exit 0) — just nudges Claude to run /codex:review first.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

# Only trigger on git commit
echo "$COMMAND" | grep -qE 'git\s+commit' || exit 0

# Count staged files
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
[ "$STAGED" -lt 3 ] && exit 0

echo "[CodexGate] $STAGED files staged — consider delegating to the codex-reviewer agent or running /codex:review --background before committing." >&2
