#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT=$(cat)

stop_hook_active=$(printf '%s' "$INPUT" | python3 -c "import sys,json; print(str(json.load(sys.stdin).get('stop_hook_active', False)).lower())" 2>/dev/null || printf 'false')

if [ "$stop_hook_active" = "true" ]; then
    printf '%s\n' '{"continue":true}'
    exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf '%s\n' '{"continue":true}'
    exit 0
fi

AUTO_FORMAT_RESULT=$("$SCRIPT_DIR/auto-format.sh")
TYPECHECK_RESULT=$("$SCRIPT_DIR/typecheck.sh")
TEST_RESULT=$("$SCRIPT_DIR/run-tests.sh")
AS_ANY_RESULT=$("$SCRIPT_DIR/check-as-any.sh")
IMPECCABLE_RESULT=$("$SCRIPT_DIR/impeccable-check.sh")

python3 - "$AUTO_FORMAT_RESULT" "$TYPECHECK_RESULT" "$TEST_RESULT" "$AS_ANY_RESULT" "$IMPECCABLE_RESULT" <<'PY'
import json
import sys

auto = json.loads(sys.argv[1])
typecheck = json.loads(sys.argv[2])
tests = json.loads(sys.argv[3])
as_any = json.loads(sys.argv[4])
impeccable = json.loads(sys.argv[5])

messages = []
should_continue = False

if auto["status"] == "changed":
    should_continue = True
    messages.append(auto["message"])

if typecheck["status"] == "failed":
    should_continue = True
    messages.append(typecheck["message"])

if tests["status"] == "failed":
    should_continue = True
    messages.append(tests["message"])

if as_any["status"] == "failed":
    should_continue = True
    messages.append(as_any["message"])

if impeccable["status"] == "failed":
    should_continue = True
    messages.append(impeccable["message"])

if should_continue:
    reason = (
        "Validation hooks ran automatically after the turn. Re-read the updated files, "
        "fix any remaining issues, and then finalize.\n\n" + "\n\n".join(messages)
    )
    print(json.dumps({"decision": "block", "reason": reason}))
elif messages:
    print(json.dumps({"continue": True, "systemMessage": "\n\n".join(messages)}))
else:
    print(json.dumps({"continue": True}))
PY
