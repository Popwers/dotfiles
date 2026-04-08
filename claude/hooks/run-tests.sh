#!/usr/bin/env bash
# Run tests related to the edited file after edit/write.
# PostToolUse/Edit|Write — detects test runner and runs targeted tests.
# Reports failures so Claude can auto-correct.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Only trigger for source/test files
if ! [[ "$FILE" =~ \.(ts|tsx|js|jsx)$ ]] || [ ! -f "$FILE" ]; then
    exit 0
fi

# Find project root (has package.json)
DIR=$(dirname "$FILE")
while [ "$DIR" != "/" ]; do
    if [ -f "$DIR/package.json" ]; then
        break
    fi
    DIR=$(dirname "$DIR")
done
[ ! -f "$DIR/package.json" ] && exit 0

cd "$DIR" || exit 0

# Determine test file path
BASENAME=$(basename "$FILE")

# If it's already a test file, run it directly
if [[ "$BASENAME" =~ \.test\.(ts|tsx|js|jsx)$ ]]; then
    TEST_FILE="$FILE"
# Try to find corresponding test file
else
    NAME="${BASENAME%.*}"
    EXT="${BASENAME##*.}"
    # Search in tests/ directory (mirroring src/)
    TEST_FILE=$(find "$DIR/tests" -name "${NAME}.test.${EXT}" -o -name "${NAME}.test.ts" 2>/dev/null | head -1)
fi

if [ -n "$TEST_FILE" ] && [ -f "$TEST_FILE" ]; then
    OUTPUT=$(bun test "$TEST_FILE" 2>&1)
    if [ $? -ne 0 ]; then
        FAILURES=$(echo "$OUTPUT" | grep -E "(FAIL|Error|✗|×)" | head -10)
        echo "[Tests] Failures in $(basename "$TEST_FILE"):" >&2
        echo "$FAILURES" >&2
    fi
fi
