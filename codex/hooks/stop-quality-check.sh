#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$repo_root" ]; then
    printf '%s\n' '{"status":"skipped","message":"Not inside a git repository."}'
    exit 0
fi

modified=()
while IFS= read -r -d '' rel; do
    case "$rel" in
        *.ts|*.tsx|*.js|*.jsx)
            abs="$repo_root/$rel"
            [ -f "$abs" ] && modified+=("$abs")
            ;;
    esac
done < <(
    git -C "$repo_root" diff --name-only -z HEAD 2>/dev/null
    git -C "$repo_root" ls-files --others --exclude-standard -z 2>/dev/null
)

if [ ${#modified[@]} -eq 0 ]; then
    printf '%s\n' '{"status":"skipped","message":"No modified JS/TS files."}'
    exit 0
fi

issues=''

for file in "${modified[@]}"; do
    [[ "$file" =~ \.test\.(ts|tsx|js|jsx)$ ]] || continue
    if ! output=$(cd "$repo_root" && bun test "$file" 2>&1); then
        failures=$(printf '%s\n' "$output" | grep -E "(FAIL|Error|✗|×)" | head -5)
        if [ -n "$failures" ]; then
            printf -v issues '%s[Tests] Failures in %s:\n%s\n\n' "$issues" "$(basename "$file")" "$failures"
        fi
    fi
done

if command -v bunx >/dev/null 2>&1; then
    lint_output=$( (cd "$repo_root" && bunx @biomejs/biome check "${modified[@]}" --no-errors-on-unmatched) 2>&1 \
        | grep -E "(error|warning)" | head -5 || true)
    if [ -n "$lint_output" ]; then
        printf -v issues '%s[Lint] Fix before completing:\n%s\n\n' "$issues" "$lint_output"
    fi
fi

as_any=$(grep -nE '\bas[[:space:]]+any\b' "${modified[@]}" 2>/dev/null | head -10 || true)
if [ -n "$as_any" ]; then
    printf -v issues '%s[Types] Replace `as any` with a type guard or typed helper:\n%s\n\n' "$issues" "$as_any"
fi

if [ -n "$issues" ]; then
    python3 - "$issues" <<'PY'
import json
import sys

print(json.dumps({
    "status": "failed",
    "message": "Task quality issues:\n\n" + sys.argv[1]
}))
PY
    exit 0
fi

printf '%s\n' '{"status":"passed","message":"Stop quality check passed."}'
