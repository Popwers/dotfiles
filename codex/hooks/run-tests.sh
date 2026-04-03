#!/usr/bin/env bash

set -euo pipefail

git_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

changed_source_files() {
    git status --porcelain 2>/dev/null | awk '
        $1 != "D" && $2 != "D" {
            path = substr($0, 4)
            sub(/^"/, "", path)
            sub(/"$/, "", path)
            print path
        }
    ' | grep -E '\.(ts|tsx|js|jsx)$' || true
}

main() {
    local root
    local changed
    local test_files=''
    local output
    local status

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf '%s\n' '{"status":"skipped","message":"Not inside a git repository."}'
        exit 0
    fi

    root=$(git_root)
    changed=$(changed_source_files)

    if [ -z "$changed" ]; then
        printf '%s\n' '{"status":"skipped","message":"No changed JS/TS files."}'
        exit 0
    fi

    if [ ! -f "$root/package.json" ]; then
        printf '%s\n' '{"status":"skipped","message":"No package.json found at repo root."}'
        exit 0
    fi

    while IFS= read -r file; do
        [ -n "$file" ] || continue
        if echo "$file" | grep -qE '\.(test|spec)\.(ts|tsx|js|jsx)$'; then
            test_files="$test_files $file"
            continue
        fi

        base=$(basename "$file")
        name=${base%.*}
        match=$(find "$root/tests" -type f \( -name "$name.test.ts" -o -name "$name.test.tsx" -o -name "$name.test.js" -o -name "$name.test.jsx" -o -name "$name.spec.ts" -o -name "$name.spec.tsx" -o -name "$name.spec.js" -o -name "$name.spec.jsx" \) 2>/dev/null | head -1 || true)
        if [ -n "$match" ]; then
            rel=${match#"$root"/}
            test_files="$test_files $rel"
        fi
    done <<< "$changed"

    test_files=$(printf '%s\n' "$test_files" | xargs -n1 2>/dev/null | awk '!seen[$0]++' | xargs 2>/dev/null || true)

    if [ -z "$test_files" ]; then
        printf '%s\n' '{"status":"skipped","message":"No targeted tests found."}'
        exit 0
    fi

    status=0
    output=$(cd "$root" && bun test $test_files 2>&1) || status=$?

    if [ "$status" -ne 0 ]; then
        python3 - "$output" <<'PY'
import json
import re
import sys

lines = [line for line in sys.argv[1].splitlines() if re.search(r'(FAIL|Error|error|✗|×)', line)][:10]
if not lines:
    lines = sys.argv[1].splitlines()[:10]
print(json.dumps({
    "status": "failed",
    "message": "[Tests] " + "\n".join(lines)
}))
PY
        exit 0
    fi

    printf '%s\n' '{"status":"passed","message":"Targeted tests passed."}'
}

main "$@"
