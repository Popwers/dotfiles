#!/usr/bin/env bash
# Strategic Compact Suggester
# Runs on PreToolUse (Edit/Write) to suggest manual compaction at logical intervals.
#
# Why manual over auto-compact:
# - Auto-compact happens at arbitrary points, often mid-task
# - Strategic compacting preserves context through logical phases
# - Compact after exploration, before execution
# - Compact after completing a milestone, before starting next

COUNTER_FILE="/tmp/claude-tool-count-${CLAUDE_SESSION_ID:-$$}"
THRESHOLD=${COMPACT_THRESHOLD:-50}

if [ -f "$COUNTER_FILE" ]; then
    count=$(cat "$COUNTER_FILE")
    count=$((count + 1))
    echo "$count" > "$COUNTER_FILE"
else
    echo "1" > "$COUNTER_FILE"
    count=1
fi

if [ "$count" -eq "$THRESHOLD" ]; then
    echo "[StrategicCompact] $THRESHOLD tool calls reached — consider /compact if transitioning phases" >&2
fi
