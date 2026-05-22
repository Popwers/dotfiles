#!/usr/bin/env bash
# Unified Vite+ quality check — run by post-turn-validate.sh.
#   1. `vp check --fix` on changed files       → fmt + lint + auto-fix
#   2. `vp check --no-fmt --no-lint` on project → global TS typecheck
# Returns JSON: {"status": "skipped|passed|changed|failed", "message": "..."}.
# Falls back to `bunx tsc --noEmit` when the project isn't on Vite+ yet.

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
    git diff --cached --name-only --diff-filter=d 2>/dev/null
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

emit() {
    local status=$1
    local message=$2

    python3 - "$status" "$message" <<'PY'
import json
import sys

print(json.dumps({"status": sys.argv[1], "message": sys.argv[2]}))
PY
}

main() {
    local root
    local vite_root
    local candidates
    local format_candidates
    local typecheck_candidates
    local before
    local after
    local ts_root
    local output
    local fmt_changed=0
    local typecheck_failed=0
    local messages=()

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        emit "skipped" "Not inside a git repository."
        exit 0
    fi

    root=$(git_root)
    vite_root=$(find_vite_root "$root" || true)
    candidates=$(changed_files | sort -u || true)

    if [ -z "$candidates" ]; then
        emit "skipped" "No changed files."
        exit 0
    fi

    # Step 1 — fmt + lint + auto-fix on changed files (Vite+ only)
    if [ -n "$vite_root" ]; then
        format_candidates=$(printf '%s\n' "$candidates" | grep -E '\.(ts|tsx|js|jsx|mjs|cjs|json|css)$' || true)
        if [ -n "$format_candidates" ]; then
            before=$(file_hashes "$root" "$format_candidates")
            while IFS= read -r file; do
                [ -f "$root/$file" ] || continue
                (cd "$vite_root" && vp check --fix --no-error-on-unmatched-pattern "$root/$file" >/dev/null 2>&1) || true
            done <<< "$format_candidates"
            after=$(file_hashes "$root" "$format_candidates")
            if [ "$before" != "$after" ]; then
                fmt_changed=1
                messages+=("vp check --fix rewrote one or more changed files.")
            fi
        fi
    fi

    # Step 2 — global TS typecheck if any .ts/.tsx changed
    typecheck_candidates=$(printf '%s\n' "$candidates" | grep -E '\.(ts|tsx)$' || true)
    if [ -n "$typecheck_candidates" ]; then
        ts_root=$(find_tsconfig_root "$root" || true)
        if [ -n "$ts_root" ]; then
            if [ -n "$vite_root" ]; then
                output=$(cd "$ts_root" && vp check --no-fmt --no-lint --no-error-on-unmatched-pattern 2>&1) || true
            else
                output=$(cd "$ts_root" && bunx tsc --noEmit --pretty false 2>&1) || true
            fi
            if printf '%s' "$output" | grep -q 'error TS'; then
                typecheck_failed=1
                local errors
                errors=$(printf '%s\n' "$output" | grep 'error TS' | head -10)
                messages+=("[TypeCheck] ${errors}")
            fi
        fi
    fi

    if [ "$typecheck_failed" -eq 1 ]; then
        emit "failed" "$(printf '%s\n\n' "${messages[@]}")"
        exit 0
    fi

    if [ "$fmt_changed" -eq 1 ]; then
        emit "changed" "${messages[0]}"
        exit 0
    fi

    emit "passed" "Quality check passed (fmt + lint + typecheck)."
}

main "$@"
