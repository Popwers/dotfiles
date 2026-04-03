#!/usr/bin/env bash

set -euo pipefail

git_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

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

find_tsconfig_root() {
    local dir=$1

    while [ "$dir" != "/" ]; do
        if [ -f "$dir/tsconfig.json" ]; then
            printf '%s\n' "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done

    return 1
}

main() {
    local root
    local ts_root
    local changed
    local output

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf '%s\n' '{"status":"skipped","message":"Not inside a git repository."}'
        exit 0
    fi

    changed=$(changed_typescript_files)
    if [ -z "$changed" ]; then
        printf '%s\n' '{"status":"skipped","message":"No changed TypeScript files."}'
        exit 0
    fi

    root=$(git_root)
    ts_root=$(find_tsconfig_root "$root" || true)

    if [ -z "$ts_root" ]; then
        printf '%s\n' '{"status":"skipped","message":"No tsconfig.json found."}'
        exit 0
    fi

    output=$(cd "$ts_root" && bunx tsc --noEmit --pretty false 2>&1) || true

    if printf '%s' "$output" | grep -q 'error TS'; then
        python3 - "$output" <<'PY'
import json
import sys

lines = [line for line in sys.argv[1].splitlines() if 'error TS' in line][:10]
print(json.dumps({
    "status": "failed",
    "message": "[TypeCheck] " + "\n".join(lines)
}))
PY
        exit 0
    fi

    printf '%s\n' '{"status":"passed","message":"TypeScript check passed."}'
}

main "$@"
