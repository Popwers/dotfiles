#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$repo_root" ]; then
    printf '%s\n' '{"status":"skipped","message":"Not inside a git repository."}'
    exit 0
fi

has_vp_project=0
if [ -f "$repo_root/vite.config.ts" ] || [ -f "$repo_root/vite.config.js" ] \
    || [ -f "$repo_root/vite.config.mts" ] || [ -f "$repo_root/vite.config.mjs" ] \
    || [ -f "$repo_root/vite.config.cjs" ]; then
    has_vp_project=1
fi

modified=()
while IFS= read -r -d '' rel; do
    case "$rel" in
        *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
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
    if [ "$has_vp_project" -eq 1 ] && command -v vp >/dev/null 2>&1; then
        output_cmd=(vp test run "$file")
    else
        output_cmd=(bun test "$file")
    fi
    if ! output=$(cd "$repo_root" && "${output_cmd[@]}" 2>&1); then
        failures=$(printf '%s\n' "$output" | grep -E "(FAIL|Error|✗|×)" | head -5)
        if [ -n "$failures" ]; then
            printf -v issues '%s[Tests] Failures in %s:\n%s\n\n' "$issues" "$(basename "$file")" "$failures"
        fi
    fi
done

if [ "$has_vp_project" -eq 1 ] && command -v vp >/dev/null 2>&1; then
    # Strip ANSI escapes, then keep only lines that look like an actual issue label
    # (`error:`, `warn:`, `warning:`) — not the `pass: Found no warnings or lint errors`
    # success line, which previously triggered a false positive on the substring match.
    lint_output=$( (cd "$repo_root" && vp check --no-error-on-unmatched-pattern "${modified[@]}") 2>&1 \
        | sed -E 's/\x1b\[[0-9;]*m//g' \
        | grep -E "^(error|warn(ing)?):" | head -5 || true)
    if [ -n "$lint_output" ]; then
        printf -v issues '%s[vp check] Fix before completing:\n%s\n\n' "$issues" "$lint_output"
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
