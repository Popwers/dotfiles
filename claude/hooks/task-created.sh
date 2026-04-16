#!/usr/bin/env bash
# TaskCreated hook — validate task quality before creation.
# Exit 0 = allow creation, Exit 2 = block + send feedback.

INPUT=$(cat)

# Extract task details
TITLE=$(echo "$INPUT" | jq -r '.title // empty' 2>/dev/null)
DESCRIPTION=$(echo "$INPUT" | jq -r '.description // empty' 2>/dev/null)

# Check title length (should be descriptive)
if [ -n "$TITLE" ] && [ ${#TITLE} -lt 10 ]; then
    echo "Task title too short: '$TITLE'. Provide a more descriptive title (10+ chars)."
    exit 2
fi

# Check description exists for non-trivial tasks
if [ -z "$DESCRIPTION" ] || [ ${#DESCRIPTION} -lt 20 ]; then
    echo "Task needs a clearer description. Include:"
    echo "- What files/modules are involved"
    echo "- Expected outcome"
    echo "- Any constraints or dependencies"
    exit 2
fi

# Warn about vague descriptions
VAGUE_PATTERNS="fix it|do it|update|change|improve|refactor"
if echo "$DESCRIPTION" | grep -qiE "^($VAGUE_PATTERNS)$"; then
    echo "Task description is too vague: '$DESCRIPTION'. Be specific about what needs to change."
    exit 2
fi

exit 0
