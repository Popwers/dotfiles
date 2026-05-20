#!/usr/bin/env bash
# TeammateIdle hook — check before a teammate goes idle.
# Exit 0 = allow idle, Exit 2 = send feedback + keep working.

# Inform (no longer blocks) — surface state so the user sees it before idle.

# Check for uncommitted changes in tracked files
UNCOMMITTED=$(git status --porcelain 2>/dev/null | grep -E '^[MADRCU ]' | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    echo "Note: $UNCOMMITTED uncommitted changes."
fi

# Check for failing tests in modified files (warn, don't block)
MODIFIED_TESTS=$(git status --porcelain 2>/dev/null | grep -E '\.test\.(ts|tsx|js|jsx)$' | sed 's/^...//')
if [ -n "$MODIFIED_TESTS" ]; then
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
    HAS_VP=0
    if [ -n "$REPO_ROOT" ] && { [ -f "$REPO_ROOT/vite.config.ts" ] || [ -f "$REPO_ROOT/vite.config.js" ] \
        || [ -f "$REPO_ROOT/vite.config.mts" ] || [ -f "$REPO_ROOT/vite.config.mjs" ] \
        || [ -f "$REPO_ROOT/vite.config.cjs" ]; }; then
        HAS_VP=1
    fi
    for TEST_FILE in $MODIFIED_TESTS; do
        if [ ! -f "$TEST_FILE" ]; then
            continue
        fi
        if [ "$HAS_VP" -eq 1 ] && command -v vp &>/dev/null; then
            if ! vp test run "$TEST_FILE" --bail 1 2>/dev/null; then
                echo "Note: test file $TEST_FILE is failing."
            fi
        elif command -v bun &>/dev/null; then
            if ! bun test "$TEST_FILE" --bail 2>/dev/null; then
                echo "Note: test file $TEST_FILE is failing."
            fi
        fi
    done
fi

exit 0
