#!/usr/bin/env bash
# SessionStart hook: ensures .claudeignore exists and contains all template patterns.
# - No .claudeignore? Creates one from template.
# - Existing .claudeignore? Merges missing lines (preserves custom entries).
TEMPLATE="$HOME/.claude/claudeignore.template"
TARGET=".claudeignore"

[ ! -f "$TEMPLATE" ] && exit 0

if [ ! -f "$TARGET" ]; then
    cp "$TEMPLATE" "$TARGET"
    exit 0
fi

# Merge: append lines from template that are not already present
while IFS= read -r line; do
    [ -z "$line" ] && continue
    [[ "$line" == \#* ]] && continue
    grep -qxF "$line" "$TARGET" || echo "$line" >> "$TARGET"
done < "$TEMPLATE"
