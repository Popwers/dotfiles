#!/usr/bin/env bash
# SessionStart: align Vite+ repo state silently. Idempotent.
# - Auto-fetch reference vite.config.ts from gist if Vite+ in deps but no config
# - Auto-install commit hooks via `vp config` if `.vite-hooks/` is missing
# - Surface notes for legacy deps still in package.json, or missing node_modules
# - Surface migration candidates when a legacy stack is detected without Vite+

set -u

# Ensure vp (Vite+) is reachable from this non-login shell.
export PATH="$HOME/.vite-plus/bin:$HOME/.bun/bin:/opt/homebrew/bin:$PATH"

[ -f package.json ] || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

REF_GIST="e112d96aea101e5aa35311048644d9cf"
REF_URL="https://gist.githubusercontent.com/Popwers/${REF_GIST}/raw/vite.config.ts"

has_vp_dep() {
    grep -qE '"vite-plus"[[:space:]]*:' package.json
}

has_vite_config() {
    [ -f vite.config.ts ] || [ -f vite.config.js ] || [ -f vite.config.mjs ] || [ -f vite.config.cjs ]
}

detect_legacy() {
    local found=()
    for tool in husky lint-staged "@biomejs/biome" prettier "@commitlint/cli" "@commitlint/config-conventional" eslint; do
        if grep -qE "\"${tool}\"[[:space:]]*:" package.json 2>/dev/null; then
            found+=("$tool")
        fi
    done
    [ ${#found[@]} -gt 0 ] && printf '%s ' "${found[@]}"
}

notes=()

if has_vp_dep || has_vite_config; then
    if ! has_vite_config; then
        tmp=$(mktemp 2>/dev/null) || tmp="/tmp/vite-config-$$"
        if curl -fsSL --max-time 5 "$REF_URL" -o "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
            mv "$tmp" vite.config.ts
            notes+=("Fetched reference vite.config.ts from gist")
        else
            rm -f "$tmp" 2>/dev/null
        fi
    fi

    if [ ! -d .vite-hooks ] && command -v vp >/dev/null 2>&1; then
        if vp config >/dev/null 2>&1; then
            notes+=("Ran vp config (commit hooks installed in .vite-hooks/)")
        fi
    fi

    [ ! -d node_modules ] && notes+=("node_modules missing — run \`vp install\`")

    legacy=$(detect_legacy)
    [ -n "$legacy" ] && notes+=("Legacy deps still present: ${legacy}— vp covers these, consider removing")
else
    legacy=$(detect_legacy)
    if [ -n "$legacy" ]; then
        notes+=("Migration candidate — legacy stack: ${legacy}")
        notes+=("Adopt Vite+: \`vp migrate\` or seed \`curl -fsSL ${REF_URL} > vite.config.ts\`")
    fi
fi

if [ ${#notes[@]} -gt 0 ]; then
    echo "── Vite+ repo init ──"
    printf '%s\n' "${notes[@]}"
fi

exit 0
