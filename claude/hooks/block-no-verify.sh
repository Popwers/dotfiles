#!/usr/bin/env bash
# Block --no-verify on git commits/push to preserve husky hooks pipeline.
# PreToolUse/Bash — exit 2 to block, stderr shown as reason.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Strip -m/--message arguments (with their quoted value) to avoid false positives
# on commit messages like: git commit -m "removed --no-verify usage"
STRIPPED=$(echo "$COMMAND" | sed -E 's/(-m|--message)[[:space:]]+(("[^"]*")|('\''[^'\'']*'\'')|[^[:space:]]+)//g')

if echo "$STRIPPED" | grep -qE '^\s*git\s+.*\b(commit|push)\b.*--no-verify|^\s*git\s+.*--no-verify\b.*\b(commit|push)\b'; then
    echo "Blocked: --no-verify bypasses husky hooks (tests, biome, commitlint). Remove the flag and fix the underlying issue." >&2
    exit 2
fi
