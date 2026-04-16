#!/usr/bin/env bash
# TeammateIdle hook — check before a teammate goes idle.
# Exit 0 = allow idle, Exit 2 = send feedback + keep working.

# Check for uncommitted changes in tracked files
UNCOMMITTED=$(git status --porcelain 2>/dev/null | grep -E '^[MADRCU ]' | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    echo "You have $UNCOMMITTED uncommitted changes. Consider committing or stashing before going idle."
    exit 2
fi

# Check for failing tests in modified files
MODIFIED_TESTS=$(git status --porcelain 2>/dev/null | grep -E '\.test\.(ts|tsx|js|jsx)$' | sed 's/^...//')
if [ -n "$MODIFIED_TESTS" ]; then
    for TEST_FILE in $MODIFIED_TESTS; do
        if [ -f "$TEST_FILE" ] && command -v bun &>/dev/null; then
            if ! bun test "$TEST_FILE" --bail 2>/dev/null; then
                echo "Test file $TEST_FILE is failing. Fix before going idle."
                exit 2
            fi
        fi
    done
fi

exit 0
