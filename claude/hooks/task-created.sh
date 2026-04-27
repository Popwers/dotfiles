#!/usr/bin/env bash
# TaskCreated hook — validate task quality before creation.
# Exit 0 = allow, Exit 2 = block + send feedback to Claude.

INPUT=$(cat)

SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty' 2>/dev/null)
DESCRIPTION=$(echo "$INPUT" | jq -r '.task_description // empty' 2>/dev/null)

if [ -z "$SUBJECT" ]; then
    echo "Task subject is empty." >&2
    exit 2
fi

if [ -z "$DESCRIPTION" ]; then
    echo "Task needs a description (what files/outcome/constraints)." >&2
    exit 2
fi

exit 0
