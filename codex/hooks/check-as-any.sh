#!/usr/bin/env bash

set -euo pipefail

changed_typescript_files() {
    git status --porcelain 2>/dev/null | awk '
        $1 != "D" && $2 != "D" {
            path = substr($0, 4)
            sub(/^"/, "", path)
            sub(/"$/, "", path)
            print path
        }
    ' | grep -E '\.(ts|tsx)$' || true
}

main() {
    local -a files=()
    local line
    local found

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf '%s\n' '{"status":"skipped","message":"Not inside a git repository."}'
        exit 0
    fi

    while IFS= read -r line; do
        [ -n "$line" ] || continue
        files+=("$line")
    done < <(changed_typescript_files)

    if [ "${#files[@]}" -eq 0 ]; then
        printf '%s\n' '{"status":"skipped","message":"No changed TypeScript files."}'
        exit 0
    fi

    found=$(grep -nE '\bas[[:space:]]+any\b' "${files[@]}" 2>/dev/null | head -10 || true)

    if [ -n "$found" ]; then
        python3 - "$found" <<'PY'
import json
import sys

print(json.dumps({
    "status": "failed",
    "message": "[Types] `as any` found in changed files. Replace with a type guard or typed helper:\n" + sys.argv[1]
}))
PY
        exit 0
    fi

    printf '%s\n' '{"status":"passed","message":"No `as any` found in changed TypeScript files."}'
}

main "$@"
