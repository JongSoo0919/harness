#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ROOT="$(harness_resolve_root)"
cd "$ROOT"

fail() { echo "[harness][work-output][FAIL] $*" >&2; exit 1; }

WORK_DIR="${HARNESS_WORK_DIR:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-dir) WORK_DIR="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 --work-dir docs/work/YYYY-MM-DD-task"; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

[[ -n "$WORK_DIR" ]] || fail "--work-dir required"
[[ -d "$WORK_DIR" ]] || fail "missing work dir: $WORK_DIR"

for f in input.yaml 01-plan.md 02-dev-result.md 03-test-result.md 04-ops-check.md 05-summary.md harness.json; do
  [[ -s "$WORK_DIR/$f" ]] || fail "missing or empty: $WORK_DIR/$f"
done

python3 - "$WORK_DIR/harness.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1], encoding="utf-8"))
required=["inputReady","planApproved","devDone","testPassed","opsPassed","documentDone"]
missing=[k for k in required if data.get(k) is not True]
if missing:
    raise SystemExit("[harness][work-output][FAIL] true required: " + ", ".join(missing))
if data.get("openRisks") not in ([], None):
    raise SystemExit("[harness][work-output][FAIL] openRisks is not empty")
PY

echo "[harness][work-output][OK] complete"
