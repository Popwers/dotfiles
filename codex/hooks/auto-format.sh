#!/usr/bin/env bash

set -euo pipefail

git_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

find_vite_root() {
    local dir=$1

    while [ "$dir" != "/" ]; do
        if [ -f "$dir/vite.config.ts" ] || [ -f "$dir/vite.config.js" ] \
            || [ -f "$dir/vite.config.mts" ] || [ -f "$dir/vite.config.mjs" ] \
            || [ -f "$dir/vite.config.cjs" ]; then
            printf '%s\n' "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done

    return 1
}

changed_files() {
    # Only format staged files (index changes), not all dirty files.
    # This prevents reformatting unrelated local work the agent never touched.
    git diff --cached --name-only --diff-filter=d 2>/dev/null
    # Also include files just written but not yet staged (common in Codex flow).
    git diff --name-only --diff-filter=d 2>/dev/null
}

file_hashes() {
    local root=$1
    local files=$2
    local file

    while IFS= read -r file; do
        [ -n "$file" ] || continue
        [ -f "$root/$file" ] || continue
        printf '%s:%s\n' "$file" "$(git hash-object "$root/$file")"
    done <<< "$files"
}

main() {
    local root
    local vite_root
    local before
    local after
    local candidates

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf '%s\n' '{"status":"skipped","message":"Not inside a git repository."}'
        exit 0
    fi

    root=$(git_root)
    vite_root=$(find_vite_root "$root" || true)

    if [ -z "$vite_root" ]; then
        printf '%s\n' '{"status":"skipped","message":"No vite.config.* found."}'
        exit 0
    fi

    candidates=$(changed_files | sort -u | grep -E '\.(ts|tsx|js|jsx|mjs|cjs|json|css)$' || true)

    if [ -z "$candidates" ]; then
        printf '%s\n' '{"status":"skipped","message":"No formatable changed files."}'
        exit 0
    fi

    before=$(file_hashes "$root" "$candidates")

    while IFS= read -r file; do
        [ -f "$root/$file" ] || continue
        (cd "$vite_root" && vp check --fix --no-error-on-unmatched-pattern "$root/$file" >/dev/null 2>&1) || true
    done <<< "$candidates"

    after=$(file_hashes "$root" "$candidates")

    if [ "$before" != "$after" ]; then
        python3 - <<'PY'
import json
print(json.dumps({
    "status": "changed",
    "message": "vp check --fix rewrote one or more changed files."
}))
PY
        exit 0
    fi

    printf '%s\n' '{"status":"passed","message":"No formatting changes were needed."}'
}

main "$@"
