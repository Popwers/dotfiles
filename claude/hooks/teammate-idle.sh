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
    for TEST_FILE in $MODIFIED_TESTS; do
        if [ -f "$TEST_FILE" ] && command -v bun &>/dev/null; then
            if ! bun test "$TEST_FILE" --bail 2>/dev/null; then
                echo "Note: test file $TEST_FILE is failing."
            fi
        fi
    done
fi

exit 0
