#!/usr/bin/env bash
# Stop hook — verify quality before ending the turn.
# Exit 0 = allow stop, Exit 2 = block stop + send feedback so Claude fixes issues.

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && exit 0

# Collect modified/new JS/TS files as absolute paths (NUL-delimited, space-safe).
MODIFIED=()
while IFS= read -r -d '' rel; do
    case "$rel" in
        *.ts|*.tsx|*.js|*.jsx)
            abs="$REPO_ROOT/$rel"
            [ -f "$abs" ] && MODIFIED+=("$abs")
            ;;
    esac
done < <(
    git -C "$REPO_ROOT" diff --name-only -z HEAD 2>/dev/null
    git -C "$REPO_ROOT" ls-files --others --exclude-standard -z 2>/dev/null
)

[ ${#MODIFIED[@]} -eq 0 ] && exit 0

ISSUES=""

# console.log check (skip line and block comments, including multi-line blocks).
for f in "${MODIFIED[@]}"; do
    matches=$(awk '
        BEGIN { in_block = 0 }
        {
            line = $0
            gsub(/\/\*.*\*\//, "", line)
            if (in_block) {
                if (match(line, /\*\//)) {
                    line = substr(line, RSTART + RLENGTH)
                    in_block = 0
                } else { next }
            }
            if (match(line, /\/\*/)) {
                line = substr(line, 1, RSTART - 1)
                in_block = 1
            }
            if (match(line, /\/\//)) {
                line = substr(line, 1, RSTART - 1)
            }
            if (line ~ /console\.log/) print NR ": " $0
        }
    ' "$f" 2>/dev/null | head -5)
    if [ -n "$matches" ]; then
        ISSUES+="[ConsoleLog] Remove before completing: $f\n${matches}\n\n"
    fi
done

# Run tests on modified test files.
for f in "${MODIFIED[@]}"; do
    [[ "$f" =~ \.test\.(ts|tsx|js|jsx)$ ]] || continue
    if ! output=$(cd "$REPO_ROOT" && bun test "$f" 2>&1); then
        failures=$(echo "$output" | grep -E "(FAIL|Error|✗|×)" | head -5)
        ISSUES+="[Tests] Failures in $(basename "$f"):\n${failures}\n\n"
    fi
done

# Biome lint check on all modified files.
if command -v biome &>/dev/null; then
    lint_output=$( (cd "$REPO_ROOT" && biome check "${MODIFIED[@]}") 2>&1 \
        | grep -E "(error|warning)" | head -5)
    if [ -n "$lint_output" ]; then
        ISSUES+="[Lint] Fix before completing:\n${lint_output}\n\n"
    fi
fi

if [ -n "$ISSUES" ]; then
    echo -e "Task completion blocked. Fix these issues first:\n"
    echo -e "$ISSUES"
    exit 2
fi

exit 0
