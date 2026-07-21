#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=""; STAGE="manual"; ERROR=""; CAUSE=""; ASSUMPTION=""; RULE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir) RUN_DIR="${2:-}"; shift 2 ;;
    --stage) STAGE="${2:-manual}"; shift 2 ;;
    --error) ERROR="${2:-}"; shift 2 ;;
    --cause) CAUSE="${2:-}"; shift 2 ;;
    --llm-assumption) ASSUMPTION="${2:-}"; shift 2 ;;
    --rule-update) RULE="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 --run-dir .harness/runs/... --error text --cause text"; exit 0 ;;
    *) echo "[harness][error][FAIL] unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$RUN_DIR" && -n "$ERROR" && -n "$CAUSE" ]] || { echo "[harness][error][FAIL] --run-dir, --error, --cause required" >&2; exit 1; }
mkdir -p "$RUN_DIR"
{
  echo ""
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] stage=$STAGE"
  echo "error=$ERROR"
  echo "cause=$CAUSE"
  echo "llmAssumption=${ASSUMPTION:-none}"
  echo "ruleUpdate=${RULE:-none}"
} >> "$RUN_DIR/errors.log"
python3 - "$RUN_DIR/run.json" "$ERROR" "$CAUSE" "$ASSUMPTION" "$RULE" <<'PY'
import json, sys
from datetime import datetime, timezone
path, error, cause, assumption, rule = sys.argv[1:6]
try: data=json.load(open(path, encoding="utf-8"))
except FileNotFoundError: data={}
data.update({"status":"failed","lastError":error,"lastCause":cause,"updatedAt":datetime.now(timezone.utc).isoformat()})
if assumption:
    data.setdefault("assumptionFailures", []).append({"assumption":assumption,"ruleUpdate":rule,"recordedAt":datetime.now(timezone.utc).isoformat()})
json.dump(data, open(path,"w",encoding="utf-8"), ensure_ascii=False, indent=2)
open(path,"a",encoding="utf-8").write("\n")
PY
echo "[harness][error][OK] $RUN_DIR/errors.log"
