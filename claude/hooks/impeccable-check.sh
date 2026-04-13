#!/bin/bash
# Runs impeccable detect on frontend files to catch UI anti-patterns

# Check if impeccable is installed
command -v impeccable >/dev/null 2>&1 || exit 0

# Extract file path from hook input
file_path=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')
[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

# Run impeccable detect and capture output
output=$(impeccable detect "$file_path" 2>&1)
exit_code=$?

# If no issues found, exit silently
[ $exit_code -eq 0 ] && [ -z "$output" ] && exit 0

# Return issues as additional context for the model
if [ -n "$output" ]; then
	echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"impeccable detected UI anti-patterns in $file_path:\\n$output\"}}"
fi

exit 0
