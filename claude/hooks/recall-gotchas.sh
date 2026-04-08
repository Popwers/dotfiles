#!/usr/bin/env bash
# SessionStart hook: surface recent gotchas so past lessons inform the current session.
# Reads the memory gotchas.md file and prints the last entries to stderr.

GOTCHAS="$HOME/.claude/projects/-Users-lionel-Desktop-dotfiles/memory/gotchas.md"

# Also check a global gotchas file for cross-project lessons
GLOBAL_GOTCHAS="$HOME/.claude/memory/gotchas.md"

show_gotchas() {
    local file="$1"
    local label="$2"
    if [ -f "$file" ] && [ -s "$file" ]; then
        # Show last 10 non-empty, non-heading lines
        RECENT=$(grep -v '^#' "$file" | grep -v '^---' | grep -v '^\s*$' | tail -10)
        if [ -n "$RECENT" ]; then
            echo "[$label] Recent lessons to keep in mind:" >&2
            echo "$RECENT" >&2
        fi
    fi
}

show_gotchas "$GLOBAL_GOTCHAS" "Gotchas"
show_gotchas "$GOTCHAS" "Gotchas:project"
