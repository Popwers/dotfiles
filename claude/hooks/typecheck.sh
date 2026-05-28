#!/usr/bin/env bash
# PostToolUse/Edit|Write (async) — global TS typecheck after editing a .ts/.tsx file.
# Catches downstream breakage the single-file fmt/lint pass in quality-check.sh can't see.
# Runs async so it never blocks the edit flow; errors surface to stderr for auto-correction.
# Falls back to `bunx tsc --noEmit` when the project isn't on Vite+ yet.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

[[ "$FILE" =~ \.(ts|tsx)$ ]] || exit 0
[ -f "$FILE" ] || exit 0

# Walk up to find the Vite+ root (so we can prefer `vp` over a bare tsc).
DIR=$(dirname "$FILE")
VITE_ROOT=""
while [ "$DIR" != "/" ]; do
    if [ -f "$DIR/vite.config.ts" ] || [ -f "$DIR/vite.config.js" ] \
        || [ -f "$DIR/vite.config.mts" ] || [ -f "$DIR/vite.config.mjs" ] \
        || [ -f "$DIR/vite.config.cjs" ]; then
        VITE_ROOT="$DIR"
        break
    fi
    DIR=$(dirname "$DIR")
done

# Walk up to the nearest tsconfig and typecheck that project.
TS_DIR=$(dirname "$FILE")
while [ "$TS_DIR" != "/" ]; do
    if [ -f "$TS_DIR/tsconfig.json" ]; then
        if [ -n "$VITE_ROOT" ] && command -v vp >/dev/null 2>&1; then
            ERRORS=$(cd "$TS_DIR" && vp check --no-fmt --no-lint --no-error-on-unmatched-pattern 2>&1 \
                | grep -E "error TS" | head -10)
        else
            ERRORS=$(cd "$TS_DIR" && bunx tsc --noEmit --pretty false 2>&1 | grep -E "error TS" | head -10)
        fi
        if [ -n "$ERRORS" ]; then
            COUNT=$(echo "$ERRORS" | wc -l | tr -d ' ')
            echo "[TypeCheck] $COUNT error(s) — fix before commit:" >&2
            echo "$ERRORS" >&2
        fi
        break
    fi
    TS_DIR=$(dirname "$TS_DIR")
done

exit 0
