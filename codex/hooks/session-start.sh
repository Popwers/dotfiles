#!/usr/bin/env bash

set -euo pipefail

if command -v ollama >/dev/null 2>&1; then
    pgrep -x ollama >/dev/null 2>&1 || nohup ollama serve >/dev/null 2>&1 &
fi

if command -v grepai >/dev/null 2>&1; then
    grepai status >/dev/null 2>&1 || grepai init --yes >/dev/null 2>&1 || true
    grepai watch --background >/dev/null 2>&1 || true
fi

template="$HOME/.claude/claudeignore.template"
target=".claudeignore"
if [ -f "$template" ]; then
    if [ ! -f "$target" ]; then
        cp "$template" "$target"
    else
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            case "$line" in \#*) continue ;; esac
            grep -qsxF "$line" "$target" || printf '%s\n' "$line" >> "$target"
        done < "$template"
    fi
fi

[ -x "$HOME/.codex/hooks/repo-init.sh" ] && "$HOME/.codex/hooks/repo-init.sh" || true
