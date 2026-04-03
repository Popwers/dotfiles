#!/usr/bin/env bash

set -euo pipefail

if command -v ollama >/dev/null 2>&1; then
    pgrep -x ollama >/dev/null 2>&1 || nohup ollama serve >/dev/null 2>&1 &
fi

if command -v grepai >/dev/null 2>&1; then
    grepai status >/dev/null 2>&1 || grepai init --yes >/dev/null 2>&1 || true
    if [ -f .gitignore ]; then
        grep -qsx '.grepai/' .gitignore || printf '%s\n' '.grepai/' >> .gitignore
    fi
    grepai watch --background >/dev/null 2>&1 || true
fi
