#!/usr/bin/env bash
# PostToolUse/Edit|Write — block `as any` introduced in TS/TSX files.
# Exit 2 = block the edit and surface the reason so Claude rewrites with a typed helper.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

[[ "$FILE" =~ \.(ts|tsx)$ ]] || exit 0

PATTERN='\bas[[:space:]]+any\b'
MSG="[Types] \`as any\` introduced in $(basename "$FILE"). Replace with a type guard or a typed helper (see rules/code-quality.md)."

case "$TOOL" in
    Edit|MultiEdit)
        NEW=$(echo "$INPUT" | jq -r '[.tool_input.new_string, (.tool_input.edits // [] | map(.new_string) | join("\n"))] | join("\n")' 2>/dev/null)
        OLD=$(echo "$INPUT" | jq -r '[.tool_input.old_string, (.tool_input.edits // [] | map(.old_string) | join("\n"))] | join("\n")' 2>/dev/null)
        NEW_COUNT=$(printf '%s' "$NEW" | grep -cE "$PATTERN" || true)
        OLD_COUNT=$(printf '%s' "$OLD" | grep -cE "$PATTERN" || true)
        NEW_COUNT=${NEW_COUNT:-0}
        OLD_COUNT=${OLD_COUNT:-0}
        if [ "$NEW_COUNT" -gt "$OLD_COUNT" ]; then
            echo "$MSG" >&2
            exit 2
        fi
        ;;
    Write)
        CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null)
        if printf '%s' "$CONTENT" | grep -qE "$PATTERN"; then
            echo "$MSG" >&2
            exit 2
        fi
        ;;
esac

exit 0
