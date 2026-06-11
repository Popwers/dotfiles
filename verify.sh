#!/usr/bin/env bash
# verify.sh — local verification baseline for the dotfiles repo.
# Validates syntax of every shell script and config file. No CI; run manually
# or before committing. Exit 0 = everything passes.
set -uo pipefail
cd "$(dirname "$0")"

GREEN='\033[32m'; RED='\033[31m'; YELLOW='\033[33m'; RESET='\033[0m'
FAILED=0

check() {
    local label=$1; shift
    if "$@" >/dev/null 2>&1; then
        printf "${GREEN}✓${RESET} %s\n" "$label"
    else
        printf "${RED}✗${RESET} %s\n" "$label"
        "$@" 2>&1 | sed 's/^/    /' || true
        FAILED=1
    fi
}

# Bash syntax
check "bash -n setup_my_mac.sh" bash -n setup_my_mac.sh
check "bash -n claude/statusline.sh" bash -n claude/statusline.sh
for f in claude/hooks/*.sh codex/hooks/*.sh; do
    check "bash -n $f" bash -n "$f"
done

# Fish syntax
check "fish -n config.fish" fish -n config.fish

# JSON validity (.vscode/*.json are JSONC — deliberately excluded)
for f in claude/settings.json claude/defaults.json codex/hooks.json .czrc; do
    check "jq empty $f" jq empty "$f"
done

# TOML validity
check "tomllib codex/config.toml" python3 -c "import tomllib; tomllib.load(open('codex/config.toml','rb'))"

# ShellCheck (optional — errors only; stylistic findings are out of scope)
if command -v shellcheck >/dev/null 2>&1; then
    check "shellcheck --severity=error (all bash scripts)" \
        shellcheck --severity=error setup_my_mac.sh claude/statusline.sh claude/hooks/*.sh codex/hooks/*.sh
else
    printf "${YELLOW}∼${RESET} shellcheck not installed — skipped (brew install shellcheck)\n"
fi

if [ "$FAILED" -eq 0 ]; then
    printf "\n${GREEN}All checks passed.${RESET}\n"
else
    printf "\n${RED}Some checks failed.${RESET}\n"
fi
exit "$FAILED"
