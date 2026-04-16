#!/usr/bin/env bash
# TaskCompleted hook — verify quality before marking a task as done.
# Exit 0 = allow completion, Exit 2 = block + send feedback.

# Get modified files (staged + unstaged)
MODIFIED=$(git status --porcelain 2>/dev/null | grep -E '^\s*[MADRCU?]' | sed 's/^...//' | grep -E '\.(ts|tsx|js|jsx)$')

if [ -z "$MODIFIED" ]; then
    exit 0
fi

ISSUES=""

# Check for console.log
CONSOLE_LOGS=$(echo "$MODIFIED" | xargs grep -l 'console\.log' 2>/dev/null \
    | xargs grep -n 'console\.log' 2>/dev/null \
    | grep -v '//.*console\.log' \
    | grep -v '/\*.*console\.log.*\*/' \
    | head -5)
if [ -n "$CONSOLE_LOGS" ]; then
    ISSUES="${ISSUES}[ConsoleLog] Remove console.log before completing:\n${CONSOLE_LOGS}\n\n"
fi

# Find project root
DIR=$(pwd)
while [ "$DIR" != "/" ]; do
    if [ -f "$DIR/package.json" ]; then
        break
    fi
    DIR=$(dirname "$DIR")
done

# Run tests if in a project
if [ -f "$DIR/package.json" ]; then
    cd "$DIR" || exit 0

    # Check if bun test exists and run it on modified test files
    TEST_FILES=$(echo "$MODIFIED" | grep -E '\.test\.(ts|tsx|js|jsx)$')
    if [ -n "$TEST_FILES" ]; then
        for TEST_FILE in $TEST_FILES; do
            if [ -f "$TEST_FILE" ]; then
                OUTPUT=$(bun test "$TEST_FILE" 2>&1)
                if [ $? -ne 0 ]; then
                    FAILURES=$(echo "$OUTPUT" | grep -E "(FAIL|Error|✗|×)" | head -5)
                    ISSUES="${ISSUES}[Tests] Failures in $(basename "$TEST_FILE"):\n${FAILURES}\n\n"
                fi
            fi
        done
    fi

    # Quick lint check on modified files
    if command -v biome &>/dev/null; then
        LINT_OUTPUT=$(echo "$MODIFIED" | xargs biome check 2>&1 | grep -E "(error|warning)" | head -5)
        if [ -n "$LINT_OUTPUT" ]; then
            ISSUES="${ISSUES}[Lint] Fix before completing:\n${LINT_OUTPUT}\n\n"
        fi
    fi
fi

if [ -n "$ISSUES" ]; then
    echo -e "Task completion blocked. Fix these issues first:\n"
    echo -e "$ISSUES"
    exit 2
fi

exit 0
