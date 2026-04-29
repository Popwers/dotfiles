#!/usr/bin/env bash

set -euo pipefail

changed_frontend_files() {
    git status --porcelain 2>/dev/null | awk '
        $1 != "D" && $2 != "D" {
            path = substr($0, 4)
            sub(/^"/, "", path)
            sub(/"$/, "", path)
            print path
        }
    ' | grep -E '\.(html|css|jsx|tsx|vue|svelte|astro)$' || true
}

main() {
    local changed
    local output=''
    local file
    local result

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf '%s\n' '{"status":"skipped","message":"Not inside a git repository."}'
        exit 0
    fi

    if ! command -v impeccable >/dev/null 2>&1; then
        printf '%s\n' '{"status":"skipped","message":"impeccable is not installed."}'
        exit 0
    fi

    changed=$(changed_frontend_files)
    if [ -z "$changed" ]; then
        printf '%s\n' '{"status":"skipped","message":"No changed frontend files."}'
        exit 0
    fi

    while IFS= read -r file; do
        [ -n "$file" ] || continue
        [ -f "$file" ] || continue
        result=$(impeccable detect "$file" 2>&1 || true)
        if [ -n "$result" ]; then
            output="${output}[Impeccable] ${file}:\n${result}\n\n"
        fi
    done <<< "$changed"

    if [ -n "$output" ]; then
        python3 - "$output" <<'PY'
import json
import sys

print(json.dumps({
    "status": "failed",
    "message": sys.argv[1]
}))
PY
        exit 0
    fi

    printf '%s\n' '{"status":"passed","message":"No UI anti-patterns found by impeccable."}'
}

main "$@"
