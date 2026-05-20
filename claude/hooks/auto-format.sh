#!/usr/bin/env bash
# Auto lint + format + fix with Vite+ after edit/write on JS/TS files.
# PostToolUse/Edit|Write — runs `vp check --fix` (fmt + lint + auto-fix).
# Errors are reported to stderr so Claude can auto-correct.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [[ "$FILE" =~ \.(ts|tsx|js|jsx|mjs|cjs|json|css)$ ]] && [ -f "$FILE" ]; then
    DIR=$(dirname "$FILE")
    while [ "$DIR" != "/" ]; do
        if [ -f "$DIR/vite.config.ts" ] || [ -f "$DIR/vite.config.js" ] \
            || [ -f "$DIR/vite.config.mjs" ] || [ -f "$DIR/vite.config.cjs" ]; then
            OUTPUT=$(cd "$DIR" && vp check --fix --no-error-on-unmatched-pattern "$FILE" 2>&1)
            EXIT=$?
            if [ "$EXIT" -ne 0 ]; then
                echo "[vp check] Errors remain in $(basename "$FILE"):" >&2
                echo "$OUTPUT" | tail -5 >&2
            fi
            break
        fi
        DIR=$(dirname "$DIR")
    done
fi
