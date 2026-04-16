#!/usr/bin/env bash
# TeammateIdle hook — check before a teammate goes idle.
# Exit 0 = allow idle, Exit 2 = send feedback + keep working.

INPUT=$(cat)

# Extract team name from input if available
TEAM_NAME=$(echo "$INPUT" | jq -r '.team_name // empty' 2>/dev/null)

# Check for uncommitted changes
UNCOMMITTED=$(git status --porcelain 2>/dev/null | grep -E '^\s*[MADRCU]' | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    echo "You have $UNCOMMITTED uncommitted changes. Consider committing or stashing before going idle."
    exit 2
fi

# Check task list if team name is available
if [ -n "$TEAM_NAME" ]; then
    TASK_DIR="$HOME/.claude/tasks/$TEAM_NAME"
    if [ -d "$TASK_DIR" ]; then
        # Count pending tasks
        PENDING=$(find "$TASK_DIR" -name "*.json" -exec grep -l '"status":\s*"pending"' {} \; 2>/dev/null | wc -l | tr -d ' ')
        if [ "$PENDING" -gt 0 ]; then
            echo "There are $PENDING pending tasks. Consider claiming one before going idle."
            exit 2
        fi
    fi
fi

exit 0
