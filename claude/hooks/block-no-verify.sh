#!/usr/bin/env bash
# Block --no-verify on git commits to preserve husky hooks pipeline.
# PreToolUse/Bash — exit 2 to block, stderr shown as reason.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

if echo "$COMMAND" | grep -qE 'git\s+(commit|push).*--no-verify|--no-verify.*git\s+(commit|push)'; then
    echo "Blocked: --no-verify bypasses husky hooks (tests, biome, commitlint). Remove the flag and fix the underlying issue." >&2
    exit 2
fi
