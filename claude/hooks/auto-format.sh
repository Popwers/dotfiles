#!/usr/bin/env bash
# Auto lint + format + fix with Biome after edit/write on JS/TS files.
# PostToolUse/Edit|Write — runs biome check --write (lint + format + auto-fix).
# Errors are reported to stderr so Claude can auto-correct.

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [[ "$FILE" =~ \.(ts|tsx|js|jsx|json|css)$ ]] && [ -f "$FILE" ]; then
    DIR=$(dirname "$FILE")
    while [ "$DIR" != "/" ]; do
        if [ -f "$DIR/biome.json" ] || [ -f "$DIR/biome.jsonc" ]; then
            OUTPUT=$(cd "$DIR" && bunx @biomejs/biome check --write "$FILE" --no-errors-on-unmatched 2>&1)
            EXIT=$?
            if [ "$EXIT" -ne 0 ]; then
                echo "[Biome] Errors remain in $(basename "$FILE"):" >&2
                echo "$OUTPUT" | tail -5 >&2
            fi
            break
        fi
        DIR=$(dirname "$DIR")
    done
fi
