#!/usr/bin/env bash

set -euo pipefail

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || true)

if echo "$COMMAND" | grep -qE 'git\s+(commit|push).*--no-verify|--no-verify.*git\s+(commit|push)'; then
    echo 'Blocked: --no-verify bypasses repo validation hooks. Remove the flag and fix the underlying issue.' >&2
    exit 2
fi
