#!/usr/bin/env bash
# TypeScript check after edit on .ts/.tsx files.
# PostToolUse/Edit|Write — runs tsc --noEmit, reports errors so Claude can fix them.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [[ "$FILE" =~ \.(ts|tsx)$ ]] && [ -f "$FILE" ]; then
    DIR=$(dirname "$FILE")
    while [ "$DIR" != "/" ]; do
        if [ -f "$DIR/tsconfig.json" ]; then
            ERRORS=$(cd "$DIR" && bunx tsc --noEmit --pretty false 2>&1 | grep -E "error TS" | head -10)
            if [ -n "$ERRORS" ]; then
                COUNT=$(echo "$ERRORS" | wc -l | tr -d ' ')
                echo "[TypeCheck] $COUNT error(s) — fix before commit:" >&2
                echo "$ERRORS" >&2
            fi
            break
        fi
        DIR=$(dirname "$DIR")
    done
fi
