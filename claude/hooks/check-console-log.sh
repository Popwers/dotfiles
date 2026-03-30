#!/usr/bin/env bash
# Scan modified files for leftover console.log statements.
# Stop hook — warns but does not block.

MODIFIED=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.(ts|tsx|js|jsx)$')
if [ -z "$MODIFIED" ]; then
    exit 0
fi

FOUND=$(echo "$MODIFIED" | xargs grep -n 'console\.log' 2>/dev/null | grep -v '//.*console\.log' | head -10)
if [ -n "$FOUND" ]; then
    echo "[ConsoleLog] Found console.log in modified files — remove before commit:" >&2
    echo "$FOUND" >&2
fi
