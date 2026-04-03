#!/usr/bin/env bash

set -euo pipefail

# Stop grepai watcher to avoid zombie processes
if command -v grepai >/dev/null 2>&1; then
    grepai watch --stop >/dev/null 2>&1 || true
fi

printf '%s\n' '{"continue":true}'
