#!/usr/bin/env bash

set -euo pipefail

git_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

find_biome_root() {
    local dir=$1

    while [ "$dir" != "/" ]; do
        if [ -f "$dir/biome.json" ] || [ -f "$dir/biome.jsonc" ]; then
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
    local biome_root
    local before
    local after
    local candidates

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf '%s\n' '{"status":"skipped","message":"Not inside a git repository."}'
        exit 0
    fi

    root=$(git_root)
    biome_root=$(find_biome_root "$root" || true)

    if [ -z "$biome_root" ]; then
        printf '%s\n' '{"status":"skipped","message":"No biome config found."}'
        exit 0
    fi

    candidates=$(changed_files | sort -u | grep -E '\.(ts|tsx|js|jsx|json|css)$' || true)

    if [ -z "$candidates" ]; then
        printf '%s\n' '{"status":"skipped","message":"No formatable changed files."}'
        exit 0
    fi

    before=$(file_hashes "$root" "$candidates")

    while IFS= read -r file; do
        [ -f "$root/$file" ] || continue
        (cd "$biome_root" && bunx @biomejs/biome check --write "$root/$file" --no-errors-on-unmatched >/dev/null 2>&1) || true
    done <<< "$candidates"

    after=$(file_hashes "$root" "$candidates")

    if [ "$before" != "$after" ]; then
        python3 - <<'PY'
import json
print(json.dumps({
    "status": "changed",
    "message": "Biome rewrote one or more changed files."
}))
PY
        exit 0
    fi

    printf '%s\n' '{"status":"passed","message":"No formatting changes were needed."}'
}

main "$@"
