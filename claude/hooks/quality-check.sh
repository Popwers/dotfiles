#!/usr/bin/env bash
# PostToolUse/Edit|Write — unified quality check after edit on JS/TS/JSON/CSS:
#   1. `vp check --fix` on the edited file  → fmt + lint + auto-fix
#   2. `vp check --no-fmt --no-lint`        → global TS typecheck (catches downstream breakage)
# Errors surfaced to stderr so Claude can auto-correct.
# Falls back to `bunx tsc --noEmit` when the project isn't on Vite+ yet.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

[[ "$FILE" =~ \.(ts|tsx|js|jsx|mjs|cjs|json|css)$ ]] || exit 0
[ -f "$FILE" ] || exit 0

# Walk up to find Vite+ root
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

# Step 1 — fmt + lint + auto-fix on the edited file (Vite+ only)
if [ -n "$VITE_ROOT" ] && command -v vp >/dev/null 2>&1; then
    OUTPUT=$(cd "$VITE_ROOT" && vp check --fix --no-error-on-unmatched-pattern "$FILE" 2>&1)
    if [ $? -ne 0 ]; then
        echo "[vp check] Errors remain in $(basename "$FILE"):" >&2
        echo "$OUTPUT" | tail -5 >&2
    fi
fi

# Step 2 — global TS typecheck (only for .ts/.tsx)
if [[ "$FILE" =~ \.(ts|tsx)$ ]]; then
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
fi

exit 0
