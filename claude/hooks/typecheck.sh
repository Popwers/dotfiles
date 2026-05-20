#!/usr/bin/env bash
# TypeScript check after edit on .ts/.tsx files via Vite+ (`vp check --no-fmt --no-lint`).
# PostToolUse/Edit|Write — runs typecheck, reports errors so Claude can fix them.
# Falls back to `bunx tsc --noEmit` when the project isn't on Vite+ yet.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [[ "$FILE" =~ \.(ts|tsx)$ ]] && [ -f "$FILE" ]; then
    DIR=$(dirname "$FILE")
    while [ "$DIR" != "/" ]; do
        if [ -f "$DIR/tsconfig.json" ]; then
            if [ -f "$DIR/vite.config.ts" ] || [ -f "$DIR/vite.config.js" ] \
                || [ -f "$DIR/vite.config.mjs" ] || [ -f "$DIR/vite.config.cjs" ]; then
                ERRORS=$(cd "$DIR" && vp check --no-fmt --no-lint --no-error-on-unmatched-pattern 2>&1 \
                    | grep -E "error TS" | head -10)
            else
                ERRORS=$(cd "$DIR" && bunx tsc --noEmit --pretty false 2>&1 | grep -E "error TS" | head -10)
            fi
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
