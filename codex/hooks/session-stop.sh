#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STOP_RESULT=$("$SCRIPT_DIR/stop-quality-check.sh")

# Stop grepai watcher to avoid zombie processes
if command -v grepai >/dev/null 2>&1; then
    grepai watch --stop >/dev/null 2>&1 || true
fi

python3 - "$STOP_RESULT" <<'PY'
import json
import sys

result = json.loads(sys.argv[1])

if result.get("status") == "failed":
    print(json.dumps({
        "continue": True,
        "systemMessage": result["message"]
    }))
else:
    print(json.dumps({"continue": True}))
PY
