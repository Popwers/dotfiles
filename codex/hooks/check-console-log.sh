#!/usr/bin/env bash

set -euo pipefail

MODIFIED=$(git status --porcelain 2>/dev/null | awk '
    $1 != "D" && $2 != "D" {
        path = substr($0, 4)
        sub(/^"/, "", path)
        sub(/"$/, "", path)
        print path
    }
' | grep -E '\.(ts|tsx|js|jsx)$' || true)

if [ -z "$MODIFIED" ]; then
    printf '%s\n' '{"status":"passed","message":"No changed JS/TS files to scan."}'
    exit 0
fi

FOUND=$(printf '%s\n' "$MODIFIED" | xargs grep -n 'console\.log' 2>/dev/null | grep -v '//.*console\.log' | head -10 || true)

if [ -n "$FOUND" ]; then
    MESSAGE='[ConsoleLog] Found console.log in modified files; remove before commit:\n'"$FOUND"
    python3 - "$MESSAGE" <<'PY'
import json
import sys

print(json.dumps({
    "status": "failed",
    "message": sys.argv[1]
}))
PY
    exit 0
fi

printf '%s\n' '{"status":"passed","message":"No console.log found in changed files."}'
