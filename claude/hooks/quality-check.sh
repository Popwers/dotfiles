#!/usr/bin/env bash
# PostToolUse/Edit|Write — fast single-file quality pass after edit on JS/TS/JSON/CSS:
#   `vp check --fix` on the edited file  → fmt + lint + auto-fix
# Errors surfaced to stderr so Claude can auto-correct.
# The global TS typecheck runs separately (async) in typecheck.sh to keep edits snappy.

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

# fmt + lint + auto-fix on the edited file (Vite+ only)
if [ -n "$VITE_ROOT" ] && command -v vp >/dev/null 2>&1; then
    OUTPUT=$(cd "$VITE_ROOT" && vp check --fix --no-error-on-unmatched-pattern "$FILE" 2>&1)
    if [ $? -ne 0 ]; then
        echo "[vp check] Errors remain in $(basename "$FILE"):" >&2
        echo "$OUTPUT" | tail -5 >&2
    fi
fi

exit 0
