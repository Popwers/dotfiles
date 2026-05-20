#!/usr/bin/env bash
# Stop hook — verify quality before ending the turn.
# Exit 0 = allow stop, Exit 2 = block stop + send feedback so Claude fixes issues.

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && exit 0

# Skip if the repo isn't a Vite+ project.
if ! { [ -f "$REPO_ROOT/vite.config.ts" ] || [ -f "$REPO_ROOT/vite.config.js" ] \
    || [ -f "$REPO_ROOT/vite.config.mjs" ] || [ -f "$REPO_ROOT/vite.config.cjs" ]; }; then
    exit 0
fi

# Collect modified/new JS/TS files as absolute paths (NUL-delimited, space-safe).
MODIFIED=()
while IFS= read -r -d '' rel; do
    case "$rel" in
        *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
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

# console.log detection is delegated to Oxlint via Vite+ config.
# Enable the relevant rule in `vite.config.*` to have the lint pass below flag it.

# Run tests on modified test files.
if command -v vp >/dev/null 2>&1; then
    for f in "${MODIFIED[@]}"; do
        [[ "$f" =~ \.test\.(ts|tsx|js|jsx)$ ]] || continue
        if ! output=$(cd "$REPO_ROOT" && vp test run "$f" 2>&1); then
            failures=$(echo "$output" | grep -E "(FAIL|Error|✗|×)" | head -5)
            ISSUES+="[Tests] Failures in $(basename "$f"):\n${failures}\n\n"
        fi
    done
fi

# Full quality gate on all modified files: fmt + lint + typecheck.
if command -v vp &>/dev/null; then
    lint_output=$( (cd "$REPO_ROOT" && vp check --no-error-on-unmatched-pattern "${MODIFIED[@]}") 2>&1 \
        | grep -E "(error|warning)" | head -5)
    if [ -n "$lint_output" ]; then
        ISSUES+="[vp check] Fix before completing:\n${lint_output}\n\n"
    fi
fi

if [ -n "$ISSUES" ]; then
    {
        echo -e "Task completion blocked. Fix these issues first:\n"
        echo -e "$ISSUES"
    } >&2
    exit 2
fi

exit 0
