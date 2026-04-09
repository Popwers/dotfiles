#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONSOLE_RESULT=$("$SCRIPT_DIR/check-console-log.sh")

# Stop grepai watcher to avoid zombie processes
if command -v grepai >/dev/null 2>&1; then
    grepai watch --stop >/dev/null 2>&1 || true
fi

python3 - "$CONSOLE_RESULT" <<'PY'
import json
import sys

console = json.loads(sys.argv[1])

if console.get("status") == "failed":
    print(json.dumps({
        "continue": True,
        "systemMessage": console["message"]
    }))
else:
    print(json.dumps({"continue": True}))
PY
